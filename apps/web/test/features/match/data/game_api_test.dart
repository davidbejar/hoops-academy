import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/match/data/api_events_remote.dart';
import 'package:hoops_app/features/match/data/event_codec.dart';
import 'package:hoops_app/features/match/data/matches_repository.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/match/domain/pending_event.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../support/fake_adapter.dart';
import '../domain/vector_support.dart';

Map<String, Object?> _canonical(Map<String, Object?> json) => {
  ...json,
  'recordedAtClient': DateTime.parse(json['recordedAtClient']! as String).toUtc().toIso8601String(),
};

void main() {
  test('every vector event crosses the generated MatchEvent oneOf unchanged', () {
    var n = 0;
    for (final v in loadVectors()) {
      for (final raw in v.rawEvents) {
        final json = raw['event']! as Map<String, Object?>;
        final domain = MatchEvent.fromJson(json);
        final api = EventCodec.toApi(domain);
        final wire = gen.standardSerializers.serializeWith(gen.MatchEvent.serializer, api)! as Map;
        expect(_canonical(wire.cast<String, Object?>()), _canonical(json), reason: '${json['type']}');
        expect(EventCodec.fromApi(api).toJson(), domain.toJson());
        n++;
      }
    }
    expect(n, greaterThan(100));
  });

  group('ApiEventsRemote over the generated client', () {
    late List<RequestOptions> requests;
    ApiEventsRemote remote(List<FakeResponse> responses) {
      final adapter = FakeAdapter(responses);
      requests = adapter.requests;
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))..httpClientAdapter = adapter;
      return ApiEventsRemote(gen.HoopsGameApi(dio: dio, interceptors: const []), 'tenant-1');
    }

    final meta = EventMeta(
      id: '0190b6a0-0001-7000-8000-000000000002', deviceId: 'd', clientSeq: 2, period: 1,
      clockSecondsRemaining: 570, recordedAtClient: DateTime.utc(2026, 11, 1, 10),
    );

    test('submit posts events:batch with the tenant and maps per-event results', () async {
      final r = remote([
        FakeResponse(200, jsonEncode({
          'results': [
            {'eventId': meta.id, 'status': 'ACCEPTED', 'serverSeq': 7},
            {'eventId': 'b', 'status': 'DUPLICATE', 'serverSeq': 3},
            {'eventId': 'c', 'status': 'REJECTED', 'reason': 'NOT_AUTHORIZED', 'message': 'no'},
          ],
          'lastServerSeq': 7,
        })),
      ]);
      final out = await r.submit('m1', [Shot(meta, playerId: 'p1', points: 2, made: true)]);
      expect(requests.single.path, '/api/game/matches/m1/events:batch');
      expect(requests.single.headers['X-Tenant-Id'], 'tenant-1');
      final body = requests.single.data;
      final events = ((body is String ? jsonDecode(body) : body) as Map)['events'] as List;
      expect((events.single as Map)['payload'], {'points': 2, 'made': true});
      expect(out.lastServerSeq, 7);
      expect(out.results.map((e) => e.status), [EventStatus.accepted, EventStatus.duplicate, EventStatus.rejected]);
      expect(out.results.last.reason, 'NOT_AUTHORIZED');
      expect(out.results.first.serverSeq, 7);
    });

    test('feed reads ?after= and decodes stored events', () async {
      final r = remote([
        FakeResponse(200, jsonEncode({
          'events': [
            {
              'serverSeq': 12,
              'event': Shot(meta, playerId: 'p1', points: 3, made: false).toJson(),
              'recordedBy': {'personId': 'coach', 'displayName': 'Coach'},
              'receivedAt': '2026-11-01T10:00:00Z',
              'voidedByEventId': 'v1',
            },
          ],
          'lastServerSeq': 12,
          'hasMore': false,
        })),
      ]);
      final page = await r.feed('m1', after: 11);
      expect(requests.single.queryParameters['after'], 11);
      final e = page.events.single;
      expect(e.serverSeq, 12);
      expect(e.recordedByPersonId, 'coach');
      expect(e.voidedByEventId, 'v1');
      expect((e.event as Shot).points, 3);
      expect(page.hasMore, isFalse);
    });

    test('401 and network failures surface as AppError kinds', () async {
      await expectLater(
        remote([FakeResponse.problem(401, {'title': 'Unauthorized', 'status': 401})]).feed('m1', after: 0),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', AppErrorKind.unauthorized)),
      );
      await expectLater(
        remote([const FakeResponse.network()]).submit('m1', [PeriodStart(meta)]),
        throwsA(isA<AppError>().having((e) => e.kind, 'kind', AppErrorKind.network)),
      );
    });
  });

  test('MatchesRepository lists by team and season and maps the roster', () async {
    final adapter = FakeAdapter([
      FakeResponse(200, jsonEncode({
        'items': [matchJson('m1')],
        'page': {'page': 0, 'size': 100, 'totalElements': 1, 'totalPages': 1},
      })),
      FakeResponse(200, jsonEncode({
        'matchId': 'm1',
        'entries': [
          {'playerId': 'p1', 'displayName': 'Ana', 'jerseyNumber': '4', 'isStarter': true},
        ],
      })),
    ]);
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))..httpClientAdapter = adapter;
    final repo = ApiMatchesRepository(gen.HoopsGameApi(dio: dio, interceptors: const []), 't');
    final list = await repo.list(teamId: 'team-1', seasonId: 's-1');
    expect(adapter.requests.first.queryParameters, containsPair('teamId', 'team-1'));
    expect(adapter.requests.first.queryParameters, containsPair('seasonId', 's-1'));
    expect(list.single.opponentName, 'Rivals');
    final roster = await repo.roster('m1');
    expect(roster.single.displayName, 'Ana');
    expect(roster.single.isStarter, isTrue);
  });
}

Map<String, Object?> matchJson(String id, {String status = 'SCHEDULED'}) => {
  'id': id,
  'teamId': 'team-1',
  'seasonId': 's-1',
  'opponentName': 'Rivals',
  'homeAway': 'HOME',
  'scheduledAt': '2026-11-07T10:00:00Z',
  'status': status,
  'periodCount': 4,
  'periodMinutes': 10,
  'score': {'team': 0, 'opponent': 0},
  'lastServerSeq': 0,
};
