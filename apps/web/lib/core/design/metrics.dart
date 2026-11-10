import 'package:flutter/widgets.dart';

/// Spacing scale (logical pixels, 4 px grid). Widgets use these names, never
/// literals.
abstract final class HoopsSpace {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;

  /// Default gap between stacked items (cards in a list, form fields).
  static const gap = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;
}

/// Corner radii. The landing's buttons are 14, its cards 22.
abstract final class HoopsRadius {
  /// Status chips, small badges.
  static const xs = 6.0;

  /// Filter chips, avatars of rows, icon tiles.
  static const sm = 10.0;

  /// Buttons, inputs, menus, banners.
  static const md = 14.0;

  /// Cards and tiles.
  static const lg = 20.0;

  /// Dialogs and bottom sheets.
  static const xl = 28.0;

  /// Fully rounded (pills).
  static const pill = 999.0;
}

/// Elevation levels: the design is flat (hairline borders), elevation is for
/// things that float over the page.
abstract final class HoopsElevation {
  static const flat = 0.0;

  /// Floating action button, menus.
  static const raised = 2.0;

  /// Dialogs and bottom sheets.
  static const overlay = 6.0;
}

/// Durations and curves of motion. Respect `MediaQuery.disableAnimations`.
abstract final class HoopsMotion {
  /// Hover, press, colour changes.
  static const fast = Duration(milliseconds: 120);

  /// Most transitions (banners, indicators).
  static const standard = Duration(milliseconds: 200);

  /// Larger movements (sheets, expanding panels).
  static const emphasized = Duration(milliseconds: 320);

  /// Entrance of content once in view (landing).
  static const reveal = Duration(milliseconds: 700);

  static const curve = Curves.easeOutCubic;
  static const emphasizedCurve = Curves.easeInOutCubic;
}

/// Sizes that are not spacing.
abstract final class HoopsSize {
  /// Minimum interactive size (Material guideline, comfortable court-side).
  static const minTapTarget = 48.0;

  /// Height of the app bar.
  static const appBar = 64.0;

  /// Icon inside a tile or empty state.
  static const iconTile = 44.0;

  /// Avatar of a list row and of the profile button.
  static const avatar = 40.0;

  /// Bottom padding of a list under an extended floating action button, so
  /// the last row is never covered by it.
  static const fabClearance = 88.0;
}

/// Width classes: phones (compact), tablets (medium), desktops (expanded).
enum WidthClass {
  compact,
  medium,
  expanded;

  /// From this width the shell uses a navigation rail instead of a bar.
  static const mediumMin = 720.0;

  /// From this width the rail shows its labels beside the icons.
  static const expandedMin = 1024.0;

  /// Reading width of forms and lists.
  static const readingMax = 720.0;

  /// Width of dashboards and grids.
  static const contentMax = 1200.0;

  static WidthClass forWidth(double width) {
    if (width >= expandedMin) return expanded;
    if (width >= mediumMin) return medium;
    return compact;
  }

  static WidthClass of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);

  /// Horizontal page padding.
  double get gutter => switch (this) {
    compact => HoopsSpace.md,
    medium => HoopsSpace.lg,
    expanded => HoopsSpace.xl,
  };

  /// Vertical space between page sections.
  double get sectionGap => switch (this) {
    compact => HoopsSpace.lg,
    medium => HoopsSpace.xl,
    expanded => HoopsSpace.xl,
  };

  bool get isCompact => this == compact;
}
