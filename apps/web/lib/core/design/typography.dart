import 'package:flutter/material.dart';

import 'colors.dart';

/// Type scale: the landing's character (heavy, slightly tight headings, airy
/// body copy) at app sizes. Font: the platform's Roboto (no extra download).
abstract final class HoopsType {
  static TextTheme textTheme(HoopsColors c) => TextTheme(
    displaySmall: _heading(36, -1.0, c.ink),
    headlineLarge: _heading(32, -0.8, c.ink),
    headlineMedium: _heading(28, -0.6, c.ink),
    headlineSmall: _heading(24, -0.4, c.ink),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.25,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: c.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.3,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
      color: c.ink,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: c.ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: c.ink),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: c.ink),
    bodySmall: TextStyle(fontSize: 12.5, height: 1.45, color: c.inkMuted),
    labelLarge: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
    labelMedium: const TextStyle(
      fontSize: 12.5,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelSmall: const TextStyle(
      fontSize: 11.5,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
  );

  /// Label above a title (the landing's role names). The helpers below take
  /// the theme's [TextTheme] so they keep its font family.
  static TextStyle eyebrow(TextTheme t, HoopsColors c) =>
      t.labelSmall!.copyWith(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: c.accentText,
      );

  /// The number of a stat tile (tabular figures so digits do not jump).
  static TextStyle statValue(TextTheme t, HoopsColors c) =>
      t.headlineMedium!.copyWith(
        fontSize: 30,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: c.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// The academy name in the app bar (the landing's brand line).
  static TextStyle brand(TextTheme t, HoopsColors c) => t.titleLarge!.copyWith(
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: c.ink,
  );

  static TextStyle _heading(double size, double tracking, Color color) =>
      TextStyle(
        fontSize: size,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: tracking,
        color: color,
      );
}
