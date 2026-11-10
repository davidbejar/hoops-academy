import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/export/ics_writer.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../support/core_fixtures.dart';
import '../../../support/fake_athlete.dart';
import '../../../support/fake_export.dart';
import '../../../support/fake_game.dart';
import '../../../support/fake_repos.dart';
import '../../../support/export_overrides.dart';
import '../../../support/pump_helpers.dart';

import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/errors/app_error.dart';

import '../../../support/ics_validator.dart';

const fin = 'm-fin';
const sched = 'm-sched';

String _id(String suffix) =>
    '0190b6a0-0000-7000-8000-0000000000${suffix.padLeft(2, '0')}';

EventMeta _meta(String id, int clock) => EventMeta(
  id: _id(id),
  deviceId: 'coach-tablet',
  clientSeq: clock,
  period: 1,
  clockSecondsRemaining: clock,
  recordedAtClient: DateTime.utc(2026, 10, 31, 10, 10 - clock ~/ 100),
);

FakeCore coreWithTeam() => FakeCore(
  teams: FakeTeamsRepository(
    teams: [team(teamA, 'Mini A')],
    rosters: {
      teamA: [
        teamPlayer(teamA, 'p1', 'Ana Ruiz', jersey: '4'),
        teamPlayer(teamA, 'p2', 'Bo Gil', jersey: '5'),
      ],
    },
  ),
  players: FakePlayersRepository([player('p1', 'Ana Ruiz')]),
);

FakeGame game() {
  final g = FakeGame(
    matches: FakeMatchesRepository(
      matches: [
        gameMatch(
          fin,
          status: gen.MatchStatus.FINISHED,
          opponent: 'Lobos',
          team: 0,
          at: DateTime.utc(2026, 10, 31, 10),
          seasonId: seasonId,
        ),
        gameMatch(
          sched,
          status: gen.MatchStatus.SCHEDULED,
          opponent: 'Águilas',
          at: DateTime.utc(2026, 11, 14, 10),
          seasonId: seasonId,
        ),
      ],
      rosters: {fin: demoRoster},
      seasonStatsResult: gen.PlayerSeasonStats(
        (b) => b
          ..playerId = 'p1'
          ..seasonId = seasonId
          ..gamesPlayed = 1
          ..gamesStarted = 1
          ..totals.replace(_line(8))
          ..averages.points = 8
          ..averages.assists = 1
          ..averages.rebounds = 2
          ..averages.steals = 0
          ..averages.blocks = 0
          ..averages.turnovers = 0
          ..averages.personalFouls = 1
          ..averages.minutesPlayed = 10
          ..matches.add(
            gen.PlayerMatchLine(
              (m) => m
                ..matchId = fin
                ..scheduledAt = DateTime.utc(2026, 10, 31, 10)
                ..opponentName = 'Lobos'
                ..status = gen.MatchStatus.FINISHED
                ..wasStarter = true
                ..stats.replace(_line(8)),
            ),
          ),
      ),
    ),
  );
  g.server.preload(fin, [
    RecordedEvent(PeriodStart(_meta('e1', 600))),
    RecordedEvent(
      Shot(_meta('e2', 500), playerId: 'p1', points: 2, made: true),
    ),
    RecordedEvent(
      Shot(_meta('e3', 450), playerId: 'p2', points: 3, made: true),
    ),
    RecordedEvent(OpponentScore(_meta('e4', 400), points: 3)),
    RecordedEvent(PeriodEnd(_meta('e5', 0))),
  ], personId: 'coach');
  return g;
}

gen.StatLine _line(int points) => gen.StatLine(
  (b) => b
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
    ..secondsPlayed = 600,
);

