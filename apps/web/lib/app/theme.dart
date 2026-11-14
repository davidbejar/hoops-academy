import 'package:material_ui/material_ui.dart';

import '../core/design/tokens.dart';

/// The Material 3 colour scheme of [c]: every role mapped to a token, nothing
/// generated from a seed (a seed gave the pink tint the app had before).
ColorScheme hoopsColorScheme(HoopsColors c) {
  final light = c.brightness == Brightness.light;
  return ColorScheme(
    brightness: c.brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    primaryContainer: c.accentSoft,
    onPrimaryContainer: c.onAccentSoft,
    secondary: light ? const Color(0xFF3D3832) : const Color(0xFFD6D0C6),
    onSecondary: light ? Colors.white : c.canvas,
    secondaryContainer: c.surfaceMuted,
    onSecondaryContainer: c.ink,
    tertiary: c.info.foreground,
    onTertiary: light ? Colors.white : const Color(0xFF0B1A33),
    tertiaryContainer: c.info.container,
    onTertiaryContainer: c.info.onContainer,
    error: c.danger.foreground,
    onError: light ? Colors.white : const Color(0xFF2A0A0A),
    errorContainer: c.danger.container,
    onErrorContainer: c.danger.onContainer,
    surface: c.canvas,
    onSurface: c.ink,
    onSurfaceVariant: c.inkMuted,
    surfaceDim: light ? const Color(0xFFEDE8E0) : c.canvas,
    surfaceBright: light ? c.canvas : c.surfaceMuted,
    surfaceContainerLowest: light ? Colors.white : const Color(0xFF0A0B0C),
    surfaceContainerLow: c.surface,
    surfaceContainer: light ? const Color(0xFFF6F2EC) : const Color(0xFF1B1D21),
    surfaceContainerHigh: c.surfaceRaised,
    surfaceContainerHighest: light
        ? const Color(0xFFEBE5DC)
        : const Color(0xFF26292E),
    outline: c.borderStrong,
    outlineVariant: c.border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: c.inverse,
    onInverseSurface: c.onInverse,
    inversePrimary: light ? const Color(0xFFF2783A) : const Color(0xFFC2410C),
    surfaceTint: Colors.transparent,
  );
}

