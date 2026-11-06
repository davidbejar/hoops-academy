import 'package:flutter/material.dart';

import '../ui/chart_tokens.dart';
import 'tone.dart';

/// A foreground drawn on a background, named for the contrast test.
typedef ColorPair = ({String name, Color foreground, Color background});

/// The colour roles of the design system (ADR-0040), light and dark.
///
/// Derived from the landing page (WP70): one basketball orange on a warm
/// off-white or near-black canvas, white / graphite cards with hairline
/// borders, near-black / warm white ink. Every text role meets WCAG AA on
/// every surface it is used on; `test/core/design/contrast_test.dart` checks
/// [textPairs] and [controlPairs].
///
/// Read it with `HoopsColors.of(Theme.of(context).brightness)` or, inside the
/// app, `Theme.of(context).extension<HoopsColors>()!` (both are the same).
@immutable
class HoopsColors extends ThemeExtension<HoopsColors> {
  const HoopsColors({
    required this.brightness,
    required this.brand,
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.border,
    required this.borderStrong,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.inverse,
    required this.onInverse,
    required this.neutral,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.chart,
  });

  /// The landing's orange. Decorative only (icons, indicators, focus, glow):
  /// white text on it is 3.6:1, below AA, so buttons use [accent].
  static const brandOrange = Color(0xFFE8590C);

  final Brightness brightness;

  /// [brandOrange]; at least 3:1 on [canvas] and [surface] (icons, marks).
  final Color brand;

  /// Page background (the landing's off-white / near-black).
  final Color canvas;

  /// Cards, bars and sheets on the canvas.
  final Color surface;

  /// Quiet fills: neutral chips, progress tracks, table headers, hovers.
  final Color surfaceMuted;

  /// Dialogs, menus and bottom sheets.
  final Color surfaceRaised;

  /// Body text and headings.
  final Color ink;

  /// Secondary text (subtitles, captions, unselected labels).
  final Color inkMuted;

  /// Hairlines: card borders, dividers.
  final Color border;

  /// Outlines of controls (inputs, outlined buttons): 3:1 on the surfaces.
  final Color borderStrong;

  /// Primary action fill (filled buttons, FAB) and [onAccent] its label.
  final Color accent;
  final Color onAccent;

  /// Orange text and links on the canvas, cards and dialogs.
  final Color accentText;

  /// Selected / highlighted fill (nav indicator, selected chips) and its ink.
  final Color accentSoft;
  final Color onAccentSoft;

  /// The landing's contrasting band, tooltips and snack bars.
  final Color inverse;
  final Color onInverse;

  final ToneColors neutral;
  final ToneColors success;
  final ToneColors warning;
  final ToneColors danger;
  final ToneColors info;

  /// Chart colours (dataviz palette, WP14), unchanged by the design system.
  final ChartPalette chart;

  /// The colours of [tone]; [HoopsTone.accent] is the soft orange.
  ToneColors tone(HoopsTone tone) => switch (tone) {
    HoopsTone.neutral => neutral,
    HoopsTone.accent => ToneColors(
      foreground: accentText,
      container: accentSoft,
      onContainer: onAccentSoft,
    ),
    HoopsTone.success => success,
    HoopsTone.warning => warning,
    HoopsTone.danger => danger,
    HoopsTone.info => info,
  };

