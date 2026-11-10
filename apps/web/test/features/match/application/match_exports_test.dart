import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/export/csv_writer.dart';
import 'package:hoops_app/core/export/export_table.dart';
import 'package:hoops_app/core/time/tenant_zone.dart';
import 'package:hoops_app/features/match/application/match_exports.dart';
import 'package:hoops_app/features/match/domain/projector/projection.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

AppLocalizations l(String lang) => lookupAppLocalizations(Locale(lang));

gen.StatLine apiLine({int points = 10, int seconds = 750}) => gen.StatLine(
  (b) => b
    ..points = points
    ..fg1Made = 2
    ..fg1Attempted = 3
    ..fg2Made = 2
    ..fg2Attempted = 5
    ..fg3Made = 1
    ..fg3Attempted = 4
    ..assists = 3
    ..offensiveRebounds = 1
    ..defensiveRebounds = 4
    ..turnovers = 2
    ..steals = 1
    ..blocks = 0
    ..personalFouls = 3
    ..technicalFouls = 0
    ..unsportsmanlikeFouls = 0
    ..secondsPlayed = seconds,
);

gen.PlayerSeasonStats seasonStats() => gen.PlayerSeasonStats(
  (b) => b
    ..playerId = 'p1'
    ..seasonId = 's1'
    ..gamesPlayed = 2
    ..gamesStarted = 1
    ..totals.replace(apiLine(points: 25, seconds: 1500))
    ..averages.points = 12.5
    ..averages.assists = 1
    ..averages.rebounds = 2
    ..averages.steals = 0
    ..averages.blocks = 0
    ..averages.turnovers = 0
    ..averages.personalFouls = 1
    ..averages.minutesPlayed = 12.5
    ..matches.addAll([
      gen.PlayerMatchLine(
        (m) => m
          ..matchId = 'm1'
          ..scheduledAt = DateTime.utc(2026, 10, 31, 22, 30)
          ..opponentName = '=Lobos'
          ..status = gen.MatchStatus.FINISHED
          ..wasStarter = true
          ..stats.replace(apiLine()),
      ),
      gen.PlayerMatchLine(
        (m) => m
          ..matchId = 'm2'
          ..scheduledAt = DateTime.utc(2026, 11, 7, 10)
          ..opponentName = 'Tigres'
          ..status = gen.MatchStatus.FINISHED
          ..wasStarter = false
          ..stats.replace(apiLine(points: 15, seconds: 750)),
      ),
    ]),
);

Object? value(ExportCell c) => switch (c) {
  TextCell(:final value) => value,
  NumberCell(:final value) => value,
  DateCell(:final value) => isoDate(value),
  TimeCell(:final hour, :final minute) => isoTime(hour, minute),
  EmptyCell() => null,
};

List<Object?> rowOf(ExportTable t, int i) => [
  for (final c in t.rows[i]) value(c),
];