ThemeData buildTheme(Brightness brightness) {
  final c = HoopsColors.of(brightness);
  final scheme = hoopsColorScheme(c);
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    textTheme: HoopsType.textTheme(c),
  );
  // The merged text theme: the token sizes on the platform typography (font
  // family), so component text styles below keep the family too.
  final text = base.textTheme;
  final control = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(HoopsRadius.md),
  );
  const minButton = Size(HoopsSize.minTapTarget, HoopsSize.minTapTarget);
  const buttonPadding = EdgeInsets.symmetric(horizontal: HoopsSpace.lg - 4);
  final hairline = BorderSide(color: c.border);
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(HoopsRadius.md),
    borderSide: BorderSide(color: c.borderStrong),
  );
  WidgetStateProperty<TextStyle> navLabel(TextStyle base) =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? base.copyWith(color: c.ink, fontWeight: FontWeight.w800)
            : base.copyWith(color: c.inkMuted, fontWeight: FontWeight.w600),
      );

  return base.copyWith(
    scaffoldBackgroundColor: c.canvas,
    canvasColor: c.canvas,
    dividerColor: c.border,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: [c],
    appBarTheme: AppBarTheme(
      backgroundColor: c.canvas,
      foregroundColor: c.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: HoopsSize.appBar,
      centerTitle: false,
      shape: Border(bottom: hairline),
      titleTextStyle: text.titleLarge!.copyWith(fontWeight: FontWeight.w800),
      iconTheme: IconThemeData(color: c.ink),
      actionsIconTheme: IconThemeData(color: c.ink),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: c.accentSoft,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoopsRadius.pill),
      ),
      labelTextStyle: navLabel(text.labelMedium!),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? c.onAccentSoft
              : c.inkMuted,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.surface,
      elevation: 0,
      indicatorColor: c.accentSoft,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoopsRadius.pill),
      ),
      selectedIconTheme: IconThemeData(color: c.onAccentSoft),
      unselectedIconTheme: IconThemeData(color: c.inkMuted),
      selectedLabelTextStyle: text.labelMedium!.copyWith(
        color: c.ink,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelTextStyle: text.labelMedium!.copyWith(
        color: c.inkMuted,
        fontWeight: FontWeight.w600,
      ),
      minWidth: 88,
      minExtendedWidth: 232,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: HoopsElevation.flat,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoopsRadius.lg),
        side: hairline,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.accentSoft,
      checkmarkColor: c.onAccentSoft,
      side: BorderSide(color: c.border),
      labelStyle: text.labelLarge!.copyWith(
        color: c.ink,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: text.labelLarge!.copyWith(color: c.onAccentSoft),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoopsRadius.sm),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: HoopsSpace.sm,
        vertical: HoopsSpace.xs + 2,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minButton,
        padding: buttonPadding,
        shape: control,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minButton,
        padding: buttonPadding,
        shape: control,
        foregroundColor: c.ink,
        side: BorderSide(color: c.borderStrong),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: minButton,
        foregroundColor: c.accentText,
        shape: control,
        textStyle: text.labelLarge,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: minButton,
        padding: buttonPadding,
        shape: control,
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        elevation: HoopsElevation.flat,
        side: hairline,
        textStyle: text.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: minButton,
        foregroundColor: c.ink,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent,
      foregroundColor: c.onAccent,
      elevation: HoopsElevation.raised,
      focusElevation: HoopsElevation.raised,
      hoverElevation: HoopsElevation.overlay,
      highlightElevation: HoopsElevation.overlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoopsRadius.lg - 4),
      ),
      extendedTextStyle: text.labelLarge,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: c.accentSoft,
        selectedForegroundColor: c.onAccentSoft,
        foregroundColor: c.ink,
        side: BorderSide(color: c.borderStrong),
        textStyle: text.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: c.accent, width: 2),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: c.danger.foreground),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: c.danger.foreground, width: 2),
      ),
      disabledBorder: inputBorder.copyWith(borderSide: hairline),
      labelStyle: text.bodyLarge!.copyWith(color: c.inkMuted),
      floatingLabelStyle: text.bodyLarge!.copyWith(color: c.ink),
      hintStyle: text.bodyLarge!.copyWith(color: c.inkMuted),
      helperStyle: text.bodySmall,
      errorStyle: text.bodySmall!.copyWith(color: c.danger.foreground),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: HoopsSpace.md,
        vertical: HoopsSpace.gap + 2,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: HoopsElevation.overlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoopsRadius.xl - 4),
      ),
      titleTextStyle: text.headlineSmall!.copyWith(fontSize: 22),
      contentTextStyle: text.bodyMedium!.copyWith(color: c.inkMuted),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surfaceRaised,
      modalBackgroundColor: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: HoopsElevation.overlay,
      modalElevation: HoopsElevation.overlay,
      showDragHandle: true,
      dragHandleColor: c.borderStrong,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(HoopsRadius.xl),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: HoopsElevation.raised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoopsRadius.md),
        side: hairline,
      ),
      textStyle: text.bodyMedium,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.surfaceRaised),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoopsRadius.md),
            side: hairline,
          ),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.inverse,
      contentTextStyle: text.bodyMedium!.copyWith(color: c.onInverse),
      actionTextColor: scheme.inversePrimary,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.inverse,
        borderRadius: BorderRadius.circular(HoopsRadius.xs),
      ),
      textStyle: text.labelMedium!.copyWith(color: c.onInverse),
    ),
    listTileTheme: ListTileThemeData(
      minTileHeight: 56,
      iconColor: c.inkMuted,
      textColor: c.ink,
      titleTextStyle: text.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
      subtitleTextStyle: text.bodyMedium!.copyWith(color: c.inkMuted),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoopsRadius.lg),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: HoopsSpace.md),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: c.ink,
      unselectedLabelColor: c.inkMuted,
      labelStyle: text.titleSmall,
      unselectedLabelStyle: text.titleSmall!.copyWith(
        fontWeight: FontWeight.w600,
      ),
      indicatorColor: c.brand,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: c.border,
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(c.surfaceMuted),
      headingTextStyle: text.labelLarge!.copyWith(color: c.inkMuted),
      dataTextStyle: text.bodyMedium,
      dividerThickness: 1,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(HoopsRadius.md),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.brand,
      linearTrackColor: c.surfaceMuted,
      circularTrackColor: Colors.transparent,
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: c.accent,
      textColor: c.onAccent,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: c.ink,
      collapsedIconColor: c.inkMuted,
      shape: const Border(),
      collapsedShape: const Border(),
    ),
  );
}
