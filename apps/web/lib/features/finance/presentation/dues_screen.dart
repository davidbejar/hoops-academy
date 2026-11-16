import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/finance_lookups.dart';
import '../application/finance_providers.dart';
import '../domain/periods.dart';
import 'finance_widgets.dart';
import 'generate_dues_dialog.dart';

/// Every due of the academy, filtered by plan, team, period and state.
class DuesScreen extends ConsumerWidget {
  const DuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final dues = ref.watch(duesProvider);
    final online = financeOnline(ref);
    return SubPage(
      title: l.financeDuesTitle,
      parentPath: '/admin/finance',
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('dues-generate'),
        onPressed: online
            ? () => showDialog<bool>(
                context: context,
                builder: (_) => const GenerateDuesDialog(),
              )
            : null,
        icon: const Icon(Icons.playlist_add),
        label: Text(l.financeGenerateTitle),
      ),
      child: PageBody(
        header: PageHeader(title: l.financeDuesTitle),
        children: [
          const FinanceOfflineNote(),
          const _Filters(),
          FinanceBody<fin.DuePage>(
            value: dues,
            needs: [ref.watch(financeSettingsProvider)],
            onRetry: () {
              ref.invalidate(duesProvider);
              ref.invalidate(financeSettingsProvider);
            },
            isEmpty: (page) => page.items.isEmpty,
            emptyMessage: l.financeDuesEmpty,
            builder: (context, page) => _DueList(page: page),
          ),
        ],
      ),
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final query = ref.watch(dueQueryProvider);
    final notifier = ref.read(dueQueryProvider.notifier);
    final plans = ref.watch(feePlansProvider).value ?? const <fin.FeePlan>[];
    final lookups = ref.watch(financeLookupsProvider).value;
    final locale = localeOf(context);
    final compact = WidthClass.of(context).isCompact;

    // The periods to pick from: those of the chosen plan, else of every plan.
    final periodKeys = <String>{};
    for (final plan in plans) {
      if (query.planId != null && plan.id != query.planId) continue;
      final season = lookups?.season(plan.seasonId);
      if (season == null) continue;
      periodKeys.addAll(
        planPeriodKeys(
          cadence: plan.cadence,
          firstPeriod: plan.firstPeriod,
          lastPeriod: plan.lastPeriod,
          seasonStart: season.startsOn.toDateTime(),
          seasonEnd: season.endsOn.toDateTime(),
        ),
      );
    }
    final periods = periodKeys.toList()
      ..sort((a, b) => Period.tryParse(a)!.compareTo(Period.tryParse(b)!));

    DropdownMenuItem<String?> all() =>
        DropdownMenuItem<String?>(value: null, child: Text(l.all));

    final planField = DropdownButtonFormField<String?>(
      key: const Key('dues-filter-plan'),
      initialValue: query.planId,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.financeFilterPlan),
      items: [
        all(),
        for (final p in plans)
          DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
      ],
      onChanged: (v) => notifier.filter(planId: v, period: null),
    );
    final teamField = DropdownButtonFormField<String?>(
      key: const Key('dues-filter-team'),
      initialValue: query.teamId,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.financeFilterTeam),
      items: [
        all(),
        for (final t in lookups?.teams ?? const <api.Team>[])
          DropdownMenuItem<String?>(value: t.id, child: Text(t.name)),
      ],
      onChanged: (v) => notifier.filter(teamId: v),
    );
    final periodField = KeyedSubtree(
      key: ValueKey('period-of-${query.planId}'),
      child: DropdownButtonFormField<String?>(
        key: const Key('dues-filter-period'),
        initialValue: query.period,
        isExpanded: true,
        decoration: InputDecoration(labelText: l.financeFilterPeriod),
        items: [
          all(),
          for (final key in periods)
            DropdownMenuItem<String?>(
              value: key,
              child: Text(periodLabel(key, l, locale)),
            ),
        ],
        onChanged: (v) => notifier.filter(period: v),
      ),
    );
    final chips = [
      ChoiceChip(
        key: const Key('dues-status-ALL'),
        label: Text(l.all),
        selected: query.status == null,
        onSelected: (_) => notifier.filter(status: null),
      ),
      for (final status in const [
        fin.DueStatus.OPEN,
        fin.DueStatus.PAID,
        fin.DueStatus.WAIVED,
      ])
        ChoiceChip(
          key: Key('dues-status-${status.name}'),
          label: Text(status.label(l)),
          selected: query.status == status,
          onSelected: (_) => notifier.filter(status: status),
        ),
    ];
    // On a phone the filters stay short so the list starts on the first screen:
    // the plan, then team and period side by side, the states in one row.
    return compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: HoopsSpace.sm,
            children: [
              planField,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: HoopsSpace.sm,
                children: [
                  Expanded(child: teamField),
                  Expanded(child: periodField),
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(spacing: HoopsSpace.sm, children: chips),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: HoopsSpace.gap,
            children: [
              Wrap(
                spacing: HoopsSpace.gap,
                runSpacing: HoopsSpace.gap,
                children: [
                  for (final field in [planField, teamField, periodField])
                    SizedBox(width: 240, child: field),
                ],
              ),
              Wrap(
                spacing: HoopsSpace.sm,
                runSpacing: HoopsSpace.sm,
                children: chips,
              ),
            ],
          );
  }
}

class _DueList extends ConsumerWidget {
  const _DueList({required this.page});

  final fin.DuePage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final locale = localeOf(context);
    final text = Theme.of(context).textTheme;
    final meta = page.page;
    final notifier = ref.read(dueQueryProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: HoopsSpace.gap,
      children: [
        Text(
          l.financeDuesCount(meta.totalElements),
          key: const Key('dues-count'),
          style: text.titleSmall,
        ),
        for (final due in page.items)
          ListRow(
            key: Key('due-${due.id}'),
            title: due.playerName,
            subtitle:
                '${due.feePlanName} · ${periodLabel(due.period, l, locale)}',
            details: DueStatusChip(due.status),
            trailing: Text(
              money?.format(due.amountMinor) ?? '${due.amountMinor}',
              style: text.titleMedium,
            ),
            onTap: () => context.go('/admin/finance/dues/${due.id}'),
          ),
        if (meta.totalPages > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('dues-previous'),
                tooltip: l.financePagePrevious,
                icon: const Icon(Icons.chevron_left),
                onPressed: meta.page > 0
                    ? () => notifier.goToPage(meta.page - 1)
                    : null,
              ),
              Text(l.financePageOf(meta.page + 1, meta.totalPages)),
              IconButton(
                key: const Key('dues-next'),
                tooltip: l.financePageNext,
                icon: const Icon(Icons.chevron_right),
                onPressed: meta.page + 1 < meta.totalPages
                    ? () => notifier.goToPage(meta.page + 1)
                    : null,
              ),
            ],
          ),
        const SizedBox(height: HoopsSize.appBar),
      ],
    );
  }
}
