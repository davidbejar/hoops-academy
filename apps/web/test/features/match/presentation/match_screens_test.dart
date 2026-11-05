import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/match/application/match_providers.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../support/core_fixtures.dart';
import '../../../support/fake_game.dart';
import '../../../support/fake_repos.dart';
import '../../../support/harness.dart';
import '../../../support/pump_helpers.dart';

const live = 'm-live';
const sched = 'm-sched';
const fin = 'm-fin';

FakeCore coreWithTeam() => FakeCore(
  teams: FakeTeamsRepository(
    teams: [team(teamA, 'Mini A')],
    rosters: {
      teamA: [
        teamPlayer(teamA, 'p1', 'Ana Ruiz', jersey: '4'),
        teamPlayer(teamA, 'p2', 'Bo Gil', jersey: '5'),
        teamPlayer(teamA, 'p3', 'Cai Soto'),
      ],
    },
  ),
);

FakeGame gameWith({List<gen.Match>? matches}) => FakeGame(
  matches: FakeMatchesRepository(
    matches: matches ??
        [
          gameMatch(live, opponent: 'Tigres', team: 0),
          gameMatch(sched, status: gen.MatchStatus.SCHEDULED, opponent: 'Águilas', at: DateTime.utc(2026, 11, 14, 10)),
          gameMatch(fin, status: gen.MatchStatus.FINISHED, opponent: 'Lobos', team: 0, at: DateTime.utc(2026, 10, 31, 10)),
        ],
    rosters: {live: demoRoster, fin: demoRoster},
  ),
);

Future<Harness> pumpCoach(WidgetTester tester, FakeGame game, String location, {bool settle = true, Size size = const Size(360, 780)}) =>
    pumpAs(
      tester,
      roles: {TenantRole.coach},
      staffTeamIds: {teamA},
      core: coreWithTeam(),
      game: game,
      location: location,
      settle: settle,
      size: size,
    );

Future<Harness> pumpParent(WidgetTester tester, FakeGame game, String location) => pumpAs(
  tester,
  roles: {TenantRole.parent},
  linkedPlayerIds: {'p1'},
  core: coreWithTeam(),
  game: game,
  location: location,
);

Future<Harness> pumpPlayer(WidgetTester tester, FakeGame game, String location) => pumpAs(
  tester,
  roles: {TenantRole.player},
  ownPlayerId: 'p1',
  core: coreWithTeam(),
  game: game,
  location: location,
);

String? textOf(WidgetTester tester, String key) => tester.widget<Text>(find.byKey(Key(key))).data;

Future<void> tapAction(WidgetTester tester, String player, String action) async {
  await tapKey(tester, 'player-$player');
  await tapKey(tester, 'action-$action');
  await clearSnackBars(tester);
}

