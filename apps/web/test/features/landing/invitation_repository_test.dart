import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/http/interceptors.dart';
import 'package:hoops_app/features/landing/data/invitation_repository.dart';
import 'package:hoops_app/features/landing/domain/invitation_request.dart';

/// Answers every call with [status] and [body]; remembers the last request.
class _Server implements HttpClientAdapter {
  _Server(this.status, [this.body = const {'status': 'RECEIVED'}]);
  final int status;
  final Map<String, Object?> body;
  RequestOptions? last;
  Object? sent;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    final chunks = <int>[];
    if (requestStream != null) {
      await for (final c in requestStream) {
        chunks.addAll(c);
      }
    }
    sent = jsonDecode(utf8.decode(chunks));
    if (status == 0) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [
          status >= 400 ? 'application/problem+json' : 'application/json',
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(InvitationRepository, _Server) _repo(
  int status, [
  Map<String, Object?> body = const {'status': 'RECEIVED'},
]) {
  final server = _Server(status, body);
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = server;
  dio.interceptors.addAll(
    buildInterceptors(
      dio: dio,
      accessToken: () async => null,
      refresh: () async => false,
      onSessionExpired: () {},
      tenantId: () => 'some-tenant',
      languageCode: () => 'en',
    ),
  );
  return (
    ApiInvitationRepository(api.HoopsCoreApi(dio: dio, interceptors: const [])),
    server,
  );
}

const _request = InvitationRequest(
  name: '  Ana Ruiz ',
  email: ' ana@example.com ',
  role: InvitationRole.coach,
  academy: ' Norte Basket ',
  languageCode: 'id',
);

void main() {
  test('sends the trimmed form without a token or tenant to the public '
      'endpoint', () async {
    final (repo, server) = _repo(202);

    expect(await repo.send(_request), InvitationOutcome.sent);

    expect(server.last!.method, 'POST');
    expect(server.last!.path, '/platform/academy-requests');
    expect(server.last!.headers.containsKey('Authorization'), isFalse);
    expect(server.last!.headers.containsKey('X-Tenant-Id'), isFalse);
    expect(server.sent, {
      'name': 'Ana Ruiz',
      'email': 'ana@example.com',
      'role': 'COACH',
      'academyName': 'Norte Basket',
      'locale': 'id',
    });
  });

  test('an empty name is left out; every role maps to the contract', () async {
    for (final (role, wire) in [
      (InvitationRole.admin, 'ADMIN'),
      (InvitationRole.coach, 'COACH'),
      (InvitationRole.parent, 'PARENT'),
    ]) {
      final (repo, server) = _repo(202);
      await repo.send(
        InvitationRequest(name: ' ', email: 'a@b.es', role: role, academy: 'X'),
      );
      final sent = server.sent! as Map;
      expect(sent.containsKey('name'), isFalse);
      expect(sent['role'], wire);
      expect(sent['locale'], 'es');
    }
  });

  test('a filled honeypot travels as website', () async {
    final (repo, server) = _repo(202);
    await repo.send(
      const InvitationRequest(
        name: '',
        email: 'bot@spam.example',
        role: InvitationRole.admin,
        academy: 'Spam',
        website: 'http://spam.example',
      ),
    );
    expect((server.sent! as Map)['website'], 'http://spam.example');
  });

  test('409 ACADEMY_NAME_TAKEN is a taken academy', () async {
    final (repo, _) = _repo(409, {
      'status': 409,
      'title': 'Conflict',
      'code': 'ACADEMY_NAME_TAKEN',
    });
    expect(await repo.send(_request), InvitationOutcome.academyTaken);
  });

  test('a rate limit, a server error or no network is a failure', () async {
    for (final status in [429, 500, 400, 0]) {
      final (repo, _) = _repo(status, {'status': status, 'title': 'x'});
      expect(
        await repo.send(_request),
        InvitationOutcome.failed,
        reason: '$status',
      );
    }
  });
}