void main() {
  final madrid = TenantZone.of('Europe/Madrid');

  group('playerStatsTable', () {
    final table = playerStatsTable(
      l('en'),
      seasonStats(),
      zone: madrid,
      playerName: 'Ana Ruiz',
    );

    test('headers are in the user language', () {
      expect(table.headers.take(7), [
        'Player',
        'Date',
        'Start time',
        'Time zone',
        'Opponent',
        'Status',
        'Starter',
      ]);
      expect(
        playerStatsTable(l('es'), seasonStats(), zone: madrid).headers[1],
        'Fecha',
      );
      expect(
        playerStatsTable(l('id'), seasonStats(), zone: madrid).headers[1],
        'Tanggal',
      );
    });

    test('one row per match plus the season totals', () {
      expect(table.rows, hasLength(3));
    });

    test('a match row: academy-zone date and time, status, typed numbers', () {
      final r = rowOf(table, 0);
      expect(r.sublist(0, 7), [
        'Ana Ruiz',
        '2026-10-31',
        '23:30',
        'Europe/Madrid',
        '=Lobos',
        'Finished',
        'Yes',
      ]);
      // MIN, PTS, REB, AST, STL, BLK, TOV, PF
      expect(r.sublist(7, 15), [12.5, 10, 5, 3, 1, 0, 2, 3]);
      // FG made/att, 3P made/att, FT made/att
      expect(r.sublist(15), [3, 9, 1, 4, 2, 3]);
    });

    test('the date follows the academy zone, not the device', () {
      // 22:30 UTC on 31 Oct is already 1 Nov in Jakarta.
      final jakarta = playerStatsTable(
        l('en'),
        seasonStats(),
        zone: TenantZone.of('Asia/Jakarta'),
      );
      expect(value(jakarta.rows[0][1]), '2026-11-01');
      expect(value(jakarta.rows[0][2]), '05:30');
    });

    test('a bench player reads No', () {
      expect(rowOf(table, 1)[6], 'No');
    });

    test('the totals row closes the table', () {
      final r = rowOf(table, 2);
      expect(r[0], 'Ana Ruiz');
      expect(r[1], isNull);
      expect(r[4], 'Totals');
      expect(r[6], 1); // games started
      expect(r.sublist(7, 15), [25, 25, 5, 3, 1, 0, 2, 3]);
    });

    test('CSV: the opponent that looks like a formula is guarded', () {
      final csv = CsvWriter.write(table);
      expect(csv, contains("'=Lobos"));
      expect(csv, startsWith('﻿Player,Date,Start time,Time zone,'));
    });

    test('the sheet is named in the user language', () {
      expect(table.sheetName, 'Player stats');
      expect(
        playerStatsTable(l('es'), seasonStats(), zone: madrid).sheetName,
        'Estadísticas',
      );
    });
  });

  group('boxScoreTable', () {
    const ana = BoxScoreLine(
      name: 'Ana Ruiz',
      jersey: '4',
      starter: true,
      stats: StatLine(
        points: 12,
        fg2Made: 4,
        fg2Attempted: 8,
        fg3Made: 1,
        fg3Attempted: 3,
        fg1Made: 1,
        fg1Attempted: 2,
        assists: 2,
        offensiveRebounds: 1,
        defensiveRebounds: 3,
        secondsPlayed: 1230,
      ),
    );
    const bo = BoxScoreLine(
      name: '-Bo',
      jersey: null,
      starter: false,
      stats: StatLine(points: 3, steals: 1, secondsPlayed: 60),
    );
    final table = boxScoreTable(
      l('en'),
      BoxScoreExport(
        teamName: 'Mini A',
        opponentName: 'Tigres',
        lines: const [ana, bo],
        totals: const StatLine(points: 15, secondsPlayed: 1290),
        teamScore: 15,
        opponentScore: 9,
      ),
    );

    test('headers', () {
      expect(table.headers.take(5), [
        'Team',
        'Player',
        'Jersey',
        'Starter',
        'MIN',
      ]);
      expect(table.headers.last, 'FT attempted');
    });

    test('every player line of our team', () {
      expect(rowOf(table, 0).sublist(0, 4), ['Mini A', 'Ana Ruiz', '4', 'Yes']);
      expect(rowOf(table, 0).sublist(4), [
        20.5,
        12,
        4,
        2,
        0,
        0,
        0,
        0,
        5,
        11,
        1,
        3,
        1,
        2,
      ]);
      expect(rowOf(table, 1).sublist(0, 4), ['Mini A', '-Bo', null, 'No']);
    });

    test('team totals, then the opponent as a score-only line', () {
      expect(rowOf(table, 2).sublist(0, 2), ['Mini A', 'Team totals']);
      expect(rowOf(table, 2)[5], 15);
      expect(rowOf(table, 3).sublist(0, 2), ['Tigres', 'Team totals']);
      expect(rowOf(table, 3)[5], 9);
      expect(rowOf(table, 3)[4], isNull);
    });

    test('no totals known: no totals row for our team', () {
      final t = boxScoreTable(
        l('en'),
        const BoxScoreExport(
          teamName: 'Mini A',
          opponentName: 'Tigres',
          lines: [ana],
          totals: null,
          teamScore: 15,
          opponentScore: 9,
        ),
      );
      expect(t.rows, hasLength(2));
    });

    test('a negative score would stay numeric in CSV', () {
      expect(CsvWriter.write(table), contains("'-Bo"));
    });
  });
}