/// Lets the confirmation snack bar expire so it does not cover the bench.
Future<void> clearSnackBars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('match list', () {
    testWidgets('loading', (tester) async {
      final game = gameWith()..matches.hang = true;
      await pumpCoach(tester, game, '/matches', settle: false);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('error with retry', (tester) async {
      final game = gameWith()..matches.failWith = const AppError(kind: AppErrorKind.forbidden, status: 403);
      await pumpCoach(tester, game, '/matches');
      expect(find.text('Reintentar'), findsWidgets);
      game.matches.failWith = null;
      await tester.tap(find.text('Reintentar').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('match-$live')), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await pumpCoach(tester, gameWith(matches: []), '/matches');
      expect(find.text('No hay partidos'), findsOneWidget);
    });

    testWidgets('populated: status chips, score, create button for staff', (tester) async {
      await pumpCoach(tester, gameWith(), '/matches');
      expect(find.byKey(const Key('match-$live')), findsOneWidget);
      expect(find.byKey(const Key('match-$fin')), findsOneWidget);
      expect(find.byKey(const Key('status-LIVE')), findsOneWidget);
      expect(find.byKey(const Key('status-SCHEDULED')), findsOneWidget);
      expect(find.byKey(const Key('match-new')), findsOneWidget);
      expect(find.byKey(const Key('match-team-filter')), findsOneWidget);
    });

    testWidgets('offline: cached list after a successful load', (tester) async {
      final game = gameWith();
      final h = await pumpCoach(tester, game, '/matches');
      game.matches.failWith = const AppError(kind: AppErrorKind.network);
      h.container.invalidate(matchListProvider);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('match-list-cached')), findsOneWidget);
      expect(find.byKey(const Key('match-$live')), findsOneWidget);
    });

    testWidgets('parent: no team filter, no create button', (tester) async {
      await pumpParent(tester, gameWith(), '/matches');
      expect(find.byKey(const Key('match-$live')), findsOneWidget);
      expect(find.byKey(const Key('match-new')), findsNothing);
      expect(find.byKey(const Key('match-team-filter')), findsNothing);
    });

    testWidgets('create a match', (tester) async {
      final game = gameWith();
      await pumpCoach(tester, game, '/matches');
      await tapKey(tester, 'match-new');
      await enter(tester, 'match-new-opponent', 'Halcones');
      await tapKey(tester, 'form-submit');
      expect(game.matches.calls, contains('create'));
      expect(find.text('vs Halcones'), findsOneWidget);
    });
  });

  group('match setup', () {
    testWidgets('pick players, starters and jersey; save stores and caches the roster', (tester) async {
      final game = gameWith();
      await pumpCoach(tester, game, '/matches/$sched/setup');
      expect(find.byKey(const Key('setup-p1')), findsOneWidget);
      await tapKey(tester, 'setup-save');
      expect(find.text('Marca al menos un titular'), findsOneWidget);
      expect(game.matches.replacedRosters, isEmpty);

      await tapKey(tester, 'setup-starter-p1');
      await tapKey(tester, 'setup-include-p3');
      await enter(tester, 'setup-jersey-p2', '12');
      await tapKey(tester, 'setup-save');
      final saved = game.matches.replacedRosters.single;
      expect(saved.map((e) => e.playerId), ['p1', 'p2']);
      expect(saved.first.isStarter, isTrue);
      expect(saved[1].jerseyNumber, '12');
      expect((await tester.runAsync(() => game.store.roster(sched)))!.length, 2);
    });

    testWidgets('empty team roster', (tester) async {
      final game = gameWith();
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        staffTeamIds: {teamA},
        core: FakeCore(teams: FakeTeamsRepository(teams: [team(teamA, 'Mini A')])),
        game: game,
        location: '/matches/$sched/setup',
      );
      expect(find.text('El equipo no tiene jugadores'), findsOneWidget);
    });

    testWidgets('parent sees the not-allowed state', (tester) async {
      await pumpParent(tester, gameWith(), '/matches/$sched/setup');
      expect(find.byKey(const Key('forbidden')), findsOneWidget);
    });
  });

  group('live match (staff)', () {
    testWidgets('loading and error states', (tester) async {
      final game = gameWith()..matches.hang = true;
      await pumpCoach(tester, game, '/matches/$live', settle: false);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('error without cache shows retry', (tester) async {
      final game = gameWith()..matches.failWith = const AppError(kind: AppErrorKind.network);
      await pumpCoach(tester, game, '/matches/$live');
      expect(find.text('Reintentar'), findsWidgets);
    });

    testWidgets('no roster: staff gets the setup button', (tester) async {
      await pumpCoach(tester, gameWith(), '/matches/$sched');
      expect(find.text('Este partido aún no tiene convocatoria'), findsOneWidget);
      await tapKey(tester, 'open-setup');
      expect(find.byKey(const Key('setup-save')), findsOneWidget);
    });

    testWidgets('court, clock, period, shot, opponent points, substitution, undo, log', (tester) async {
      final game = gameWith()..server.offline = true;
      await pumpCoach(tester, game, '/matches/$live');
      expect(find.byKey(const Key('game-clock')), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
      expect(find.byKey(const Key('player-p6')), findsOneWidget);

      await tapKey(tester, 'period-start');
      expect(find.byKey(const Key('period-end')), findsOneWidget);
      expect(find.byKey(const Key('period-label')), findsOneWidget);

      await tapAction(tester, 'p1', '3pt-made');
      expect(textOf(tester, 'score-team'), '3');

      await tapKey(tester, 'opponent-2');
      expect(textOf(tester, 'score-opponent'), '2');

      // Substitution: tap a bench player, choose who leaves.
      await tapKey(tester, 'player-p6');
      await tapKey(tester, 'sub-out-p5');
      final own = await tester.runAsync(() => game.store.ownEvents(live));
      expect(own!.map((e) => e.event.type), [
        MatchEventType.periodStart, MatchEventType.shot, MatchEventType.opponentScore,
        MatchEventType.subOut, MatchEventType.subIn,
      ]);

      await tapKey(tester, 'undo'); // voids the SUB_IN
      await tester.tap(find.byKey(const Key('tab-log')));
      await tester.pumpAndSettle();
      expect(find.text('Pendiente'), findsWidgets, reason: 'offline: events wait in the queue');
      expect(find.textContaining('Anulada'), findsOneWidget);
      expect(find.byKey(const Key('sync-banner')), findsOneWidget);
      expect(find.text('6 sin sincronizar'), findsOneWidget);
    });

    testWidgets('reconnect: the banner retry syncs the queue', (tester) async {
      final game = gameWith()..server.offline = true;
      await pumpCoach(tester, game, '/matches/$live');
      await tapKey(tester, 'period-start');
      await tapAction(tester, 'p2', 'ast');
      expect(find.text('2 sin sincronizar'), findsOneWidget);
      game.server.offline = false;
      await tapKey(tester, 'sync-retry');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sync-banner')), findsNothing);
      expect(game.server.stored(live).length, 2);
    });

    testWidgets('REJECTED events show their reason and can be discarded', (tester) async {
      final game = gameWith()..server.rejectWhen = (e) => e is Block ? 'NOT_AUTHORIZED' : null;
      await pumpCoach(tester, game, '/matches/$live');
      await tapAction(tester, 'p1', 'blk');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-log')));
      await tester.pumpAndSettle();
      expect(find.text('Rechazada: sin permiso'), findsOneWidget);
      expect(find.text('1 rechazadas'), findsOneWidget);
      final id = (await tester.runAsync(() => game.store.ownEvents(live)))!.single.event.id;
      await tapKey(tester, 'log-discard-$id');
      await tapKey(tester, 'dialog-confirm');
      expect(find.text('Rechazada: sin permiso'), findsNothing);
    });

    testWidgets('box score tab and finished match with copy', (tester) async {
      final game = gameWith();
      game.server.preload(fin, [
        RecordedEvent(PeriodStart(_meta('e1', 600))),
        RecordedEvent(Shot(_meta('e2', 500), playerId: 'p1', points: 2, made: true)),
        RecordedEvent(OpponentScore(_meta('e3', 400), points: 3)),
        RecordedEvent(PeriodEnd(_meta('e4', 0))),
      ], personId: 'coach');
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      await pumpCoach(tester, game, '/matches/$fin');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('box-score')), findsOneWidget, reason: 'FINISHED opens on the box score');
      expect(find.text('#4 Ana Ruiz *'), findsOneWidget);
      expect(find.byKey(const Key('period-score-1')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('box-copy')),
        100,
        scrollable: find.descendant(of: find.byKey(const Key('box-score')), matching: find.byType(Scrollable)).first,
      );
      await tapKey(tester, 'box-copy');
      expect(copied, contains('Nosotros 2 – 3 Lobos'));
      expect(copied, contains('Ana Ruiz: 2 pts'));
    });

    testWidgets('PLAYER sees their own box score line and no other player\'s', (tester) async {
      final game = gameWith();
      game.server.preload(fin, [
        RecordedEvent(PeriodStart(_meta('e1', 600))),
        RecordedEvent(Shot(_meta('e2', 500), playerId: 'p1', points: 2, made: true)),
        RecordedEvent(Shot(_meta('e3', 450), playerId: 'p2', points: 3, made: true)),
        RecordedEvent(PeriodEnd(_meta('e4', 0))),
      ], personId: 'coach');
      await pumpPlayer(tester, game, '/matches/$fin');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('box-score')), findsOneWidget);
      expect(find.text('#4 Ana Ruiz *'), findsOneWidget);
      expect(find.textContaining('Bo Gil'), findsNothing);
    });

    testWidgets('match menu: start a scheduled match', (tester) async {
      final game = gameWith();
      game.matches.rosters[sched] = demoRoster;
      await pumpCoach(tester, game, '/matches/$sched');
      await tapKey(tester, 'match-menu');
      await tapKey(tester, 'menu-start');
      expect(game.matches.calls, contains('start'));
      expect(find.byKey(const Key('status-LIVE')), findsNothing, reason: 'staff sees the clock, not the chip');
    });
  });

  group('parent-restricted mode', () {
    testWidgets('other players disabled, clock/period/opponent hidden, linked player scores', (tester) async {
      final game = gameWith()..server.offline = true;
      await pumpParent(tester, game, '/matches/$live');
      expect(find.byKey(const Key('parent-mode')), findsOneWidget);
      expect(find.byKey(const Key('game-clock')), findsNothing);
      expect(find.byKey(const Key('period-start')), findsNothing);
      expect(find.byKey(const Key('opponent-2')), findsNothing);
      expect(find.byKey(const Key('timeout-menu')), findsNothing);
      expect(find.byKey(const Key('match-menu')), findsNothing);
      final other = tester.widget<InkWell>(find.byKey(const Key('player-p2')));
      expect(other.onTap, isNull);
      final bench = tester.widget<InkWell>(find.byKey(const Key('player-p6')));
      expect(bench.onTap, isNull);

      await tapAction(tester, 'p1', 'stl');
      final own = await tester.runAsync(() => game.store.ownEvents(live));
      expect(own!.single.event, isA<Steal>());
      expect(own.single.status.unsynced, isTrue);
    });

    testWidgets('parent cannot void a coach event', (tester) async {
      final game = gameWith();
      game.server.preload(live, [RecordedEvent(Shot(_meta('c1', 500), playerId: 'p1', points: 2, made: true))], personId: 'coach');
      await pumpParent(tester, game, '/matches/$live');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-log')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('log-${_id('c1')}')), findsOneWidget);
      expect(find.byKey(Key('log-void-${_id('c1')}')), findsNothing);
    });
  });

  group('season stats', () {
    testWidgets('populated, reached from the player detail', (tester) async {
      final game = gameWith();
      game.matches.seasonStatsResult = _seasonStats();
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        staffTeamIds: {teamA},
        core: FakeCore(players: FakePlayersRepository([player('p1', 'Ana Ruiz')])),
        game: game,
        location: '/players/p1',
      );
      await tapKey(tester, 'player-season-stats');
      expect(find.text('2 partidos · 1 de titular'), findsOneWidget);
      expect(find.byKey(const Key('avg-points')), findsOneWidget);
      expect(find.byKey(const Key('stats-match-$fin')), findsOneWidget);
      expect(game.matches.lastSeasonStatsSeason, seasonId);
    });

    testWidgets('empty and error', (tester) async {
      final game = gameWith();
      game.matches.seasonStatsResult = _seasonStats(empty: true);
      await pumpParent(tester, game, '/matches/stats/p1');
      expect(find.text('Sin partidos en esta temporada'), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      final game = gameWith()..matches.failWith = const AppError(kind: AppErrorKind.notFound, status: 404);
      await pumpParent(tester, game, '/matches/stats/p1');
      expect(find.text('Reintentar'), findsWidgets);
    });
  });
}

