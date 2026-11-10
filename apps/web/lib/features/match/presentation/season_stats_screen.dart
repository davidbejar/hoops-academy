import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;
import 'package:intl/intl.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/export/export_menu.dart';
import '../../../core/export/export_runner.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../admin/application/admin_providers.dart';
import '../../roster/application/roster_providers.dart';
import '../../tenant/application/tenant_providers.dart';
import '../application/match_providers.dart';
import 'match_export_actions.dart';
import 'match_labels.dart';

/// Narrowest average tile: two in a row on a phone, four from tablets.
const _averageTileMinWidth = 140.0;

/// `GET /players/{id}/season-stats?seasonId=` for (player, season).
final seasonStatsProvider =
    FutureProvider.family<gen.PlayerSeasonStats, (String, String)>(
      (ref, key) =>
          ref.watch(matchesRepositoryProvider).seasonStats(key.$1, key.$2),
    );

/// A player's season statistics (route `/matches/stats/:playerId`; linked
/// from the player detail and, WP14, from Me / My players).
class SeasonStatsScreen extends ConsumerStatefulWidget {
  const SeasonStatsScreen({super.key, required this.playerId});
  final String playerId;

  @override
  ConsumerState<SeasonStatsScreen> createState() => _SeasonStatsScreenState();
}

class _SeasonStatsScreenState extends ConsumerState<SeasonStatsScreen> {
  String? _seasonId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final seasons = ref.watch(seasonsProvider).value ?? const <api.Season>[];
    final active = ref.watch(activeSeasonProvider);
    final seasonId = _seasonId ?? active.value?.id;
    return SubPage(
      title: l.seasonStatsTitle,
      parentPath: '/matches',
      actions: [
        if (seasonId != null)
          ExportMenu(
            formats: const [ExportFormat.csv, ExportFormat.xlsx],
            prepare: (ref, l) => prepareStatsExport(
              ref,
              l,
              playerId: widget.playerId,
              seasonId: seasonId,
            ),
          ),
      ],
      child: Column(
        children: [
          if (seasons.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: HoopsSpace.md),
              child: ContentFrame(
                child: DropdownButtonFormField<String>(
                  key: const Key('stats-season'),
                  initialValue: seasonId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.seasonStatsSeason),
                  items: [
                    for (final s in seasons)
                      DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  onChanged: (v) => setState(() => _seasonId = v),
                ),
              ),
            ),
          Expanded(
            child: seasonId == null
                ? AsyncBody<api.Season?>(
                    value: active,
                    onRetry: () => ref.invalidate(seasonsProvider),
                    isEmpty: (s) => s == null,
                    emptyMessage: l.seasonStatsEmpty,
                    builder: (_, _) => const SizedBox.shrink(),
                  )
                : _StatsBody(playerId: widget.playerId, seasonId: seasonId),
          ),
        ],
      ),
    );
  }
}

class _StatsBody extends ConsumerWidget {
  const _StatsBody({required this.playerId, required this.seasonId});
  final String playerId;
  final String seasonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final key = (playerId, seasonId);
    return AsyncBody<gen.PlayerSeasonStats>(
      value: ref.watch(seasonStatsProvider(key)),
      onRetry: () => ref.invalidate(seasonStatsProvider(key)),
      isEmpty: (s) => s.gamesPlayed == 0 && s.matches.isEmpty,
      emptyMessage: l.seasonStatsEmpty,
      builder: (context, s) {
        final text = Theme.of(context).textTheme;
        final locale = Localizations.localeOf(context).toLanguageTag();
        final avg = NumberFormat('0.0', locale);
        final t = s.totals;
        final zone = ref.watch(tenantZoneProvider);
        return PageBody(
          key: const Key('season-stats'),
          header: PageHeader(
            key: const Key('stats-games'),
            title: l.seasonStatsGames(s.gamesPlayed, s.gamesStarted),
          ),
          children: [
            _Section(
              title: l.seasonStatsAverages,
              child: ResponsiveGrid(
                minTileWidth: _averageTileMinWidth,
                children: [
                  StatTile(
                    key: const Key('avg-points'),
                    label: l.seasonStatsPoints,
                    value: avg.format(s.averages.points),
                  ),
                  StatTile(
                    label: l.seasonStatsRebounds,
                    value: avg.format(s.averages.rebounds),
                  ),
                  StatTile(
                    label: l.seasonStatsAssists,
                    value: avg.format(s.averages.assists),
                  ),
                  StatTile(
                    label: l.seasonStatsMinutes,
                    value: avg.format(s.averages.minutesPlayed),
                    tone: HoopsTone.neutral,
                  ),
                ],
              ),
            ),
            _Section(
              title: l.seasonStatsMatches,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: HoopsSpace.gap,
                children: [
                  for (final m in s.matches)
                    ListRow(
                      key: Key('stats-match-${m.matchId}'),
                      title: l.matchVs(m.opponentName),
                      subtitle: DateFormat.yMMMd(locale)
                          .format(zone.wall(m.scheduledAt)),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: HoopsSpace.xs,
                        children: [
                          statusChip(l, m.status),
                          Text(
                            '${m.stats.points} ${l.matchColPts}',
                            style: tabular(text.titleSmall!),
                          ),
                        ],
                      ),
                      onTap: () => context.go('/matches/${m.matchId}'),
                    ),
                ],
              ),
            ),
            SectionCard(
              title: l.seasonStatsTotals,
              child: Text(
                '${t.points} ${l.matchColPts} · ${t.offensiveRebounds + t.defensiveRebounds} ${l.matchColReb} · '
                '${t.assists} ${l.matchColAst} · ${t.steals} ${l.matchColStl} · ${t.blocks} ${l.matchColBlk} · '
                '${t.turnovers} ${l.matchColTov} · ${t.personalFouls} ${l.matchColPf}',
                key: const Key('stats-totals'),
                style: tabular(text.bodyLarge!),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A titled block of the page whose content brings its own cards.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: HoopsSpace.gap,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      child,
    ],
  );
}