Future<void> settleFeed(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

String csvOf(SavedFile f) => utf8.decode(f.bytes);

void main() {
  late FakeFileDownloader downloader;

  setUp(() => downloader = FakeFileDownloader());

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    Set<TenantRole> roles = const {TenantRole.coach},
    FakeGame? withGame,
    FakeAthlete? athlete,
    bool excelOffline = false,
    Size size = const Size(360, 780),
    Set<String> linked = const {},
    String? ownPlayer,
  }) => pumpAs(
    tester,
    roles: roles,
    staffTeamIds: roles.contains(TenantRole.coach) ? {teamA} : {},
    linkedPlayerIds: linked,
    ownPlayerId: ownPlayer,
    core: coreWithTeam(),
    game: withGame ?? game(),
    athlete: athlete,
    location: location,
    size: size,
    overrides: exportOverrides(downloader, excelOffline: excelOffline),
  );

  Future<void> choose(WidgetTester tester, String format) async {
    await tapKey(tester, 'export-menu');
    await tapKey(tester, 'export-$format');
  }

  group('player stats (season statistics screen)', () {
    testWidgets('CSV: one row per match plus the totals', (tester) async {
      await pumpAt(tester, '/matches/stats/p1');
      await choose(tester, 'csv');
      final f = downloader.saved.single;
      expect(f.fileName, 'hoops-role-test-player-stats-ana-ruiz-20261110.csv');
      expect(f.bytes.take(3), [0xEF, 0xBB, 0xBF], reason: 'UTF-8 BOM');
      final text = csvOf(f);
      expect(text, startsWith('Jugador,Fecha,Hora de inicio'));
      expect(text, contains('Ana Ruiz,2026-10-31,'));
      expect(text, contains(',Lobos,Finalizado,Sí,'));
      expect(text, contains(',Totales,'));
      expect(find.textContaining('Descargado hoops-role-test'), findsOneWidget);
    });

    testWidgets('the menu offers CSV and Excel, not the calendar', (
      tester,
    ) async {
      await pumpAt(tester, '/matches/stats/p1');
      await tapKey(tester, 'export-menu');
      expect(find.byKey(const Key('export-csv')), findsOneWidget);
      expect(find.byKey(const Key('export-xlsx')), findsOneWidget);
      expect(find.byKey(const Key('export-ics')), findsNothing);
    });

    testWidgets('Excel goes through the deferred builder', (tester) async {
      await pumpAt(tester, '/matches/stats/p1');
      await choose(tester, 'xlsx');
      final f = downloader.saved.single;
      expect(f.fileName, endsWith('-20261110.xlsx'));
      expect(utf8.decode(f.bytes), 'xlsx:Estadísticas');
    });

    testWidgets('Excel cannot be loaded: a message, CSV still works', (
      tester,
    ) async {
      await pumpAt(tester, '/matches/stats/p1', excelOffline: true);
      await choose(tester, 'xlsx');
      expect(downloader.saved, isEmpty);
      expect(find.textContaining('No se pudo cargar Excel'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await choose(tester, 'csv');
      expect(downloader.saved, hasLength(1));
    });

    testWidgets('a parent sees the same button', (tester) async {
      await pumpAt(
        tester,
        '/matches/stats/p1',
        roles: {TenantRole.parent},
        linked: {'p1'},
      );
      expect(find.byKey(const Key('export-menu')), findsOneWidget);
    });
  });

  group('box score (match screen)', () {
    testWidgets('CSV: both teams, every line, the totals', (tester) async {
      await pumpAt(tester, '/matches/$fin');
      await settleFeed(tester);
      await choose(tester, 'csv');
      final f = downloader.saved.single;
      expect(f.fileName, 'hoops-role-test-box-score-vs-lobos-20261110.csv');
      final text = csvOf(f);
      expect(text, contains('Equipo,Jugador,Dorsal,Titular,MIN,PTS'));
      expect(text, contains('Mini A,Ana Ruiz,4,Sí,'));
      expect(text, contains('Mini A,Total equipo,'));
      expect(text, contains('Lobos,Total equipo,,,,3,'));
    });

    testWidgets('a player exports the lines they may see only', (tester) async {
      await pumpAt(
        tester,
        '/matches/$fin',
        roles: {TenantRole.player},
        ownPlayer: 'p1',
      );
      await settleFeed(tester);
      await choose(tester, 'csv');
      final text = csvOf(downloader.saved.single);
      expect(text, contains('Ana Ruiz'));
      expect(text, isNot(contains('Bo Gil')));
    });

    testWidgets('the menu offers CSV and Excel', (tester) async {
      await pumpAt(tester, '/matches/$fin');
      await settleFeed(tester);
      await tapKey(tester, 'export-menu');
      expect(find.byKey(const Key('export-xlsx')), findsOneWidget);
      expect(find.byKey(const Key('export-ics')), findsNothing);
    });
  });

  group('team calendar (matches list)', () {
    FakeAthlete athleteWithSessions() => FakeAthlete(
      training: FakeTrainingRepository(
        sessions: [
          session('s1', teamId: teamA, day: DateTime(2026, 11, 12)),
          session(
            's2',
            teamId: teamA,
            day: DateTime(2026, 11, 13),
            status: ath.TrainingSessionStatus.CANCELLED,
            cancelReason: 'Lluvia',
          ),
        ],
      ),
    );

    testWidgets('ICS: matches and sessions merged, valid RFC 5545', (
      tester,
    ) async {
      await pumpAt(tester, '/matches', athlete: athleteWithSessions());
      await choose(tester, 'ics');
      final f = downloader.saved.single;
      expect(f.fileName, 'hoops-role-test-calendar-20261110.ics');
      expect(f.mediaType, IcsWriter.mediaType);
      final text = utf8.decode(f.bytes);
      expect(validateIcs(f.bytes), isEmpty);
      expect(text, contains('UID:match-$fin@hoops-academy'));
      expect(text, contains('UID:match-$sched@hoops-academy'));
      expect(text, contains('UID:training-s1@hoops-academy'));
      expect(text, contains('STATUS:CANCELLED'));
      expect(text.indexOf('match-$fin'), lessThan(text.indexOf('training-s1')));
    });

    testWidgets('CSV is sorted by start and has the sessions', (tester) async {
      await pumpAt(tester, '/matches', athlete: athleteWithSessions());
      await choose(tester, 'csv');
      final text = csvOf(downloader.saved.single);
      final lines = text.split('\r\n');
      expect(lines.first, contains('Fecha,Hora de inicio,Hora de fin'));
      final dates = [
        for (final l in lines.skip(1))
          if (l.isNotEmpty) l.substring(0, 10),
      ];
      expect([...dates]..sort(), dates);
      expect(dates, hasLength(4));
    });

    testWidgets('training sessions unreadable offline: matches only, said so', (
      tester,
    ) async {
      final athlete = athleteWithSessions();
      await pumpAt(tester, '/matches', athlete: athlete);
      athlete.training.failWith = const AppError(kind: AppErrorKind.network);
      await choose(tester, 'ics');
      final text = utf8.decode(downloader.saved.single.bytes);
      expect(text, contains('UID:match-$fin@hoops-academy'));
      expect(text, isNot(contains('UID:training')));
      expect(
        find.textContaining('el archivo solo incluye los partidos'),
        findsOneWidget,
      );
    });

    testWidgets('matches unreadable but seen on the list: the cache is used', (
      tester,
    ) async {
      final g = game();
      await pumpAt(
        tester,
        '/matches',
        withGame: g,
        athlete: athleteWithSessions(),
      );
      g.matches.failWith = const AppError(kind: AppErrorKind.network);
      await choose(tester, 'ics');
      final text = utf8.decode(downloader.saved.single.bytes);
      expect(text, contains('UID:match-$fin@hoops-academy'));
      expect(text, contains('UID:training-s1@hoops-academy'));
      expect(find.textContaining('solo incluye'), findsNothing);
    });

    testWidgets('matches unreadable, nothing cached: sessions only, said so', (
      tester,
    ) async {
      final g = game()
        ..matches.failWith = const AppError(kind: AppErrorKind.network);
      await pumpAt(
        tester,
        '/training',
        withGame: g,
        athlete: athleteWithSessions(),
      );
      await choose(tester, 'ics');
      final text = utf8.decode(downloader.saved.single.bytes);
      expect(text, contains('UID:training-s1@hoops-academy'));
      expect(text, isNot(contains('UID:match')));
      expect(
        find.textContaining('el archivo solo incluye los entrenamientos'),
        findsOneWidget,
      );
    });

    testWidgets('both sources down: the error message, no file', (
      tester,
    ) async {
      final g = game()
        ..matches.failWith = const AppError(kind: AppErrorKind.network);
      final athlete = athleteWithSessions();
      await pumpAt(tester, '/training', withGame: g, athlete: athlete);
      athlete.training.failWith = const AppError(kind: AppErrorKind.network);
      await choose(tester, 'ics');
      expect(downloader.saved, isEmpty);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('the training list has the same menu and file', (tester) async {
      await pumpAt(tester, '/training', athlete: athleteWithSessions());
      await choose(tester, 'ics');
      final text = utf8.decode(downloader.saved.single.bytes);
      expect(text, contains('UID:training-s1@hoops-academy'));
      expect(text, contains('UID:match-$fin@hoops-academy'));
    });

    testWidgets('a parent can export the calendar they see', (tester) async {
      await pumpAt(
        tester,
        '/matches',
        roles: {TenantRole.parent},
        linked: {'p1'},
        athlete: athleteWithSessions(),
      );
      expect(find.byKey(const Key('export-menu')), findsOneWidget);
    });
  });
}
