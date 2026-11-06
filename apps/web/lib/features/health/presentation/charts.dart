import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/api/athlete_api.dart' as ath;
import '../../../core/ui/chart_tokens.dart';
import '../../../core/ui/labels.dart' show formatAthDate;
import '../../../l10n/gen/app_localizations.dart';
import 'health_labels.dart';

/// One plotted value.
class ChartPoint {
  const ChartPoint(this.at, this.value, {this.band, this.pending = false});
  final DateTime at;
  final double value;
  final ath.NormBand? band;
  final bool pending;
}

double _days(DateTime d) =>
    d.millisecondsSinceEpoch / Duration.millisecondsPerDay;
DateTime _fromDays(double v) => DateTime.fromMillisecondsSinceEpoch(
  (v * Duration.millisecondsPerDay).round(),
  isUtc: true,
);

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String _shortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${(d.year % 100).toString().padLeft(2, '0')}';

/// Shared line-chart body: thin 2 px line, >= 8 px markers with a 2 px
/// surface ring, recessive grid, ink-coloured axis text.
class _Line extends StatelessWidget {
  const _Line({
    required this.points,
    required this.palette,
    required this.markerColor,
    required this.lineColor,
  });

  final List<ChartPoint> points;
  final ChartPalette palette;
  final Color Function(ChartPoint) markerColor;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    final xs = points.map((p) => _days(p.at)).toList();
    final ys = points.map((p) => p.value).toList();
    var minX = xs.reduce(math.min), maxX = xs.reduce(math.max);
    if (minX == maxX) {
      minX -= 3;
      maxX += 3;
    }
    var minY = ys.reduce(math.min), maxY = ys.reduce(math.max);
    final pad = math.max((maxY - minY) * 0.15, 1.0);
    minY -= pad;
    maxY += pad;
    final style = TextStyle(color: palette.inkSecondary, fontSize: 11);
    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: palette.grid, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, meta) => v == meta.min || v == meta.max
                  ? const SizedBox.shrink()
                  : SideTitleWidget(
                      meta: meta,
                      child: Text(_fmt(v), style: style),
                    ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: math.max((maxX - minX) / 3, 1),
              getTitlesWidget: (v, meta) => v == meta.min || v == meta.max
                  ? const SizedBox.shrink()
                  : SideTitleWidget(
                      meta: meta,
                      child: Text(_shortDate(_fromDays(v)), style: style),
                    ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => palette.surface,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${_shortDate(points[s.spotIndex].at)}\n${_fmt(s.y)}',
                  TextStyle(color: palette.ink, fontSize: 12),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (final p in points) FlSpot(_days(p.at), p.value)],
            isCurved: false,
            color: lineColor,
            barWidth: 2,
            dotData: FlDotData(
              getDotPainter: (spot, _, _, i) => FlDotCirclePainter(
                radius: 5,
                color: markerColor(points[i]),
                strokeWidth: 2,
                strokeColor: palette.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    super.key,
    required this.title,
    required this.semantics,
    required this.chart,
    this.legend,
    this.table,
  });
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
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: p.ink),
            ),
            const SizedBox(height: AppTokens.spaceSm),
            Semantics(
              label: semantics,
              child: ExcludeSemantics(
                child: SizedBox(height: 180, child: chart),
              ),
            ),
            if (legend != null) ...[
              const SizedBox(height: AppTokens.spaceSm),
              legend!,
            ],
            ?table,
          ],
        ),
      ),
    );
  }
}

/// Height or weight over time (single series: the title names it, no legend
/// box). A table view is available for screen readers and exact values.
class GrowthChart extends StatefulWidget {
  const GrowthChart({super.key, required this.title, required this.points});
  final String title;
  final List<ChartPoint> points;

  @override
  State<GrowthChart> createState() => _GrowthChartState();
}

class _GrowthChartState extends State<GrowthChart> {
  bool _table = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = ChartPalette.of(context);
    final pts = widget.points;
    if (pts.isEmpty) {
      return _ChartCard(
        title: widget.title,
        semantics: l.chartNoData,
        chart: Center(child: Text(l.chartNoData)),
      );
    }
    return _ChartCard(
      title: widget.title,
      semantics: l.chartSummary(pts.length, widget.title, _fmt(pts.last.value)),
      chart: _Line(
        points: pts,
        palette: p,
        markerColor: (_) => p.series,
        lineColor: p.series,
      ),
      table: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            key: Key('table-toggle-${widget.title}'),
            onPressed: () => setState(() => _table = !_table),
            child: Text(_table ? l.growthHideTable : l.growthShowTable),
          ),
          if (_table)
            DataTable(
              columns: [
                DataColumn(label: Text(l.chartDate)),
                DataColumn(label: Text(l.chartValue), numeric: true),
              ],
              rows: [
                for (final pt in pts.reversed)
                  DataRow(
                    cells: [
                      DataCell(Text(_shortDate(pt.at))),
                      DataCell(Text(_fmt(pt.value))),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Test results over time; each marker is coloured by the expected band
/// (ordinal ramp) and the legend names the bands, so colour is never the
/// only carrier of meaning.
class BandHistoryChart extends StatelessWidget {
  const BandHistoryChart({
    super.key,
    required this.title,
    required this.unit,
    required this.points,
  });
  final String title;
  final String unit;
  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = ChartPalette.of(context);
    if (points.isEmpty) {
      return _ChartCard(
        title: title,
        semantics: l.chartNoData,
        chart: Center(child: Text(l.chartNoData)),
      );
    }
    Color marker(ChartPoint pt) =>
        pt.band == null ? p.surface : p.bands[bandIndex(pt.band!)];
    return _ChartCard(
      key: Key('band-chart-$title'),
      title: '$title ($unit)',
      semantics: l.chartSummary(
        points.length,
        title,
        '${_fmt(points.last.value)} $unit',
      ),
      chart: _Line(
        points: points,
        palette: p,
        markerColor: marker,
        lineColor: p.inkSecondary,
      ),
      legend: Wrap(
        key: const Key('band-legend'),
        spacing: AppTokens.spaceMd,
        runSpacing: AppTokens.spaceXs,
        children: [
          for (var i = 0; i < normBands.length; i++)
            _Swatch(
              color: p.bands[i],
              label: normBands[i].label(l),
              ink: p.inkSecondary,
            ),
          _Swatch(
            color: p.surface,
            label: l.testNoBand.split(' ').take(2).join(' '),
            ink: p.inkSecondary,
            outlined: true,
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.ink,
    this.outlined = false,
  });
  final Color color;
  final String label;
  final Color ink;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: outlined ? Border.all(color: ink, width: 1.5) : null,
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: ink, fontSize: 12)),
    ],
  );
}

/// Helper for screens: points of a measurement series.
List<ChartPoint> measurementPoints(
  Iterable<ath.BodyMeasurement> list, {
  required bool height,
}) => [
  for (final m in list)
    if ((height ? m.heightCm : m.weightKg) != null)
      ChartPoint(
        m.measuredOn.toDateTime(utc: true),
        (height ? m.heightCm : m.weightKg)!,
      ),
];

List<ChartPoint> resultPoints(Iterable<ath.PhysicalTestResult> list) => [
  for (final r in list)
    ChartPoint(
      r.measuredOn.toDateTime(utc: true),
      r.value,
      band: r.expectedBand,
      pending: r.referencePending,
    ),
];

String athDateText(ath.Date d) => formatAthDate(d);
