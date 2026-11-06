import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Tiles in as many equal columns as fit (each at least [minTileWidth], at
/// most [maxColumns]); the tiles of a row share their height.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 240,
    this.spacing = HoopsSpace.gap,
    this.maxColumns = 4,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final int maxColumns;

  static int columnsFor(
    double width, {
    required double minTileWidth,
    required double spacing,
    required int maxColumns,
  }) {
    final fit = ((width + spacing) / (minTileWidth + spacing)).floor();
    return math.max(1, math.min(fit, maxColumns));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = columnsFor(
        constraints.maxWidth,
        minTileWidth: minTileWidth,
        spacing: spacing,
        maxColumns: maxColumns,
      );
      final rows = <Widget>[];
      for (var start = 0; start < children.length; start += columns) {
        final cells = children.skip(start).take(columns).toList();
        if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < columns; i++) ...[
                  if (i > 0) SizedBox(width: spacing),
                  Expanded(
                    child: i < cells.length ? cells[i] : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: rows,
      );
    },
  );
}
