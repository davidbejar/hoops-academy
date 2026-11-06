import 'package:flutter/painting.dart';

/// WCAG 2.x contrast ratio of [foreground] drawn on [background], 1..21.
///
/// A translucent foreground is composited over the (opaque) background
/// first, as the eye sees it. AA asks 4.5:1 for normal text and 3:1 for large
/// text and for the outlines of controls (WCAG 1.4.3 / 1.4.11).
double contrastRatio(Color foreground, Color background) {
  final bg = background.withValues(alpha: 1);
  final fg = Color.alphaBlend(foreground, bg);
  final a = fg.computeLuminance();
  final b = bg.computeLuminance();
  final (light, dark) = a > b ? (a, b) : (b, a);
  return (light + 0.05) / (dark + 0.05);
}

/// Minimum ratio for body text (WCAG 1.4.3, level AA).
const aaText = 4.5;

/// Minimum ratio for large text, icons and control outlines (WCAG 1.4.11).
const aaNonText = 3.0;
