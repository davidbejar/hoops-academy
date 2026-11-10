import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../core/export/export_table.dart';
import '../../../core/time/tenant_zone.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../domain/projector/projection.dart';
import 'match_labels.dart';

/// Tables for the match exports (WP97): the same figures the screens show,
/// as typed cells with headers in the user's language. Pure functions over
/// data the app has already loaded.

/// Minutes with two decimals, as a number (not "12:30" text) so a
/// spreadsheet can add them up.
double _minutes(int seconds) => (seconds / 60 * 100).round() / 100;

NumberCell _n(num v) => NumberCell(v);

/// The stat columns of both tables, in the order of the on-screen box score:
/// MIN PTS REB AST STL BLK TOV PF, then made / attempted for FG, 3P and FT.
List<String> _statHeaders(AppLocalizations l) => [
  l.matchColMin,
  l.matchColPts,
  l.matchColReb,
  l.matchColAst,
  l.matchColStl,
  l.matchColBlk,
  l.matchColTov,
  l.matchColPf,
  l.exportMade(l.matchColFg),
  l.exportAttempted(l.matchColFg),
  l.exportMade(l.matchCol3p),
  l.exportAttempted(l.matchCol3p),
  l.exportMade(l.matchColFt),
  l.exportAttempted(l.matchColFt),
];

List<ExportCell> _statCells(StatLine s) => [
  _n(_minutes(s.secondsPlayed)),
  _n(s.points),
  _n(s.rebounds),
  _n(s.assists),
  _n(s.steals),
  _n(s.blocks),
  _n(s.turnovers),
  _n(s.personalFouls),
  _n(s.fgMade),
  _n(s.fgAttempted),
  _n(s.fg3Made),
  _n(s.fg3Attempted),
  _n(s.fg1Made),
  _n(s.fg1Attempted),
];

StatLine _fromApi(gen.StatLine s) => StatLine(
  points: s.points,
  fg1Made: s.fg1Made,
  fg1Attempted: s.fg1Attempted,
  fg2Made: s.fg2Made,
  fg2Attempted: s.fg2Attempted,
  fg3Made: s.fg3Made,
  fg3Attempted: s.fg3Attempted,
  assists: s.assists,
  offensiveRebounds: s.offensiveRebounds,
  defensiveRebounds: s.defensiveRebounds,
  turnovers: s.turnovers,
  steals: s.steals,
  blocks: s.blocks,
  personalFouls: s.personalFouls,
  technicalFouls: s.technicalFouls,
  unsportsmanlikeFouls: s.unsportsmanlikeFouls,
  secondsPlayed: s.secondsPlayed,
);

String _yesNo(AppLocalizations l, bool v) => v ? l.exportYes : l.exportNo;

/// One row per match of the season plus a closing row with the season totals.
ExportTable playerStatsTable(
  AppLocalizations l,
  gen.PlayerSeasonStats stats, {
  required TenantZone zone,
  String? playerName,
}) {
  ExportCell player() =>
      playerName == null ? const EmptyCell() : TextCell(playerName);
  final rows = <List<ExportCell>>[
    for (final m in stats.matches)
      () {
        final wall = zone.wall(m.scheduledAt);
        return <ExportCell>[
          player(),
          DateCell(wall),
          TimeCell(wall.hour, wall.minute),
          TextCell(zone.label ?? ''),
          TextCell(m.opponentName),
          TextCell(statusLabel(l, m.status)),
          TextCell(_yesNo(l, m.wasStarter)),
          ..._statCells(_fromApi(m.stats)),
        ];
      }(),
    [
      player(),
      const EmptyCell(),
      const EmptyCell(),
      const EmptyCell(),
      TextCell(l.seasonStatsTotals),
      const EmptyCell(),
      _n(stats.gamesStarted),
      ..._statCells(_fromApi(stats.totals)),
    ],
  ];
  return ExportTable(
    sheetName: l.exportSheetPlayerStats,
    headers: [
      l.exportColPlayer,
      l.matchDate,
      l.exportColTime,
      l.exportColZone,
      l.matchOpponent,
      l.exportColStatus,
      l.exportColStarter,
      ..._statHeaders(l),
    ],
    rows: rows,
  );
}

/// A player line of the box score the person may see.
class BoxScoreLine {
  const BoxScoreLine({
    required this.name,
    required this.jersey,
    required this.starter,
    required this.stats,
  });
  final String name;
  final String? jersey;
  final bool starter;
  final StatLine stats;
}

/// What the box score export needs from a match: our lines (only those the
/// role may see), our totals when known, and the opponent as a score.
class BoxScoreExport {
  const BoxScoreExport({
    required this.teamName,
    required this.opponentName,
    required this.lines,
    required this.totals,
    required this.teamScore,
    required this.opponentScore,
  });
  final String teamName;
  final String opponentName;
  final List<BoxScoreLine> lines;
  final StatLine? totals;
  final int teamScore;
  final int opponentScore;
}

/// Both teams: every visible player line and the totals of ours, and the
/// opponent's total (the app records the opponent's score, not its players).
ExportTable boxScoreTable(AppLocalizations l, BoxScoreExport box) {
  const empty = EmptyCell();
  return ExportTable(
    sheetName: l.exportSheetBoxScore,
    headers: [
      l.matchTeam,
      l.exportColPlayer,
      l.exportColNumber,
      l.exportColStarter,
      ..._statHeaders(l),
    ],
    rows: [
      for (final line in box.lines)
        [
          TextCell(box.teamName),
          TextCell(line.name),
          line.jersey == null ? empty : TextCell(line.jersey!),
          TextCell(_yesNo(l, line.starter)),
          ..._statCells(line.stats),
        ],
      if (box.totals != null)
        [
          TextCell(box.teamName),
          TextCell(l.matchTotals),
          empty,
          empty,
          ..._statCells(box.totals!),
        ],
      [
        TextCell(box.opponentName),
        TextCell(l.matchTotals),
        empty,
        empty,
        // MIN is unknown, PTS is the opponent's score, the rest is not recorded.
        empty,
        _n(box.opponentScore),
        ...List<ExportCell>.filled(12, empty),
      ],
    ],
  );
}
