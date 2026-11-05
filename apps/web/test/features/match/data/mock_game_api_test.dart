import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/match/data/api_events_remote.dart';
import 'package:hoops_app/features/match/data/matches_repository.dart';
import 'package:hoops_app/features/match/data/mock_game_api.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/match/domain/pending_event.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

/// The demo game backend through the real generated client and repositories.
void main() {
  gen.HoopsGameApi client(List<String> roles) => gen.HoopsGameApi(
    dio: Dio(BaseOptions(baseUrl: 'http://mock', headers: {'Authorization': 'Bearer x'}))
      ..httpClientAdapter = MockApiAdapter(roles: roles),
    interceptors: const [],
  );

  EventMeta meta(int seq) => EventMeta(
    id: '0190b6a0-0000-7000-8000-0000000ff${seq.toString().padLeft(3, '0')}',
    deviceId: 'test-device', clientSeq: seq, period: 2, clockSecondsRemaining: 500,
    recordedAtClient: DateTime.utc(2026, 11, 2, 12),
  );

  test('coach: list, roster, batch, feed, box score and season stats', () async {
    final api = client(['COACH']);
    final repo = ApiMatchesRepository(api, mockTenantAId);
    final events = ApiEventsRemote(api, mockTenantAId);
    final matches = await repo.list(teamId: MockGameApi.ownTeamId);
    expect(matches.map((m) => m.status), containsAll([gen.MatchStatus.LIVE, gen.MatchStatus.SCHEDULED, gen.MatchStatus.FINISHED]));
    final roster = await repo.roster(MockGameApi.liveMatchId);
    expect(roster.where((r) => r.isStarter).length, 5);

    final before = await repo.boxScore(MockGameApi.liveMatchId);
    final out = await events.submit(MockGameApi.liveMatchId, [
      PeriodStart(meta(1)),
      Shot(meta(2), playerId: 'p-ana', points: 3, made: true),
    ]);
    expect(out.results.map((r) => r.status), [EventStatus.accepted, EventStatus.accepted]);
    final again = await events.submit(MockGameApi.liveMatchId, [Shot(meta(2), playerId: 'p-ana', points: 3, made: true)]);
    expect(again.results.single.status, EventStatus.duplicate);
    final after = await repo.boxScore(MockGameApi.liveMatchId);
    expect(after.score.team, before.score.team + 3);

    final feed = await events.feed(MockGameApi.liveMatchId, after: 0);
    expect(feed.events.map((e) => e.event.id), contains(meta(2).id));

    final stats = await repo.seasonStats('p-ana', 'season-2026');
    expect(stats.gamesPlayed, 2);
    expect(stats.matches.length, 2);
  });

  test('parent: linked player accepted, other player and period REJECTED NOT_AUTHORIZED', () async {
    final events = ApiEventsRemote(client(['PARENT']), mockTenantAId);
    final out = await events.submit(MockGameApi.liveMatchId, [
      Assist(meta(1), playerId: 'p-ana'),
      Assist(meta(2), playerId: 'p-leo'),
      PeriodEnd(meta(3)),
      VoidEvent(meta(4), target: meta(1).id),
    ]);
    expect(out.results.map((r) => r.status),
        [EventStatus.accepted, EventStatus.rejected, EventStatus.rejected, EventStatus.accepted]);
    expect(out.results[1].reason, 'NOT_AUTHORIZED');
    final box = await ApiMatchesRepository(client(['PARENT']), mockTenantAId).boxScore(MockGameApi.finishedMatchId);
    expect(box.players.map((p) => p.playerId), ['p-ana']);
  });

  test('feed like the server (ADR-0030): staff read every event, a parent team events and the linked player\'s', () async {
    final staff = await ApiEventsRemote(client(['COACH']), mockTenantAId).feed(MockGameApi.liveMatchId, after: 0);
    expect(staff.events.map((s) => s.event.playerId), contains('p-leo'), reason: 'precondition: other players scored');

    final parent = await ApiEventsRemote(client(['PARENT']), mockTenantAId).feed(MockGameApi.liveMatchId, after: 0);
    expect(parent.events, isNotEmpty);
    expect(parent.events.map((s) => s.event.playerId).toSet(), {null, 'p-ana'});
    expect(parent.events.length, lessThan(staff.events.length));
    expect(parent.lastServerSeq, staff.lastServerSeq, reason: 'the cursor is the match\'s, not the caller\'s');
  });
}