  static const light = HoopsColors(
    brightness: Brightness.light,
    brand: brandOrange,
    canvas: Color(0xFFFAF7F2),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF2EDE5),
    surfaceRaised: Color(0xFFFFFFFF),
    ink: Color(0xFF16130F),
    inkMuted: Color(0xFF5E5850),
    border: Color(0xFFE8E1D6),
    borderStrong: Color(0xFF8C8479),
    // Orange 700: white labels at 5.2:1 (decision recorded in ADR-0040).
    accent: Color(0xFFC2410C),
    onAccent: Color(0xFFFFFFFF),
    accentText: Color(0xFFB4380A),
    accentSoft: Color(0xFFFDEADC),
    onAccentSoft: Color(0xFF7C2D12),
    inverse: Color(0xFF16130F),
    onInverse: Color(0xFFF7F3EC),
    neutral: ToneColors(
      foreground: Color(0xFF5E5850),
      container: Color(0xFFF2EDE5),
      onContainer: Color(0xFF3D3832),
    ),
    success: ToneColors(
      foreground: Color(0xFF15803D),
      container: Color(0xFFDCF5E3),
      onContainer: Color(0xFF14532D),
    ),
    warning: ToneColors(
      foreground: Color(0xFFA14A08),
      container: Color(0xFFFDF1D3),
      onContainer: Color(0xFF78350F),
    ),
    danger: ToneColors(
      foreground: Color(0xFFB91C1C),
      container: Color(0xFFFDE4E2),
      onContainer: Color(0xFF7F1D1D),
    ),
    info: ToneColors(
      foreground: Color(0xFF1D4ED8),
      container: Color(0xFFE0EBFD),
      onContainer: Color(0xFF1E3A8A),
    ),
    chart: ChartPalette.light,
  );

  static const dark = HoopsColors(
    brightness: Brightness.dark,
    brand: brandOrange,
    canvas: Color(0xFF0E0F11),
    surface: Color(0xFF17191C),
    surfaceMuted: Color(0xFF22252A),
    surfaceRaised: Color(0xFF1C1F23),
    ink: Color(0xFFF4F1EC),
    inkMuted: Color(0xFFA7A39C),
    border: Color(0xFF2A2D32),
    borderStrong: Color(0xFF78736C),
    // On near-black the orange lightens and takes a dark label (6.6:1).
    accent: Color(0xFFF2783A),
    onAccent: Color(0xFF16130F),
    accentText: Color(0xFFF2783A),
    accentSoft: Color(0xFF3A2012),
    onAccentSoft: Color(0xFFFFC9A3),
    inverse: Color(0xFFF4F1EC),
    onInverse: Color(0xFF16130F),
    neutral: ToneColors(
      foreground: Color(0xFFA7A39C),
      container: Color(0xFF22252A),
      onContainer: Color(0xFFE2DDD5),
    ),
    success: ToneColors(
      foreground: Color(0xFF4ADE80),
      container: Color(0xFF12301F),
      onContainer: Color(0xFFBBF7D0),
    ),
    warning: ToneColors(
      foreground: Color(0xFFFBBF24),
      container: Color(0xFF36290B),
      onContainer: Color(0xFFFDE68A),
    ),
    danger: ToneColors(
      foreground: Color(0xFFF87171),
      container: Color(0xFF3B1518),
      onContainer: Color(0xFFFECACA),
    ),
    info: ToneColors(
      foreground: Color(0xFF60A5FA),
      container: Color(0xFF10243F),
      onContainer: Color(0xFFBFDBFE),
    ),
    chart: ChartPalette.dark,
  );

  static HoopsColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Every text colour on every background it is used on (AA: 4.5:1).
  List<ColorPair> get textPairs {
    final pages = {
      'canvas': canvas,
      'surface': surface,
      'surfaceRaised': surfaceRaised,
    };
    ColorPair pair(String name, Color fg, Color bg) =>
        (name: name, foreground: fg, background: bg);
    final tones = {
      'neutral': neutral,
      'accent': tone(HoopsTone.accent),
      'success': success,
      'warning': warning,
      'danger': danger,
      'info': info,
    };
    return [
      for (final MapEntry(key: name, value: bg) in pages.entries) ...[
        pair('ink/$name', ink, bg),
        pair('inkMuted/$name', inkMuted, bg),
        for (final MapEntry(key: t, value: c) in tones.entries)
          pair('$t.foreground/$name', c.foreground, bg),
      ],
      pair('ink/surfaceMuted', ink, surfaceMuted),
      pair('inkMuted/surfaceMuted', inkMuted, surfaceMuted),
      pair('onAccent/accent', onAccent, accent),
      pair('onInverse/inverse', onInverse, inverse),
      for (final MapEntry(key: t, value: c) in tones.entries) ...[
        pair('$t.onContainer/$t.container', c.onContainer, c.container),
        pair('ink/$t.container', ink, c.container),
      ],
      pair('chart.ink/chart.surface', chart.ink, chart.surface),
      pair(
        'chart.inkSecondary/chart.surface',
        chart.inkSecondary,
        chart.surface,
      ),
    ];
  }

  /// Icons, indicators and control outlines (WCAG 1.4.11: 3:1).
  List<ColorPair> get controlPairs => [
    for (final MapEntry(key: name, value: bg) in {
      'canvas': canvas,
      'surface': surface,
      'surfaceRaised': surfaceRaised,
    }.entries) ...[
      (name: 'brand/$name', foreground: brand, background: bg),
      (name: 'accent/$name', foreground: accent, background: bg),
      (name: 'borderStrong/$name', foreground: borderStrong, background: bg),
    ],
  ];

  @override
  HoopsColors copyWith() => this;

  @override
  HoopsColors lerp(covariant HoopsColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return HoopsColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      brand: c(brand, other.brand),
      canvas: c(canvas, other.canvas),
      surface: c(surface, other.surface),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      ink: c(ink, other.ink),
      inkMuted: c(inkMuted, other.inkMuted),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      accentText: c(accentText, other.accentText),
      accentSoft: c(accentSoft, other.accentSoft),
      onAccentSoft: c(onAccentSoft, other.onAccentSoft),
      inverse: c(inverse, other.inverse),
      onInverse: c(onInverse, other.onInverse),
      neutral: ToneColors.lerp(neutral, other.neutral, t),
      success: ToneColors.lerp(success, other.success, t),
      warning: ToneColors.lerp(warning, other.warning, t),
      danger: ToneColors.lerp(danger, other.danger, t),
      info: ToneColors.lerp(info, other.info, t),
      chart: t < 0.5 ? chart : other.chart,
    );
  }
}
