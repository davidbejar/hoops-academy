import 'package:material_ui/material_ui.dart';

import '../design/tokens.dart';
import 'chart_tokens.dart';

/// The card every chart sits in: a [title], the [chart] on a fixed-height plot
/// (hidden from the screen reader, which gets [semantics] instead), an
/// optional [legend] under it and an optional [table] of the exact values.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.semantics,
    required this.chart,
    this.legend,
    this.table,
  });

  /// Height of the plot area, in logical pixels (dataviz spec of WP14).
  static const plotHeight = 180.0;

  final String title;
  final String semantics;
  final Widget chart;
  final Widget? legend;
  final Widget? table;

  @override
  Widget build(BuildContext context) {
    final p = ChartPalette.of(context);
    return Card(
      color: p.surface,
      child: Padding(
        padding: const EdgeInsets.all(HoopsSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: p.ink),
            ),
            const SizedBox(height: HoopsSpace.sm),
            Semantics(
              label: semantics,
              child: ExcludeSemantics(
                child: SizedBox(height: plotHeight, child: chart),
              ),
            ),
            if (legend != null) ...[
              const SizedBox(height: HoopsSpace.sm),
              legend!,
            ],
            ?table,
          ],
        ),
      ),
    );
  }
}
