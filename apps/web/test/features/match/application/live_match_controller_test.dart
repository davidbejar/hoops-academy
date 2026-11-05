import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/connectivity/connectivity_providers.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/session/capabilities.dart';
import 'package:hoops_app/features/match/application/live_match_controller.dart';
import 'package:hoops_app/features/match/application/match_providers.dart';
import 'package:hoops_app/features/match/application/sync/sync_worker.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/match/domain/pending_event.dart';
import 'package:hoops_app/features/match/domain/stat_action.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../../support/fake_game.dart';

const m1 = 'm1';

ProviderContainer containerFor(FakeGame game, {Capabilities? caps}) {
  final c = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      ...game.overrides,
      capabilitiesProvider.overrideWithValue(
        caps ?? const Capabilities(roles: {TenantRole.coach}, staffTeamIds: {teamA}, personId: 'person-me'),
      ),
      syncScopeProvider.overrideWithValue(const SyncScope(tenantId: 't1', personId: 'person-me')),
      onlineProvider.overrideWith((ref) => Stream.value(true)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

FakeGame liveGame() => FakeGame(
  matches: FakeMatchesRepository(matches: [gameMatch(m1)], rosters: {m1: demoRoster}),
);

Future<LiveMatch> settle(ProviderContainer c) async {
  await c.read(liveMatchProvider(m1).future);
  await pumpEventQueue();
  return c.read(liveMatchProvider(m1)).requireValue;
}

void main() {
  test('loads match + roster, caches them and starts with starters on court', () async {
    final game = liveGame();
    final c = containerFor(game);
    final s = await settle(c);
    expect(s.match.id, m1);
    expect(s.projection.live.onCourt, {'p1', 'p2', 'p3', 'p4', 'p5'});
    expect(s.fromCache, isFalse);
    expect((await game.store.roster(m1))!.length, 7);
    expect(await game.store.matchJson(m1), isNotNull);
  });

  test('offline: match and roster come from the cache', () async {
    final game = liveGame();
    var c = containerFor(game);
    await settle(c);
    c.dispose();
    game.matches.failWith = const AppError(kind: AppErrorKind.network);
    c = containerFor(game);
    final s = await settle(c);
    expect(s.fromCache, isTrue);
    expect(s.roster.length, 7);
  });

  test('offline without cache: a network error', () async {
    final game = liveGame()..matches.failWith = const AppError(kind: AppErrorKind.network);
    final c = containerFor(game);
    await expectLater(c.read(liveMatchProvider(m1).future), throwsA(isA<AppError>()));
  });

  test('recording: period start, shot, opponent points, sub; projection is live', () async {
    final game = liveGame()..server.offline = true;
    final c = containerFor(game);
    await settle(c);
    final ctl = c.read(liveMatchProvider(m1).notifier);
    await ctl.startPeriod(clock: 600);
    await ctl.recordStat('p1', StatAction.threeMade, clock: 580);
    await ctl.recordStat('p2', StatAction.ftMissed, clock: 570);
    await ctl.opponentScore(2, clock: 560);
    await ctl.substitute(out: 'p5', into: 'p6', clock: 550);
    await pumpEventQueue();
    final s = c.read(liveMatchProvider(m1)).requireValue;
    expect(s.projection.summary.teamScore, 3);
    expect(s.projection.summary.opponentScore, 2);
    expect(s.projection.live.onCourt, contains('p6'));
    expect(s.projection.live.running, isTrue);
    expect(s.own.length, 6);
    expect(s.own.every((e) => e.status.unsynced), isTrue);
    expect(s.log.first.event, isA<SubIn>(), reason: 'log shows the latest first');
    expect(s.own.map((e) => e.event.meta.clientSeq), [1, 2, 3, 4, 5, 6]);
  });

  test('undo VOIDs the last own event (not a VOID, not voided)', () async {
    final game = liveGame()..server.offline = true;
    final c = containerFor(game);
    await settle(c);
    final ctl = c.read(liveMatchProvider(m1).notifier);
    await ctl.startPeriod(clock: 600);
    await ctl.recordStat('p1', StatAction.twoMade, clock: 580);
    await ctl.recordStat('p1', StatAction.threeMade, clock: 570);
    expect(await ctl.undo(), isTrue);
    expect(await ctl.undo(), isTrue);
    await pumpEventQueue();
    final s = c.read(liveMatchProvider(m1)).requireValue;
    expect(s.projection.summary.teamScore, 0);
    expect(s.own.last.event, isA<VoidEvent>());
    expect(s.log.where((e) => e.voided).length, 2);
  });

  test('parent mode: only linked players, no period / opponent / subs; VOID own only', () async {
    final game = liveGame()..server.offline = true;
    final c = containerFor(
      game,
      caps: const Capabilities(roles: {TenantRole.parent}, linkedPlayerIds: {'p1'}, personId: 'person-me'),
    );
    final s0 = await settle(c);
    expect(s0.rights.parentMode, isTrue);
    final ctl = c.read(liveMatchProvider(m1).notifier);
    await ctl.recordStat('p1', StatAction.assist, clock: 0);
    await expectLater(ctl.recordStat('p2', StatAction.assist, clock: 0), throwsA(isA<NotAllowed>()));
    await expectLater(ctl.startPeriod(clock: 600), throwsA(isA<NotAllowed>()));
    await expectLater(ctl.opponentScore(2, clock: 1), throwsA(isA<NotAllowed>()));
    await expectLater(ctl.substitute(out: 'p1', into: 'p6', clock: 1), throwsA(isA<NotAllowed>()));
    // A coach's event pulled from the feed cannot be voided by the parent.
    game.server.offline = false;
    game.server.preload(m1, [RecordedEventFixture.shot('0190b6a0-0000-7000-8000-0000000000c1')], personId: 'coach');
    await c.read(syncWorkerProvider).syncNow(matchId: m1);
    await pumpEventQueue();
    final s = c.read(liveMatchProvider(m1)).requireValue;
    final coachEntry = s.log.firstWhere((e) => e.event.id == '0190b6a0-0000-7000-8000-0000000000c1');
    expect(coachEntry.canVoid, isFalse);
    final mine = s.log.firstWhere((e) => e.event is Assist);
    expect(mine.canVoid, isTrue);
    await expectLater(ctl.voidEvent(coachEntry.event.id), throwsA(isA<NotAllowed>()));
  });

  test('parent events use the latest known period and clock', () async {
    final game = liveGame();
    game.server.preload(m1, [RecordedEventFixture.periodStart(period: 2, clock: 600)], personId: 'coach');
    final c = containerFor(
      game,
      caps: const Capabilities(roles: {TenantRole.parent}, linkedPlayerIds: {'p1'}, personId: 'person-me'),
    );
    await settle(c);
    await c.read(syncWorkerProvider).syncNow(matchId: m1);
    await pumpEventQueue();
    final ctl = c.read(liveMatchProvider(m1).notifier);
    await ctl.recordStat('p1', StatAction.steal);
    final own = await game.store.ownEvents(m1);
    expect(own.single.event.meta.period, 2);
    expect(own.single.event.meta.clockSecondsRemaining, 600);
  });

  test('REJECTED: shown with its reason and can be discarded', () async {
    final game = liveGame()..server.rejectWhen = (e) => 'NOT_AUTHORIZED';
    final c = containerFor(game);
    await settle(c);
    final ctl = c.read(liveMatchProvider(m1).notifier);
    await ctl.recordStat('p1', StatAction.block, clock: 0);
    await c.read(syncWorkerProvider).syncNow();
    await pumpEventQueue();
    var s = c.read(liveMatchProvider(m1)).requireValue;
    final entry = s.log.single;
    expect(entry.status, EventStatus.rejected);
    expect(entry.rejectReason, 'NOT_AUTHORIZED');
    await ctl.discard(entry.event.id);
    await pumpEventQueue();
    s = c.read(liveMatchProvider(m1)).requireValue;
    expect(s.log, isEmpty);
  });

  group('filtered feed (ADR-0030)', () {
    const parent = Capabilities(roles: {TenantRole.parent}, linkedPlayerIds: {'p1'}, personId: 'person-me');

    RecordedEvent shot(String id, String player, int points, {int clock = 500}) => RecordedEvent(Shot(
      EventMeta(id: id, deviceId: 'coach-tablet', clientSeq: clock, period: 1, clockSecondsRemaining: clock,
          recordedAtClient: DateTime.utc(2026, 11, 7, 10)),
      playerId: player, points: points, made: true,
    ));

    FakeGame coachScored() => liveGame()
      ..server.visiblePlayers = {'p1'}
      ..server.preload(m1, [
        RecordedEventFixture.periodStart(period: 1, clock: 600),
        shot('0190b6a0-0000-7000-8000-0000000000d1', 'p2', 3, clock: 550),
        shot('0190b6a0-0000-7000-8000-0000000000d2', 'p1', 2, clock: 540),
      ], personId: 'coach');

    test('a parent never receives other players\' events; the score comes from the server box score', () async {
      final game = coachScored();
      final c = containerFor(game, caps: parent);
      await settle(c);
      await c.read(syncWorkerProvider).syncNow(matchId: m1);
      await pumpEventQueue();
      final s = c.read(liveMatchProvider(m1)).requireValue;
      expect(s.synced.map((e) => e.event.playerId), isNot(contains('p2')));
      expect(s.projection.summary.teamScore, 2, reason: 'the local replay only knows the linked player');
      expect(s.team.teamScore, 5);
      expect(s.team.periodScores!.first.team, 5);
      expect(s.team.teamTotals!.fg3Made, 1);
    });

    test('own unsynced events count at once; hidden server events with the next refresh', () async {
      final game = coachScored();
      final c = containerFor(game, caps: parent);
      await settle(c);
      await c.read(syncWorkerProvider).syncNow(matchId: m1);
      await pumpEventQueue();
      game.server.offline = true;
      await c.read(liveMatchProvider(m1).notifier).recordStat('p1', StatAction.threeMade, clock: 530);
      await pumpEventQueue();
      expect(c.read(liveMatchProvider(m1)).requireValue.team.teamScore, 8);

      game.server.offline = false;
      await c.read(syncWorkerProvider).syncNow(matchId: m1);
      await pumpEventQueue();
      var s = c.read(liveMatchProvider(m1)).requireValue;
      expect(s.own.single.status, EventStatus.accepted);
      expect(s.team.teamScore, 8, reason: 'stored now, counted once');

      game.server.preload(m1, [shot('0190b6a0-0000-7000-8000-0000000000d3', 'p2', 2, clock: 520)], personId: 'coach');
      await c.read(syncWorkerProvider).syncNow(matchId: m1);
      await pumpEventQueue();
      expect(c.read(liveMatchProvider(m1)).requireValue.team.teamScore, 8, reason: 'the feed brought nothing visible');
      for (final t in [...game.timers.periodic]) {
        await t.tick();
      }
      await pumpEventQueue();
      s = c.read(liveMatchProvider(m1)).requireValue;
      expect(s.team.teamScore, 10, reason: 'the periodic box-score refresh');
    });

    test('offline without a box score: the cached match score, period scores and totals unknown', () async {
      final game = coachScored();
      game.matches.matches[0] = gameMatch(m1, team: 5).rebuild((b) => b.lastServerSeq = 3);
      game.matches.boxScoreOf = (_) => throw const AppError(kind: AppErrorKind.network);
      final c = containerFor(game, caps: parent);
      final s = await settle(c);
      expect(s.team.teamScore, 5);
      expect(s.team.periodScores, isNull);
      expect(s.team.teamTotals, isNull);
    });

    test('staff: team figures are the local projection, no box score request', () async {
      final game = coachScored()..server.visiblePlayers = null;
      final c = containerFor(game);
      await settle(c);
      await c.read(syncWorkerProvider).syncNow(matchId: m1);
      await pumpEventQueue();
      final s = c.read(liveMatchProvider(m1)).requireValue;
      expect(s.team.teamScore, 5);
      expect(s.team.teamScore, s.projection.summary.teamScore);
      expect(game.matches.calls, isNot(contains('boxScore')));
    });
  });

  test('recording triggers a background sync', () async {
    final game = liveGame();
    final c = containerFor(game);
    await settle(c);
    await c.read(liveMatchProvider(m1).notifier).recordStat('p1', StatAction.defensiveRebound, clock: 0);
    await pumpEventQueue(times: 50);
    expect(game.server.stored(m1).length, 1);
  });
}

/// Server-side events of other scorers.
abstract final class RecordedEventFixture {
  static RecordedEvent shot(String id) => RecordedEvent(Shot(
    EventMeta(id: id, deviceId: 'coach-tablet', clientSeq: 1, period: 1, clockSecondsRemaining: 500, recordedAtClient: DateTime.utc(2026, 11, 7, 10)),
    playerId: 'p2', points: 2, made: true,
  ));

  static RecordedEvent periodStart({required int period, required int clock}) => RecordedEvent(PeriodStart(EventMeta(
    id: '0190b6a0-0000-7000-8000-0000000000b$period', deviceId: 'coach-tablet', clientSeq: period, period: period,
    clockSecondsRemaining: clock, recordedAtClient: DateTime.utc(2026, 11, 7, 10, period),
  )));
}
