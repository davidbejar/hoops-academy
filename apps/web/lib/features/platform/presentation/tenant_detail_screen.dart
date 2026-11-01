import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api/api.dart' as api;
import '../../../core/errors/app_error.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/chart_tokens.dart';
import '../../../core/ui/page_scaffold.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/platform_providers.dart';
import 'platform_screen.dart' show TenantStatusChip;

String _date(DateTime d) {
  final t = d.toLocal();
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}

/// Tenant detail: lifecycle actions and the usage dashboard.
class TenantDetailScreen extends ConsumerWidget {
  const TenantDetailScreen({super.key, required this.tenantId});
  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final detail = ref.watch(tenantDetailProvider(tenantId));
    return SubPage(
      title: detail.value?.tenant.name ?? l.platformTitle,
      parentPath: '/platform',
      child: Guarded(
        allowed: ref.watch(isSuperAdminProvider),
        child: AsyncBody<TenantDetail>(
          value: detail,
          onRetry: () => ref.invalidate(tenantDetailProvider(tenantId)),
          builder: (context, d) => ListView(
            padding: const EdgeInsets.all(AppTokens.spaceMd),
            children: [_Header(detail: d), const SizedBox(height: AppTokens.spaceMd), UsageDashboard(detail: d)],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.detail});
  final TenantDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = detail.tenant;
    final notifier = ref.read(tenantDetailProvider(t.id).notifier);
    Future<void> lifecycle(String title, String? warning, Future<void> Function(String) action) async {
      final reason = await noteDialog(context, title: title, confirmLabel: title, required: true, label: warning == null ? l.tenantReason : '${l.tenantReason} · $warning');
      if (reason == null || !context.mounted) return;
      await runAction(context, () => action(reason), success: l.tenantUpdated);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(t.slug, style: Theme.of(context).textTheme.titleMedium)),
                TenantStatusChip(t.status),
              ],
            ),
            const SizedBox(height: AppTokens.spaceXs),
            Text('${t.timezone} · ${t.defaultLocale.name}'),
            Text(l.tenantCreatedOn(_date(t.createdAt))),
            if (t.retainUntil != null)
              Text(l.tenantRetainUntil('${t.retainUntil!.year}-${t.retainUntil!.month.toString().padLeft(2, '0')}-${t.retainUntil!.day.toString().padLeft(2, '0')}')),
            const SizedBox(height: AppTokens.spaceSm),
            Wrap(
              spacing: AppTokens.spaceSm,
              children: [
                if (t.status == api.TenantStatus.ACTIVE)
                  OutlinedButton(
                    key: const Key('tenant-suspend'),
                    onPressed: () => lifecycle(l.tenantSuspend, null, notifier.suspend),
                    child: Text(l.tenantSuspend),
                  ),
                if (t.status == api.TenantStatus.SUSPENDED)
                  FilledButton(
                    key: const Key('tenant-reactivate'),
                    onPressed: () async {
                      if (!await confirmDialog(context, message: l.tenantReactivate, confirmLabel: l.tenantReactivate)) return;
                      if (!context.mounted) return;
                      await runAction(context, notifier.reactivate, success: l.tenantUpdated);
                    },
                    child: Text(l.tenantReactivate),
                  ),
                if (t.status != api.TenantStatus.WITHDRAWN)
                  OutlinedButton(
                    key: const Key('tenant-withdraw'),
                    onPressed: () => lifecycle(l.tenantWithdraw, l.tenantWithdrawWarning, notifier.withdraw),
                    child: Text(l.tenantWithdraw),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _counterLabel(AppLocalizations l, String key) => switch (key) {
  'members' => l.usageCounter_members,
  'players' => l.usageCounter_players,
  'activePlayers' => l.usageCounter_activePlayers,
  'teams' => l.usageCounter_teams,
  'seasons' => l.usageCounter_seasons,
  'matches' => l.usageCounter_matches,
  'liveMatches' => l.usageCounter_liveMatches,
  'matchEvents' => l.usageCounter_matchEvents,
  'matchEventsLast30Days' => l.usageCounter_matchEventsLast30Days,
  'trainingSessions' => l.usageCounter_trainingSessions,
  'attendanceRecords' => l.usageCounter_attendanceRecords,
  'trainingPlans' => l.usageCounter_trainingPlans,
  'physicalTestResults' => l.usageCounter_physicalTestResults,
  'injuries' => l.usageCounter_injuries,
  'bodyMeasurements' => l.usageCounter_bodyMeasurements,
  _ => key, // counters are additive: unknown keys show as they come
};

String _serviceLabel(AppLocalizations l, String name) => switch (name) {
  'core' => l.usageServiceCore,
  'game' => l.usageServiceGame,
  'athlete' => l.usageServiceAthlete,
  _ => name,
};

/// Usage counters per service as stat tiles with single-hue horizontal bars
/// (scaled within each service), plus the "service unavailable" notice.
class UsageDashboard extends StatelessWidget {
  const UsageDashboard({super.key, required this.detail});
  final TenantDetail detail;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = ChartPalette.of(context);
    final usage = detail.usage;
    return Column(
      key: const Key('usage-dashboard'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.usageTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTokens.spaceSm),
        if (usage == null)
          Text(
            detail.usageError == null ? l.usageFailed : '${l.usageFailed} · ${AppError.of(detail.usageError!).message(l)}',
            key: const Key('usage-failed'),
          )
        else ...[
          if (usage.unavailableServices.isNotEmpty)
            Card(
              key: const Key('usage-unavailable'),
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.spaceMd),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onTertiaryContainer),
                    const SizedBox(width: AppTokens.spaceSm),
                    Expanded(
                      child: Text(
                        l.usageUnavailable(usage.unavailableServices.map((s) => _serviceLabel(l, s.name)).join(', ')),
                        style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          for (final r in usage.services) _ServiceCard(report: r, palette: p),
        ],
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.report, required this.palette});
  final api.UsageReport report;
  final ChartPalette palette;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entries = report.counters.entries.toList();
    final max = entries.fold<int>(1, (m, e) => e.value > m ? e.value : m);
    return Card(
      key: Key('usage-${report.service.name}'),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_serviceLabel(l, report.service.name), style: theme.textTheme.titleSmall),
            if (report.lastActivityAt != null) Text(l.usageLastActivity(_date(report.lastActivityAt!)), style: theme.textTheme.bodySmall),
            const SizedBox(height: AppTokens.spaceSm),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.spaceSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(_counterLabel(l, e.key), style: theme.textTheme.bodyMedium)),
                        Text('${e.value}', key: Key('counter-${e.key}'), style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LayoutBuilder(
                      builder: (context, c) => Stack(
                        children: [
                          Container(height: 8, width: c.maxWidth, decoration: BoxDecoration(color: palette.grid, borderRadius: BorderRadius.circular(4))),
                          Container(
                            height: 8,
                            width: c.maxWidth * (e.value / max),
                            decoration: BoxDecoration(color: palette.series, borderRadius: BorderRadius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
