import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../../core/time/dates.dart';
import '../../../core/ui/chart_tokens.dart';
import '../../../core/ui/kit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/finance_lookups.dart';
import '../application/finance_providers.dart';
import 'finance_widgets.dart';

/// A season's balance (ADMIN): what the dues brought in by state, what was
/// spent by category, and the result.
class BalanceScreen extends ConsumerStatefulWidget {
  const BalanceScreen({super.key});

  @override
  ConsumerState<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends ConsumerState<BalanceScreen> {
  String? _seasonId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lookups = ref.watch(financeLookupsProvider);
    final settings = ref.watch(financeSettingsProvider);
    return SubPage(
      title: l.financeBalanceTitle,
      parentPath: '/admin/finance',
      child: PageBody(
        header: PageHeader(title: l.financeBalanceTitle),
        children: [
          FinanceBody<FinanceLookups>(
            value: lookups,
            needs: [settings],
            onRetry: () {
              ref.invalidate(financeLookupsProvider);
              ref.invalidate(financeSettingsProvider);
            },
            isEmpty: (data) => data.seasons.isEmpty,
            emptyMessage: l.financeBalanceNoSeasons,
            builder: (context, data) {
              final season = data.season(_seasonId) ?? data.defaultSeason!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: HoopsSpace.gap,
                children: [
                  DropdownButtonFormField<String>(
                    key: const Key('balance-season'),
                    initialValue: season.id,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l.financeBalanceSeason,
                    ),
                    items: [
                      for (final s in data.seasons)
                        DropdownMenuItem(value: s.id, child: Text(s.name)),
                    ],
                    onChanged: (v) => setState(() => _seasonId = v),
                  ),
                  _BalanceView(seasonId: season.id),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BalanceView extends ConsumerWidget {
  const _BalanceView({required this.seasonId});

  final String seasonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(seasonBalanceProvider(seasonId));
    return FinanceBody<fin.SeasonBalance>(
      value: balance,
      needs: [ref.watch(financeSettingsProvider)],
      onRetry: () {
        ref.invalidate(seasonBalanceProvider(seasonId));
        ref.invalidate(financeSettingsProvider);
      },
      builder: (context, data) => _Figures(balance: data),
    );
  }
}

class _Figures extends ConsumerWidget {
  const _Figures({required this.balance});

  final fin.SeasonBalance balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final locale = localeOf(context);
    String show(int minor) => money?.format(minor) ?? '$minor';
    String day(DateTime d) => displayDate(locale, d);
    final net = balance.netMinor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: HoopsSpace.gap,
      children: [
        Text(
          l.financeBalanceRange(
            day(balance.from.toDateTime()),
            day(balance.to.toDateTime()),
          ),
          key: const Key('balance-range'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        ResponsiveGrid(
          minTileWidth: 150,
          children: [
            StatTile(
              key: const Key('balance-paid'),
              icon: Icons.payments_outlined,
              tone: HoopsTone.success,
              label: l.financeBalancePaid,
              value: show(balance.income.paidMinor),
            ),
            StatTile(
              key: const Key('balance-open'),
              icon: Icons.hourglass_empty,
              tone: HoopsTone.warning,
              label: l.financeBalanceOpen,
              value: show(balance.income.openMinor),
            ),
            StatTile(
              key: const Key('balance-waived'),
              icon: Icons.volunteer_activism_outlined,
              tone: HoopsTone.neutral,
              label: l.financeBalanceWaived,
              value: show(balance.income.waivedMinor),
            ),
            StatTile(
              key: const Key('balance-expenses'),
              icon: Icons.shopping_bag_outlined,
              tone: HoopsTone.info,
              label: l.financeBalanceExpenses,
              value: show(balance.expenses.totalMinor),
            ),
          ],
        ),
        StatTile(
          key: const Key('balance-net'),
          icon: net < 0 ? Icons.trending_down : Icons.trending_up,
          tone: net < 0 ? HoopsTone.danger : HoopsTone.success,
          label: l.financeBalanceNet,
          value: show(net),
        ),
        ChartCard(
          key: const Key('balance-chart'),
          title: l.financeBalanceChartTitle,
          semantics: l.financeBalanceChartSummary(
            show(balance.expenses.totalMinor),
          ),
          chart: balance.expenses.totalMinor == 0
              ? Center(child: Text(l.financeBalanceNoExpenses))
              : _CategoryBars(
                  totals: balance.expenses.byCategory.toList(),
                  show: show,
                ),
        ),
      ],
    );
  }
}

/// One horizontal bar per category, as long as its share of the largest.
/// Single series, so one colour; the amounts are written next to the bars.
class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.totals, required this.show});

  final List<fin.CategoryTotal> totals;
  final String Function(int minor) show;

  static const _labelWidth = 104.0;
  static const _valueWidth = 72.0;
  static const _barHeight = 14.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = ChartPalette.of(context);
    final largest = totals.fold<int>(
      0,
      (m, t) => t.totalMinor > m ? t.totalMinor : m,
    );
    final style = TextStyle(color: p.inkSecondary, fontSize: 12);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final t in totals)
          Row(
            key: Key('balance-bar-${t.category.name}'),
            children: [
              SizedBox(
                width: _labelWidth,
                child: Text(
                  t.category.label(l),
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: largest == 0
                          ? 0
                          : box.maxWidth * t.totalMinor / largest,
                      height: _barHeight,
                      decoration: BoxDecoration(
                        color: p.series,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: _valueWidth,
                child: Text(
                  show(t.totalMinor),
                  style: style.copyWith(color: p.ink),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
