import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/live_match_controller.dart';
import '../domain/projector/projection.dart';
import 'match_labels.dart';

/// Narrowest team total tile: two in a row on a phone, four from tablets.
const _teamTileMinWidth = 120.0;

/// Height of the table's rows.
const _rowHeight = HoopsSize.minTapTarget - HoopsSpace.sm;

/// Live / final box score from the local projection (same rules as the
/// server). PARENT sees linked players' lines only, like `GET box-score`;
/// score, period scores and totals come from [LiveMatch.team] (for a filtered
/// feed the server's figures, ADR-0030; hidden while unknown offline).
class BoxScoreView extends StatelessWidget {
  const BoxScoreView({super.key, required this.live});
  final LiveMatch live;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HoopsTokens.colorsOf(context);
    final text = Theme.of(context).textTheme;
    final gutter = WidthClass.of(context).gutter;
    final p = live.projection;
    final periodScores = live.team.periodScores;
    final totals = live.team.teamTotals;
    final lines = [
      for (final line in p.playerStats)
        if (live.rights.canSeeLine(line.playerId)) line,
    ];
    final warnings =
        p.warnings.length +
        p.playerStats.fold<int>(0, (n, x) => n + x.warnings.length);
    final cols = [
      l.matchColMin,
      l.matchColPts,
      l.matchColReb,
      l.matchColAst,
      l.matchColStl,
      l.matchColBlk,
      l.matchColTov,
      l.matchColPf,
      l.matchColFg,
      l.matchCol3p,
      l.matchColFt,
    ];
    return ListView(
      key: const Key('box-score'),
      padding: EdgeInsets.symmetric(
        horizontal: gutter,
        vertical: HoopsSpace.md,
      ),
      children: [
        if (periodScores != null) ...[
          SectionCard(
            title: l.matchPeriodScores,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: HoopsSpace.lg,
                children: [
                  for (final s in periodScores)
                    Column(
                      children: [
                        Text(
                          periodLabel(l, s.period, live.rules.periodCount),
                          style: text.labelMedium!.copyWith(color: c.inkMuted),
                        ),
                        Text(
                          '${s.team}–${s.opponent}',
                          key: Key('period-score-${s.period}'),
                          style: tabular(text.titleMedium!),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: HoopsSpace.gap),
        ],
        SectionCard(
          title: l.matchTabBox,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: HoopsSpace.md,
              horizontalMargin: HoopsSpace.sm,
              headingRowHeight: _rowHeight,
              dataRowMinHeight: _rowHeight,
              dataRowMaxHeight: _rowHeight,
              columns: [
                DataColumn(label: Text(l.navPlayers)),
                for (final col in cols)
                  DataColumn(label: Text(col), numeric: true),
              ],
              rows: [
                for (final line in lines)
                  DataRow(
                    key: ValueKey('box-${line.playerId}'),
                    cells: [
                      DataCell(
                        Text(_name(line), overflow: TextOverflow.ellipsis),
                      ),
                      for (final v in _values(line.stats))
                        DataCell(Text(v, style: tabular(text.bodyMedium!))),
                    ],
                  ),
                if (totals != null)
                  DataRow(
                    key: const ValueKey('box-totals'),
                    color: WidgetStatePropertyAll(c.surfaceMuted),
                    cells: [
                      DataCell(Text(l.matchTotals, style: text.titleSmall)),
                      for (final v in _values(totals))
                        DataCell(Text(v, style: tabular(text.titleSmall!))),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (totals != null) ...[
          const SizedBox(height: HoopsSpace.gap),
          ResponsiveGrid(
            key: const Key('box-team-tiles'),
            minTileWidth: _teamTileMinWidth,
            spacing: HoopsSpace.sm,
            children: [
              StatTile(label: l.matchColPts, value: '${totals.points}'),
              StatTile(label: l.matchColReb, value: '${totals.rebounds}'),
              StatTile(label: l.matchColAst, value: '${totals.assists}'),
              StatTile(
                label: l.matchColTov,
                value: '${totals.turnovers}',
                tone: HoopsTone.neutral,
              ),
            ],
          ),
        ],
        if (warnings > 0 && live.rights.canRunMatch) ...[
          const SizedBox(height: HoopsSpace.gap),
          Row(
            children: [
              Icon(Icons.warning_amber, color: c.warning.foreground),
              const SizedBox(width: HoopsSpace.sm),
              Expanded(
                child: Text(
                  l.matchWarnings(warnings),
                  key: const Key('box-warnings'),
                  style: text.bodyMedium!.copyWith(color: c.warning.foreground),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: HoopsSpace.md),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('box-copy'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: shareText(l, live)));
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l.matchCopied)));
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
  final b = StringBuffer()
    ..writeln(
      '${l.matchUs} ${team.teamScore} – ${team.opponentScore} ${live.match.opponentName}',
    );
  if (periods != null) {
    b.writeln(
      [
        for (final s in periods)
          '${periodLabel(l, s.period, live.rules.periodCount)} ${s.team}-${s.opponent}',
      ].join(' · '),
    );
  }
  for (final line in p.playerStats) {
    if (!live.rights.canSeeLine(line.playerId)) continue;
    b.writeln(
      l.matchShareLine(
        live.player(line.playerId)?.displayName ?? line.playerId,
        line.stats.points,
        line.stats.rebounds,
        line.stats.assists,
      ),
    );
  }
  return b.toString().trimRight();
}
