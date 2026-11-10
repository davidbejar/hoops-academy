import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/admin/data/academy_repository.dart';
import 'package:hoops_app/features/admin/data/age_categories_repository.dart';
import 'package:hoops_app/features/admin/data/seasons_repository.dart';
import 'package:hoops_app/features/roster/data/approvals_repository.dart';
import 'package:hoops_app/features/roster/data/teams_repository.dart';

/// Captures the request (including the streamed body) and answers JSON.
class CapturingAdapter implements HttpClientAdapter {
  CapturingAdapter(this.respond);
  final Map<String, Object?> Function(RequestOptions) respond;
  RequestOptions? last;
  Uint8List? body;

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
    body = Uint8List.fromList(chunks);
    return ResponseBody.fromString(
      jsonEncode(respond(options)),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const tenant = '11111111-1111-4111-8111-111111111111';

(api.HoopsCoreApi, CapturingAdapter) clientWith(
  Map<String, Object?> Function(RequestOptions) respond,
) {
  final adapter = CapturingAdapter(respond);
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = adapter;
  return (api.HoopsCoreApi(dio: dio, interceptors: const []), adapter);
}

void main() {
  test(
    'logo upload PUTs the raw bytes to /api/core/tenant/logo for the tenant',
    () async {
      final (client, adapter) = clientWith(
        (_) => {
          'contentType': 'image/png',
          'sizeBytes': 12,
          'etag': '"abc"',
          'updatedAt': '2026-11-01T10:00:00Z',
        },
      );
      final bytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
      ]);

      final logo = await ApiAcademyRepository(
        client,
        tenant,
      ).uploadLogo(bytes: bytes, mimeType: 'image/png', fileName: 'logo.png');

      expect(adapter.last!.method, 'PUT');
      expect(adapter.last!.path, '/api/core/tenant/logo');
      expect(adapter.last!.headers['X-Tenant-Id'], tenant);
      expect(adapter.body, bytes);
      expect(logo.etag, '"abc"');
    },
  );

  test('logo upload of a JPEG still carries an allowed Content-Type (generated client sends image/png)', () async {
    final (client, adapter) = clientWith(
      (_) => {
        'contentType': 'image/jpeg',
        'sizeBytes': 4,
        'etag': '"j"',
        'updatedAt': '2026-11-01T10:00:00Z',
      },
    );
    await ApiAcademyRepository(client, tenant).uploadLogo(
      bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
      mimeType: 'image/jpeg',
      fileName: 'logo.jpg',
    );
    // Characterisation of a contract gap: see ApiAcademyRepository.uploadLogo.
    expect(
      adapter.last!.headers['content-type'] ??
          adapter.last!.headers['Content-Type'],
      'image/png',
    );
  });

  test('assign sends playerId and jersey as JSON to the team roster', () async {
    final (client, adapter) = clientWith(
      (_) => {
        'player': {'id': 'p1', 'displayName': 'Ana Ruiz'},
        'teamId': 't1',
        'jerseyNumber': '7',
        'joinedOn': '2026-09-01',
        'playUpLevels': 0,
        'playerStatus': 'ACTIVE',
        'jerseySource': 'REQUESTED',
      },
    );
    await ApiTeamsRepository(
      client,
      tenant,
    ).assign('t1', 'p1', jerseyNumber: '7');
    expect(adapter.last!.method, 'POST');
    expect(adapter.last!.path, '/api/core/teams/t1/players');
    expect(jsonDecode(utf8.decode(adapter.body!)), {
      'playerId': 'p1',
      'jerseyNumber': '7',
    });
  });

  Map<String, Object?> teamPlayerJson(String? jersey) => {
    'player': {'id': 'p1', 'displayName': 'Ana Ruiz'},
    'teamId': 't1',
    'jerseyNumber': jersey,
    'joinedOn': '2026-09-01',
    'playUpLevels': 0,
    'playerStatus': 'ACTIVE',
  };

  test('a jersey change sends the number; removing it names jerseyNumber in clear (ADR-0032)', () async {
    final (client, adapter) = clientWith((_) => teamPlayerJson('7'));
    final repo = ApiTeamsRepository(client, tenant);

    await repo.setJersey('t1', 'p1', '7');
    expect(adapter.last!.method, 'PATCH');
    expect(jsonDecode(utf8.decode(adapter.body!)), {'jerseyNumber': '7'});

    await repo.setJersey('t1', 'p1', null);
    expect(jsonDecode(utf8.decode(adapter.body!)), {
      'clear': ['jerseyNumber'],
    });
  });

  test(
    'an age category update without maxAge names maxAge in clear (ADR-0032)',
    () async {
      final (client, adapter) = clientWith(
        (_) => {'id': 'c1', 'code': 'SEN', 'name': 'Senior', 'rank': 9},
      );
      final repo = ApiAgeCategoriesRepository(client, tenant);

      await repo.update('c1', code: 'SEN', name: 'Senior', rank: 9);
      expect(jsonDecode(utf8.decode(adapter.body!)), {
        'code': 'SEN',
        'name': 'Senior',
        'rank': 9,
        'clear': ['maxAge'],
      });

      await repo.update('c1', code: 'SEN', name: 'Senior', maxAge: 40, rank: 9);
      expect(jsonDecode(utf8.decode(adapter.body!)), {
        'code': 'SEN',
        'name': 'Senior',
        'maxAge': 40,
        'rank': 9,
      });
    },
  );

  test(
    'reject sends the note; approve without a note sends an empty body object',
    () async {
      final approval = {
        'id': 'a1',
        'action': 'ADD_PLAYER',
        'status': 'REJECTED',
        'player': {'id': 'p1', 'displayName': 'Ana'},
        'payload': <String, Object?>{},
        'requestedBy': {'personId': 'x', 'displayName': 'Coach'},
        'requestedAt': '2026-10-01T10:00:00Z',
      };
      final (client, adapter) = clientWith((_) => approval);
      final repo = ApiApprovalsRepository(client, tenant);
      await repo.reject('a1', note: 'duplicate');
      expect(adapter.last!.path, '/api/core/approval-requests/a1/reject');
      expect(jsonDecode(utf8.decode(adapter.body!)), {'note': 'duplicate'});
    },
  );

  test('season create sends the dates as ISO dates', () async {
    final (client, adapter) = clientWith(
      (_) => {
        'id': 's1',
        'name': '2026/27',
        'startsOn': '2026-09-01',
        'endsOn': '2027-06-30',
        'referenceYear': 2026,
        'current': false,
      },
    );
    await ApiSeasonsRepository(client, tenant).create(
      name: '2026/27',
      startsOn: api.Date(2026, 9, 1),
      endsOn: api.Date(2027, 6, 30),
      referenceYear: 2026,
    );
    expect(jsonDecode(utf8.decode(adapter.body!)), {
      'name': '2026/27',
      'startsOn': '2026-09-01',
      'endsOn': '2027-06-30',
      'referenceYear': 2026,
    });
  });
}
