import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/export/server_csv_export.dart';
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../platform/application/platform_providers.dart'
    show isSuperAdminProvider, tenantDetailProvider;
import '../application/audit_providers.dart';
import '../domain/audit_entry.dart';
import 'audit_labels.dart';

/// The academy's activity (audit trail) in the admin area: ADMIN only, like the hub that links to it.
class AcademyActivityScreen extends StatelessWidget {
  const AcademyActivityScreen({super.key});

  @override
  Widget build(BuildContext context) => SubPage(
    title: AppLocalizations.of(context).auditTitle,
    parentPath: '/admin',
    child: const AuditLogView(scope: AuditScope.academy()),
  );
}

/// The platform console's activity: every academy, or one ([tenantId]) when opened from its detail page.
class PlatformActivityScreen extends ConsumerWidget {
  const PlatformActivityScreen({super.key, this.tenantId});
  final String? tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tenantName = tenantId == null
        ? null
        : ref.watch(tenantDetailProvider(tenantId!)).value?.tenant.name;
    return SubPage(
      title: tenantName == null
          ? l.auditTitle
          : '${l.auditTitle} · $tenantName',
      parentPath: tenantId == null
          ? '/app-admin'
          : '/app-admin/academies/$tenantId',
      child: Guarded(
        allowed: ref.watch(isSuperAdminProvider),
        child: AuditLogView(
          scope: AuditScope.platform(tenantId),
          showTenant: tenantId == null,
        ),
      ),
    );
  }
}

/// Filters (date range, actions), the page of entries and the pager of one [scope].
class AuditLogView extends ConsumerWidget {
  const AuditLogView({super.key, required this.scope, this.showTenant = false});
  final AuditScope scope;
  final bool showTenant;

