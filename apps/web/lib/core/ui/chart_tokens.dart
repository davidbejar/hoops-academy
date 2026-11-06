import 'package:flutter/material.dart';

/// Chart colours from the dataviz reference palette (validated with
/// `validate_palette.py`: ordinal ramp, one hue, monotone lightness, light end
/// >= 2:1 on the surface; the dark ramp uses steps 200/300/400/500/600).
/// Text in charts always uses the ink tokens, never a series colour.
class ChartPalette {
  const ChartPalette({
    required this.surface,
    required this.ink,
    required this.inkSecondary,
    required this.grid,
    required this.series,
    required this.bands,
  });

  final Color surface;
  final Color ink;
  final Color inkSecondary;
  final Color grid;

  /// Categorical slot 1 (single-series charts).
  final Color series;

  /// Ordinal ramp for the five norm bands, POOR .. EXCELLENT.
  final List<Color> bands;

  static const light = ChartPalette(
    surface: Color(0xFFFCFCFB),
    ink: Color(0xFF0B0B0B),
    inkSecondary: Color(0xFF52514E),
    grid: Color(0x1F52514E),
    series: Color(0xFF2A78D6),
    bands: [
      Color(0xFF86B6EF),
      Color(0xFF5598E7),
      Color(0xFF2A78D6),
      Color(0xFF1C5CAB),
      Color(0xFF104281),
    ],
  );

  static const dark = ChartPalette(
    surface: Color(0xFF1A1A19),
    ink: Color(0xFFF0EFEC),
    inkSecondary: Color(0xFFC3C2B7),
    grid: Color(0x29C3C2B7),
    series: Color(0xFF3987E5),
    bands: [
      Color(0xFF9EC5F4),
      Color(0xFF6DA7EC),
      Color(0xFF3987E5),
      Color(0xFF256ABF),
      Color(0xFF184F95),
    ],
  );

  static ChartPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
