import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/live_match_controller.dart';
import '../domain/projector/projection.dart';
import 'match_labels.dart';

/// Live / final box score from the local projection (same rules as the
/// server). PARENT sees linked players' lines only, like `GET box-score`;
/// score, period scores and totals come from [LiveMatch.team] (for a filtered
/// feed the server's figures, ADR-0028; hidden while unknown offline).
class BoxScoreView extends StatelessWidget {
  const BoxScoreView({super.key, required this.live});
  final LiveMatch live;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = live.projection;
    final periodScores = live.team.periodScores;
    final totals = live.team.teamTotals;
    final lines = [for (final line in p.playerStats) if (live.rights.canSeeLine(line.playerId)) line];
    final warnings = p.warnings.length + p.playerStats.fold<int>(0, (n, x) => n + x.warnings.length);
    final cols = [l.matchColMin, l.matchColPts, l.matchColReb, l.matchColAst, l.matchColStl, l.matchColBlk,
      l.matchColTov, l.matchColPf, l.matchColFg, l.matchCol3p, l.matchColFt];
    return ListView(
      key: const Key('box-score'),
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      children: [
        if (periodScores != null) ...[
          Text(l.matchPeriodScores, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppTokens.spaceXs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in periodScores)
                  Padding(
                    padding: const EdgeInsets.only(right: AppTokens.spaceMd),
                    child: Column(
                      children: [
                        Text(periodLabel(l, s.period, live.rules.periodCount), style: theme.textTheme.labelSmall),
                        Text('${s.team}–${s.opponent}', key: Key('period-score-${s.period}')),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.spaceMd),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: AppTokens.spaceMd,
            horizontalMargin: 0,
            headingRowHeight: 36,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 40,
            columns: [
              DataColumn(label: Text(l.navPlayers)),
              for (final c in cols) DataColumn(label: Text(c), numeric: true),
            ],
            rows: [
              for (final line in lines)
                DataRow(
                  key: ValueKey('box-${line.playerId}'),
                  cells: [
                    DataCell(Text(_name(line), overflow: TextOverflow.ellipsis)),
                    for (final v in _values(line.stats)) DataCell(Text(v)),
                  ],
                ),
              if (totals != null)
                DataRow(
                  key: const ValueKey('box-totals'),
                  cells: [
                    DataCell(Text(l.matchTotals, style: const TextStyle(fontWeight: FontWeight.bold))),
                    for (final v in _values(totals)) DataCell(Text(v, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
            ],
          ),
        ),
        if (warnings > 0 && live.rights.canRunMatch)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.spaceMd),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: theme.colorScheme.tertiary),
                const SizedBox(width: AppTokens.spaceSm),
                Expanded(child: Text(l.matchWarnings(warnings), key: const Key('box-warnings'))),
              ],
            ),
          ),
        const SizedBox(height: AppTokens.spaceMd),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('box-copy'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: shareText(l, live)));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.matchCopied)));
              }
            },
            icon: const Icon(Icons.copy),
            label: Text(l.matchCopy),
          ),
        ),
      ],
    );
  }

  String _name(PlayerLine line) {
    final p = live.player(line.playerId);
    final jersey = p?.jerseyNumber;
    return '${jersey == null ? '' : '#$jersey '}${p?.displayName ?? line.playerId}${line.wasStarter ? ' *' : ''}';
  }

  static List<String> _values(StatLine s) => [
    '${s.secondsPlayed ~/ 60}:${(s.secondsPlayed % 60).toString().padLeft(2, '0')}',
    '${s.points}',
    '${s.rebounds}',
    '${s.assists}',
    '${s.steals}',
    '${s.blocks}',
    '${s.turnovers}',
    '${s.personalFouls}',
    '${s.fgMade}/${s.fgAttempted}',
    '${s.fg3Made}/${s.fg3Attempted}',
    '${s.fg1Made}/${s.fg1Attempted}',
  ];
}

/// Plain-text result for sharing (copied to the clipboard).
String shareText(AppLocalizations l, LiveMatch live) {
  final p = live.projection;
  final team = live.team;
  final periods = team.periodScores;
  final b = StringBuffer()..writeln('${l.matchUs} ${team.teamScore} – ${team.opponentScore} ${live.match.opponentName}');
  if (periods != null) {
    b.writeln([
      for (final s in periods) '${periodLabel(l, s.period, live.rules.periodCount)} ${s.team}-${s.opponent}',
    ].join(' · '));
  }
  for (final line in p.playerStats) {
    if (!live.rights.canSeeLine(line.playerId)) continue;
    b.writeln(l.matchShareLine(
      live.player(line.playerId)?.displayName ?? line.playerId,
      line.stats.points,
      line.stats.rebounds,
      line.stats.assists,
    ));
  }
  return b.toString().trimRight();
}