  /// The server's CSV of everything the screen's filters select (not just the page on screen).
  Future<Uint8List> _export(WidgetRef ref, String language) {
    final query = ref.read(auditQueryProvider(scope));
    final repo = ref.read(auditRepositoryProvider);
    return scope.platform
        ? repo.exportPlatform(
            query,
            tenantId: scope.tenantId,
            language: language,
          )
        : repo.exportAcademy(
            ref.read(api.tenantIdProvider),
            query,
            language: language,
          );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final query = ref.watch(auditQueryProvider(scope));
    final notifier = ref.read(auditQueryProvider(scope).notifier);
    final page = ref.watch(auditPageProvider(scope));
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      key: const Key('audit-log'),
      children: [
        ContentFrame(
          child: Padding(
            padding: const EdgeInsets.only(top: HoopsSpace.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: HoopsSpace.sm,
                runSpacing: HoopsSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    key: const Key('audit-range'),
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      query.hasRange ? _range(query, locale) : l.auditAnyTime,
                    ),
                    onPressed: () => _pickRange(context, query, notifier),
                  ),
                  if (query.hasRange)
                    IconButton(
                      key: const Key('audit-range-clear'),
                      tooltip: l.auditClearRange,
                      icon: const Icon(Icons.close),
                      onPressed: notifier.clearRange,
                    ),
                  OutlinedButton.icon(
                    key: const Key('audit-actions'),
                    icon: const Icon(Icons.filter_list),
                    label: Text(
                      query.actions.isEmpty
                          ? l.auditAllActions
                          : l.auditSelectedActions(query.actions.length),
                    ),
                    onPressed: () async {
                      final picked = await showDialog<Set<api.AuditAction>>(
                        context: context,
                        builder: (_) =>
                            AuditActionFilterDialog(selected: query.actions),
                      );
                      if (picked != null) notifier.setActions(picked);
                    },
                  ),
                  ServerCsvExportButton(
                    key: const Key('audit-export'),
                    what: 'audit',
                    slug: scope.platform ? 'platform' : null,
                    tooltip: l.exportAuditTooltip,
                    fetch: (language) => _export(ref, language),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: AsyncBody<AuditPage>(
            value: page,
            onRetry: () => ref.invalidate(auditPageProvider(scope)),
            isEmpty: (p) => p.items.isEmpty && p.page == 0,
            emptyMessage: l.auditEmpty,
            builder: (context, p) => Column(
              children: [
                Expanded(
                  child: PageBody(
                    children: [
                      Column(
                        spacing: HoopsSpace.gap,
                        children: [
                          for (final e in p.items)
                            AuditEntryTile(entry: e, showTenant: showTenant),
                        ],
                      ),
                    ],
                  ),
                ),
                _Pager(
                  page: p,
                  onPrevious: notifier.previousPage,
                  onNext: notifier.nextPage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _range(AuditQuery q, String locale) {
    final f = DateFormat.yMMMd(locale);
    return '${f.format(q.fromDay!)} – ${f.format(q.toDay!)}';
  }

  static Future<void> _pickRange(
    BuildContext context,
    AuditQuery query,
    AuditQueryNotifier notifier,
  ) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: query.hasRange
          ? DateTimeRange(start: query.fromDay!, end: query.toDay!)
          : null,
    );
    if (picked != null) notifier.setRange(picked.start, picked.end);
  }
}

/// One entry: the localized action, what it was about, who did it and when (and the academy on the platform list).
class AuditEntryTile extends StatelessWidget {
  const AuditEntryTile({
    super.key,
    required this.entry,
    this.showTenant = false,
  });
  final AuditEntry entry;
  final bool showTenant;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final when = DateFormat.yMMMd(locale).add_Hm().format(entry.at.toLocal());
    final actor = entry.actorName ?? entry.actorKind.label(l);
    final target = entry.targetName ?? entry.targetType.label(l);
    return ListRow(
      key: Key('audit-${entry.id}'),
      leading: IconTile(_icon(entry.targetType)),
      title: entry.action.label(l),
      subtitle: [
        if (showTenant && entry.tenantName != null) entry.tenantName!,
        target,
        '${l.auditByActor(actor)} · $when',
      ].join('\n'),
    );
  }

  static IconData _icon(api.AuditTargetType type) => switch (type) {
    api.AuditTargetType.player => Icons.sports_basketball_outlined,
    api.AuditTargetType.tenant => Icons.business_outlined,
    api.AuditTargetType.approvalRequest => Icons.how_to_reg_outlined,
    api.AuditTargetType.guardianLink => Icons.family_restroom_outlined,
    api.AuditTargetType.team => Icons.groups_outlined,
    _ => Icons.person_outline,
  };
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });
  final AuditPage page;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HoopsSpace.md,
        vertical: HoopsSpace.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: const Key('audit-prev'),
            tooltip: l.auditPreviousPage,
            icon: const Icon(Icons.chevron_left),
            onPressed: page.hasPrevious ? onPrevious : null,
          ),
          Text(
            l.auditPageOf(
              page.page + 1,
              page.totalPages < 1 ? 1 : page.totalPages,
            ),
          ),
          IconButton(
            key: const Key('audit-next'),
            tooltip: l.auditNextPage,
            icon: const Icon(Icons.chevron_right),
            onPressed: page.hasNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

/// Picks one or several actions (none = every action).
class AuditActionFilterDialog extends StatefulWidget {
  const AuditActionFilterDialog({super.key, required this.selected});
  final Set<api.AuditAction> selected;

  @override
  State<AuditActionFilterDialog> createState() =>
      _AuditActionFilterDialogState();
}

class _AuditActionFilterDialogState extends State<AuditActionFilterDialog> {
  late final Set<api.AuditAction> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final actions = [...auditActions]
      ..sort((a, b) => a.label(l).compareTo(b.label(l)));
    return AlertDialog(
      title: Text(l.auditFilterTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in actions)
                CheckboxListTile(
                  key: Key('audit-action-${auditWireName(a)}'),
                  dense: true,
                  title: Text(a.label(l)),
                  value: _selected.contains(a),
                  onChanged: (on) => setState(
                    () => on == true ? _selected.add(a) : _selected.remove(a),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('audit-actions-clear'),
          onPressed: () => Navigator.of(context).pop(<api.AuditAction>{}),
          child: Text(l.auditAllActions),
        ),
        FilledButton(
          key: const Key('audit-actions-apply'),
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l.auditApply),
        ),
      ],
    );
  }
}
