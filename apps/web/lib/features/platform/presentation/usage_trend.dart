import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/ui/async_body.dart';
import '../../../core/ui/kit.dart' show HoopsSpace;
import '../../../l10n/gen/app_localizations.dart';
import '../../health/presentation/charts.dart' show ChartPoint, GrowthChart;
import '../application/platform_providers.dart';
import 'tenant_detail_screen.dart' show usageCounterLabel;

/// The value of counter [key] in a daily snapshot (first service that reports it).
int? counterIn(api.TenantUsageSnapshot s, String key) {
  for (final report in s.services) {
    final v = report.counters[key];
    if (v != null) return v;
  }
  return null;
}

/// Counter keys present in any snapshot, in first-seen order.
List<String> counterKeys(Iterable<api.TenantUsageSnapshot> snapshots) {
  final keys = <String>{};
  for (final s in snapshots) {
    for (final report in s.services) {
      keys.addAll(report.counters.keys);
    }
  }
  return keys.toList();
}

/// Line chart of one usage counter over the daily snapshots, with a counter
/// picker and loading / empty / error states.
class UsageTrend extends ConsumerStatefulWidget {
  const UsageTrend({super.key, required this.tenantId});
  final String tenantId;

  @override
  ConsumerState<UsageTrend> createState() => _UsageTrendState();
}

class _UsageTrendState extends ConsumerState<UsageTrend> {
  String? _counter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final history = ref.watch(tenantUsageHistoryProvider(widget.tenantId));
    return Column(
      key: const Key('usage-trend'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.usageTrendTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: HoopsSpace.sm),
        history.when(
          data: (h) => _body(context, l, h.snapshots.toList()),
          loading: () => const SizedBox(
            key: Key('usage-trend-loading'),
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            key: const Key('usage-trend-error'),
            height: 300,
            child: AsyncBody<void>(
              value: AsyncError<void>(e, StackTrace.empty),
              builder: (_, _) => const SizedBox.shrink(),
              onRetry: () =>
                  ref.invalidate(tenantUsageHistoryProvider(widget.tenantId)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l,
    List<api.TenantUsageSnapshot> snapshots,
  ) {
    final keys = counterKeys(snapshots);
    if (keys.isEmpty) {
      return Text(l.usageTrendEmpty, key: const Key('usage-trend-empty'));
    }
    final selected = keys.contains(_counter)
        ? _counter!
        : (keys.contains('players') ? 'players' : keys.first);
    final points = [
      for (final s in snapshots)
        if (counterIn(s, selected) case final v?)
          ChartPoint(s.collectedAt.toUtc(), v.toDouble()),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          key: const Key('usage-trend-counter'),
          value: selected,
          isExpanded: true,
          items: [
            for (final k in keys)
              DropdownMenuItem(value: k, child: Text(usageCounterLabel(l, k))),
          ],
          onChanged: (v) => setState(() => _counter = v),
        ),
        GrowthChart(title: usageCounterLabel(l, selected), points: points),
      ],
    );
  }
}
