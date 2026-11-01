import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/ui/async_body.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../admin/application/admin_providers.dart';
import '../../roster/application/roster_providers.dart';
import '../application/match_providers.dart';
import 'match_labels.dart';

/// `GET /players/{id}/season-stats?seasonId=` for (player, season).
final seasonStatsProvider = FutureProvider.family<gen.PlayerSeasonStats, (String, String)>(
  (ref, key) => ref.watch(matchesRepositoryProvider).seasonStats(key.$1, key.$2),
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
      child: Column(
        children: [
          if (seasons.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, AppTokens.spaceMd, AppTokens.spaceMd, 0),
              child: DropdownButtonFormField<String>(
                key: const Key('stats-season'),
                initialValue: seasonId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.seasonStatsSeason),
                items: [for (final s in seasons) DropdownMenuItem(value: s.id, child: Text(s.name))],
                onChanged: (v) => setState(() => _seasonId = v),
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
        final theme = Theme.of(context);
        final locale = Localizations.localeOf(context).toLanguageTag();
        final avg = NumberFormat('0.0', locale);
        final t = s.totals;
        return ListView(
          key: const Key('season-stats'),
          padding: const EdgeInsets.all(AppTokens.spaceMd),
          children: [
            Text(l.seasonStatsGames(s.gamesPlayed, s.gamesStarted), key: const Key('stats-games'), style: theme.textTheme.titleMedium),
            const SizedBox(height: AppTokens.spaceMd),
            Text(l.seasonStatsAverages, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.spaceXs),
            Wrap(
              spacing: AppTokens.spaceSm,
              runSpacing: AppTokens.spaceSm,
              children: [
                _Metric(key: const Key('avg-points'), label: l.seasonStatsPoints, value: avg.format(s.averages.points)),
                _Metric(label: l.seasonStatsRebounds, value: avg.format(s.averages.rebounds)),
                _Metric(label: l.seasonStatsAssists, value: avg.format(s.averages.assists)),
                _Metric(label: l.seasonStatsMinutes, value: avg.format(s.averages.minutesPlayed)),
              ],
            ),
            const SizedBox(height: AppTokens.spaceMd),
            Text(l.seasonStatsTotals, style: theme.textTheme.titleSmall),
            Text(
              '${t.points} ${l.matchColPts} · ${t.offensiveRebounds + t.defensiveRebounds} ${l.matchColReb} · '
              '${t.assists} ${l.matchColAst} · ${t.steals} ${l.matchColStl} · ${t.blocks} ${l.matchColBlk} · '
              '${t.turnovers} ${l.matchColTov} · ${t.personalFouls} ${l.matchColPf}',
              key: const Key('stats-totals'),
            ),
            const SizedBox(height: AppTokens.spaceMd),
            Text(l.seasonStatsMatches, style: theme.textTheme.titleSmall),
            for (final m in s.matches)
              ListTile(
                key: Key('stats-match-${m.matchId}'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.matchVs(m.opponentName)),
                subtitle: Text(DateFormat.yMMMd(locale).format(m.scheduledAt.toLocal())),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${m.stats.points} ${l.matchColPts}'),
                    const SizedBox(width: AppTokens.spaceSm),
                    statusChip(l, m.status),
                  ],
                ),
                onTap: () => context.go('/matches/${m.matchId}'),
              ),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 96,
    padding: const EdgeInsets.all(AppTokens.spaceSm),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
    ),
    child: Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
      ],
    ),
  );
}
