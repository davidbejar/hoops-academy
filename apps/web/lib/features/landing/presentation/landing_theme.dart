import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Colours of the landing page: one accent (the app's basketball orange) on
/// off-white or near-black, following the system brightness.
@immutable
class LandingPalette {
  const LandingPalette._({
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.accentText,
    required this.accentSoft,
    required this.band,
    required this.bandText,
    required this.bandMuted,
    required this.bandBorder,
  });

  /// The brand colour; buttons, icons and the glow behind the device mock-ups.
  static const accent = AppTokens.seedColor;
  static const onAccent = Colors.white;

  static const light = LandingPalette._(
    background: Color(0xFFFAF7F2),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF16130F),
    muted: Color(0xFF5E5850),
    border: Color(0xFFE8E1D6),
    // Darker orange for small text on off-white (4.5:1 and up).
    accentText: Color(0xFFC2410C),
    accentSoft: Color(0xFFFDEADC),
    band: Color(0xFF16130F),
    bandText: Color(0xFFF7F3EC),
    bandMuted: Color(0xFFB9B2A7),
    bandBorder: Color(0xFF2E2A25),
  );

  static const dark = LandingPalette._(
    background: Color(0xFF0E0F11),
    surface: Color(0xFF17191C),
    text: Color(0xFFF4F1EC),
    muted: Color(0xFFA7A39C),
    border: Color(0xFF282B30),
    accentText: Color(0xFFF2783A),
    accentSoft: Color(0xFF2B1A10),
    band: Color(0xFF17191C),
    bandText: Color(0xFFF4F1EC),
    bandMuted: Color(0xFFA7A39C),
    bandBorder: Color(0xFF2C2F34),
  );

  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color border;
  final Color accentText;
  final Color accentSoft;

  /// The contrasting band ("why it costs less").
  final Color band;
  final Color bandText;
  final Color bandMuted;
  final Color bandBorder;

  static LandingPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Width classes of the landing (360 px phones up to wide desktops).
enum LandingWidth {
  compact,
  medium,
  wide;

  static LandingWidth of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024) return wide;
    if (width >= 720) return medium;
    return compact;
  }

  bool get isCompact => this == compact;
  bool get isWide => this == wide;

  /// Horizontal page gutter.
  double get gutter => switch (this) {
    compact => 20,
    medium => 40,
    wide => 56,
  };

  /// Vertical space between sections.
  double get sectionGap => switch (this) {
    compact => 72,
    medium => 96,
    wide => 128,
  };

  /// Size of section titles.
  double get titleSize => switch (this) {
    compact => 30,
    medium => 38,
    wide => 44,
  };
}

/// Text styles of the landing; large type, tight headings, airy body copy.
abstract final class LandingType {
  static TextStyle headline(LandingWidth w, Color color) => TextStyle(
    fontSize: switch (w) {
      LandingWidth.compact => 38,
      LandingWidth.medium => 52,
      LandingWidth.wide => 62,
    },
    height: 1.04,
    fontWeight: FontWeight.w800,
    letterSpacing: w.isCompact ? -1.0 : -2.0,
    color: color,
  );

  static TextStyle title(LandingWidth w, Color color) => TextStyle(
    fontSize: w.titleSize,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: w.isCompact ? -0.6 : -1.2,
    color: color,
  );

  static TextStyle lead(LandingWidth w, Color color) =>
      TextStyle(fontSize: w.isCompact ? 17 : 20, height: 1.55, color: color);

  static TextStyle cardTitle(Color color) => TextStyle(
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: color,
  );

  static TextStyle body(Color color) =>
      TextStyle(fontSize: 15.5, height: 1.6, color: color);

  static TextStyle eyebrow(Color color) => TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    color: color,
  );

  static TextStyle small(Color color) =>
      TextStyle(fontSize: 13.5, height: 1.5, color: color);
}

/// Centres [child] in the page's content column (max 1200 px) with the gutter.
class LandingFrame extends StatelessWidget {
  const LandingFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final w = LandingWidth.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w.gutter),
          child: child,
        ),
      ),
    );
  }
}

/// Label style of the landing's buttons, on top of the app's text theme (so
/// they use the same font family as the rest of the page).
TextStyle landingButtonText(BuildContext context, {double size = 17}) =>
    Theme.of(context).textTheme.labelLarge!
        .copyWith(fontSize: size, fontWeight: FontWeight.w700);

/// Primary call to action: white on the brand orange.
ButtonStyle landingPrimaryButton(BuildContext context, {bool large = true}) =>
    FilledButton.styleFrom(
      backgroundColor: LandingPalette.accent,
      foregroundColor: LandingPalette.onAccent,
      padding: EdgeInsets.symmetric(
        horizontal: large ? 28 : 18,
        vertical: large ? 20 : 14,
      ),
      textStyle: landingButtonText(context, size: large ? 17 : 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

/// Secondary call to action: outlined in the text colour.
ButtonStyle landingSecondaryButton(BuildContext context) {
  final p = LandingPalette.of(context);
  return OutlinedButton.styleFrom(
    foregroundColor: p.text,
    side: BorderSide(color: p.text.withValues(alpha: 0.28), width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
    textStyle: landingButtonText(context),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

/// Quiet text link (header, footer).
ButtonStyle landingLinkButton(BuildContext context, Color color) =>
    TextButton.styleFrom(
      foregroundColor: color,
      disabledForegroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      minimumSize: const Size(48, 48),
      textStyle: landingButtonText(context, size: 14.5),
    );
