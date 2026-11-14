import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/errors/app_error.dart';
import '../../../core/ui/actions.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/chart_tokens.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/platform_providers.dart';
import 'platform_screen.dart' show TenantStatusChip;
import 'tenant_admins_section.dart';
import 'usage_trend.dart';

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
      title: detail.value?.tenant.name ?? l.appAdminAcademies,
      parentPath: '/app-admin/academies',
      actions: [
        IconButton(
          key: const Key('tenant-activity'),
          tooltip: l.auditTitle,
          icon: const Icon(Icons.history),
          onPressed: () =>
              context.go('/app-admin/academies/$tenantId/activity'),
        ),
      ],
      child: Guarded(
        allowed: ref.watch(isSuperAdminProvider),
        child: AsyncBody<TenantDetail>(
          value: detail,
          onRetry: () => ref.invalidate(tenantDetailProvider(tenantId)),
          builder: (context, d) => PageBody(
            children: [
              _Header(detail: d),
              TenantAdminsSection(tenant: d.tenant),
              UsageDashboard(detail: d),
              UsageTrend(tenantId: d.tenant.id),
            ],
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
    Future<void> lifecycle(
      String title,
      String? warning,
      Future<void> Function(String) action,
    ) async {
      final reason = await noteDialog(
        context,
        title: title,
        confirmLabel: title,
        required: true,
        label: warning == null
            ? l.tenantReason
            : '${l.tenantReason} · $warning',
      );
      if (reason == null || !context.mounted) return;
      await runAction(context, () => action(reason), success: l.tenantUpdated);
    }

    return SectionCard(
      title: t.slug,
      actions: [TenantStatusChip(t.status)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: HoopsSpace.xs,
        children: [
          Text('${t.timezone} · ${t.defaultLocale.name}'),
          Text(l.tenantCreatedOn(_date(t.createdAt))),
          if (t.retainUntil != null)
            Text(
              l.tenantRetainUntil(
                '${t.retainUntil!.year}-${t.retainUntil!.month.toString().padLeft(2, '0')}-${t.retainUntil!.day.toString().padLeft(2, '0')}',
              ),
            ),
          const SizedBox(height: HoopsSpace.sm),
          Wrap(
            spacing: HoopsSpace.sm,
            children: [
              if (t.status == api.TenantStatus.ACTIVE)
                OutlinedButton(
                  key: const Key('tenant-suspend'),
                  onPressed: () =>
                      lifecycle(l.tenantSuspend, null, notifier.suspend),
                  child: Text(l.tenantSuspend),
                ),
              if (t.status == api.TenantStatus.SUSPENDED)
                FilledButton(
                  key: const Key('tenant-reactivate'),
                  onPressed: () async {
                    if (!await confirmDialog(
                      context,
                      message: l.tenantReactivate,
                      confirmLabel: l.tenantReactivate,
                    )) {
                      return;
                    }
                    if (!context.mounted) return;
                    await runAction(
                      context,
                      notifier.reactivate,
                      success: l.tenantUpdated,
                    );
                  },
                  child: Text(l.tenantReactivate),
                ),
              if (t.status != api.TenantStatus.WITHDRAWN)
                OutlinedButton(
                  key: const Key('tenant-withdraw'),
                  onPressed: () => lifecycle(
                    l.tenantWithdraw,
                    l.tenantWithdrawWarning,
                    notifier.withdraw,
                  ),
                  child: Text(l.tenantWithdraw),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String usageCounterLabel(AppLocalizations l, String key) => switch (key) {
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
  'trainingSchedules' => l.usageCounter_trainingSchedules,
  'finishedMatches' => l.usageCounter_finishedMatches,
  'membersAdmin' => l.usageCounter_membersAdmin,
  'membersCoach' => l.usageCounter_membersCoach,
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
    final text = Theme.of(context).textTheme;
    final p = ChartPalette.of(context);
    final usage = detail.usage;
    return Column(
      key: const Key('usage-dashboard'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: HoopsSpace.gap,
      children: [
        Text(l.usageTitle, style: text.titleLarge),
        if (usage == null)
          Text(
            detail.usageError == null
                ? l.usageFailed
                : '${l.usageFailed} · ${AppError.of(detail.usageError!).message(l)}',
            key: const Key('usage-failed'),
          )
        else ...[
          if (usage.unavailableServices.isNotEmpty)
            ClipRRect(
              key: const Key('usage-unavailable'),
              borderRadius: BorderRadius.circular(HoopsRadius.md),
              child: NoticeBanner(
                tone: HoopsTone.warning,
                icon: Icons.warning_amber_rounded,
                message: l.usageUnavailable(
                  usage.unavailableServices
                      .map((s) => _serviceLabel(l, s.name))
                      .join(', '),
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
    final text = Theme.of(context).textTheme;
    final c = HoopsTokens.colorsOf(context);
    final entries = report.counters.entries.toList();
    final max = entries.fold<int>(1, (m, e) => e.value > m ? e.value : m);
    return SectionCard(
      key: Key('usage-${report.service.name}'),
      title: _serviceLabel(l, report.service.name),
      subtitle: report.lastActivityAt == null
          ? null
          : l.usageLastActivity(_date(report.lastActivityAt!)),
      child: Column(
        spacing: HoopsSpace.gap,
        children: [
          for (final e in entries)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: HoopsSpace.xs,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        usageCounterLabel(l, e.key),
                        style: text.bodyLarge,
                      ),
                    ),
                    Text(
                      '${e.value}',
                      key: Key('counter-${e.key}'),
                      style: text.titleMedium,
                    ),
                  ],
                ),
                LayoutBuilder(
                  builder: (context, box) => Stack(
                    children: [
                      Container(
                        height: HoopsSpace.sm,
                        width: box.maxWidth,
                        decoration: BoxDecoration(
                          color: c.surfaceMuted,
                          borderRadius: BorderRadius.circular(HoopsSpace.xs),
                        ),
                      ),
                      Container(
                        height: HoopsSpace.sm,
                        width: box.maxWidth * (e.value / max),
                        decoration: BoxDecoration(
                          color: palette.series,
                          borderRadius: BorderRadius.circular(HoopsSpace.xs),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