String _id(String suffix) => '0190b6a0-0000-7000-8000-0000000000${suffix.padLeft(2, '0')}';

EventMeta _meta(String id, int clock) => EventMeta(
  id: _id(id), deviceId: 'coach-tablet', clientSeq: clock, period: 1, clockSecondsRemaining: clock,
  recordedAtClient: DateTime.utc(2026, 10, 31, 10, 10 - clock ~/ 100),
);

gen.StatLine _line(int points) => gen.StatLine((b) => b
  ..points = points
  ..fg1Made = 0
  ..fg1Attempted = 0
  ..fg2Made = points ~/ 2
  ..fg2Attempted = points ~/ 2
  ..fg3Made = 0
  ..fg3Attempted = 0
  ..assists = 1
  ..offensiveRebounds = 0
  ..defensiveRebounds = 2
  ..turnovers = 0
  ..steals = 0
  ..blocks = 0
  ..personalFouls = 1
  ..technicalFouls = 0
  ..unsportsmanlikeFouls = 0
  ..secondsPlayed = 600);

gen.PlayerSeasonStats _seasonStats({bool empty = false}) => gen.PlayerSeasonStats((b) => b
  ..playerId = 'p1'
  ..seasonId = seasonId
  ..gamesPlayed = empty ? 0 : 2
  ..gamesStarted = empty ? 0 : 1
  ..totals.replace(_line(empty ? 0 : 12))
  ..averages.points = empty ? 0 : 6
  ..averages.assists = 1
  ..averages.rebounds = 2
  ..averages.steals = 0
  ..averages.blocks = 0
  ..averages.turnovers = 0
  ..averages.personalFouls = 1
  ..averages.minutesPlayed = 10
  ..matches.addAll(empty
      ? const []
      : [
          gen.PlayerMatchLine((m) => m
            ..matchId = fin
            ..scheduledAt = DateTime.utc(2026, 10, 31, 10)
            ..opponentName = 'Lobos'
            ..status = gen.MatchStatus.FINISHED
            ..wasStarter = true
            ..stats.replace(_line(8))),
        ]));
