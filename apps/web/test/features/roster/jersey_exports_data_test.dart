import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/audit/data/audit_repository.dart';
import 'package:hoops_app/features/audit/domain/audit_entry.dart';
import 'package:hoops_app/features/roster/data/players_repository.dart';
import 'package:hoops_app/features/roster/data/teams_repository.dart';

import '../../support/fake_adapter.dart';

const _tenant = '11111111-1111-4111-8111-111111111111';

(api.HoopsCoreApi, FakeAdapter) _client(FakeResponse response) {
  final adapter = FakeAdapter([response]);
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = adapter;
  return (api.HoopsCoreApi(dio: dio, interceptors: const []), adapter);
}

final _csv = utf8.encode('\u{feff}Name\r\nAna\r\n');

void main() {
  group('teams (core 3.5.0)', () {
    test('an assignment answers with the rule that chose the number', () async {
      final (client, adapter) = _client(
        FakeResponse(
          201,
          jsonEncode({
            'player': {'id': 'p1', 'displayName': 'Ana Ruiz'},
            'teamId': 't1',
            'jerseyNumber': '7',
            'joinedOn': '2026-09-01',
            'playUpLevels': 0,
            'playerStatus': 'ACTIVE',
            'jerseySource': 'PREFERRED',
          }),
        ),
      );

      final assigned = await ApiTeamsRepository(
        client,
        _tenant,
      ).assign('t1', 'p1');

      expect(assigned.jerseySource, api.JerseySource.PREFERRED);
      expect(assigned.jerseyNumber, '7');
      expect(adapter.requests.single.path, '/api/core/teams/t1/players');
    });

    test('the taken numbers come with their players', () async {
      final (client, adapter) = _client(
        FakeResponse(
          200,
          jsonEncode([
            {
              'jerseyNumber': '7',
              'player': {'id': 'p1', 'displayName': 'Uma Test'},
            },
          ]),
        ),
      );

      final taken = await ApiTeamsRepository(
        client,
        _tenant,
      ).jerseyNumbers('t1');

      expect(adapter.requests.single.path, '/api/core/teams/t1/jersey-numbers');
      expect(adapter.requests.single.headers['X-Tenant-Id'], _tenant);
      expect(taken.single.jerseyNumber, '7');
      expect(taken.single.player.displayName, 'Uma Test');
    });

    test('the roster export asks for the language and returns the bytes',
        () async {
      final (client, adapter) = _client(
        FakeResponse(200, utf8.decode(_csv), contentType: 'text/csv'),
      );

      final bytes = await ApiTeamsRepository(
        client,
        _tenant,
      ).exportRoster('t1', language: 'id');

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/api/core/teams/t1/roster:export');
      expect(request.headers['Accept-Language'], 'id');
      expect(request.headers['X-Tenant-Id'], _tenant);
      expect(bytes, isA<Uint8List>());
      expect(bytes, _csv);
    });
  });

  group('players (core 3.5.0)', () {
    Map<String, Object?> playerJson(String? preferred) => {
      'id': 'p1',
      'personId': 'person-p1',
      'givenName': 'Ana',
      'familyName': 'Ruiz',
      'displayName': 'Ana Ruiz',
      'birthDate': '2015-03-04',
      'gender': 'FEMALE',
      'status': 'ACTIVE',
      'teams': <Object?>[],
      'createdAt': '2026-01-01T00:00:00Z',
      'preferredJerseyNumber': ?preferred,
    };

    test('a wish is sent as the number, removing it names it in clear',
        () async {
      final adapter = _BodyAdapter(jsonEncode(playerJson('7')));
      final client = api.HoopsCoreApi(
        dio: Dio(BaseOptions(baseUrl: 'http://test'))
          ..httpClientAdapter = adapter,
        interceptors: const [],
      );
      final repo = ApiPlayersRepository(client, _tenant);

      final player = await repo.setPreferredJersey('p1', '7');
      expect(adapter.last!.method, 'PATCH');
      expect(adapter.last!.path, '/api/core/players/p1');
      expect(jsonDecode(adapter.body), {'preferredJerseyNumber': '7'});
      expect(player.preferredJerseyNumber, '7');

      await repo.setPreferredJersey('p1', null);
      expect(jsonDecode(adapter.body), {
        'clear': ['preferredJerseyNumber'],
      });
    });
  });

  group('audit exports (core 3.5.0)', () {
    final query = AuditQuery(
      fromDay: DateTime(2026, 11, 1),
      toDay: DateTime(2026, 11, 3),
      actions: {api.AuditAction.memberPeriodInvited},
    );

    test('the academy export carries the filters of the screen', () async {
      final (client, adapter) = _client(
        FakeResponse(200, utf8.decode(_csv), contentType: 'text/csv'),
      );

      final bytes = await ApiAuditRepository(
        client,
      ).exportAcademy(_tenant, query, language: 'en');

      final request = adapter.requests.single;
      expect(request.path, '/api/core/audit-events:export');
      expect(request.headers['Accept-Language'], 'en');
      expect(request.headers['X-Tenant-Id'], _tenant);
      expect(request.uri.queryParametersAll['action'], ['member.invited']);
      expect(request.uri.queryParameters['from'], endsWith('Z'));
      expect(request.uri.queryParameters.containsKey('page'), isFalse);
      expect(bytes, _csv);
    });

    test('the platform export may narrow to one academy', () async {
      final (client, adapter) = _client(
        FakeResponse(200, utf8.decode(_csv), contentType: 'text/csv'),
      );

      await ApiAuditRepository(
        client,
      ).exportPlatform(const AuditQuery(), tenantId: 't-a', language: 'es');

      final request = adapter.requests.single;
      expect(request.path, '/platform/audit-events:export');
      expect(request.uri.queryParameters['tenantId'], 't-a');
      expect(request.headers['Accept-Language'], 'es');
    });
  });
}

class _BodyAdapter implements HttpClientAdapter {
  _BodyAdapter(this.response);
  final String response;
  RequestOptions? last;
  String body = '';

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
    body = utf8.decode(chunks);
    return ResponseBody.fromString(
      response,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
