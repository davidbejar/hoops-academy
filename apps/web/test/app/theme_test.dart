import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/theme.dart';
import 'package:hoops_app/core/design/tokens.dart';

void main() {
  for (final brightness in Brightness.values) {
    group('buildTheme(${brightness.name})', () {
      final theme = buildTheme(brightness);
      final c = HoopsColors.of(brightness);

      test('carries the tokens as a theme extension', () {
        expect(theme.extension<HoopsColors>(), same(c));
        expect(theme.brightness, brightness);
      });

      test('maps the scheme to the tokens (no seed-generated tint)', () {
        final s = theme.colorScheme;
        expect(s.primary, c.accent);
        expect(s.onPrimary, c.onAccent);
        expect(s.primaryContainer, c.accentSoft);
        expect(s.surface, c.canvas);
        expect(s.surfaceContainerLow, c.surface);
        expect(s.onSurface, c.ink);
        expect(s.onSurfaceVariant, c.inkMuted);
        expect(s.error, c.danger.foreground);
        expect(s.outlineVariant, c.border);
        expect(s.surfaceTint, Colors.transparent);
        expect(theme.scaffoldBackgroundColor, c.canvas);
      });

      test('cards are flat surfaces with a hairline border', () {
        final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
        expect(theme.cardTheme.color, c.surface);
        expect(theme.cardTheme.elevation, 0);
        expect(shape.side.color, c.border);
        expect(shape.borderRadius, BorderRadius.circular(HoopsRadius.lg));
      });

      test('app bar sits on the canvas with a bottom hairline', () {
        expect(theme.appBarTheme.backgroundColor, c.canvas);
        expect(theme.appBarTheme.scrolledUnderElevation, 0);
        expect(
          theme.appBarTheme.shape,
          Border(bottom: BorderSide(color: c.border)),
        );
      });

      test('navigation highlights with the soft accent', () {
        expect(theme.navigationBarTheme.indicatorColor, c.accentSoft);
        expect(theme.navigationRailTheme.indicatorColor, c.accentSoft);
        expect(theme.navigationBarTheme.backgroundColor, c.surface);
      });

      test('buttons keep the 48 px tap target and the control radius', () {
        final style = theme.filledButtonTheme.style!;
        expect(
          style.minimumSize!.resolve({}),
          const Size(HoopsSize.minTapTarget, HoopsSize.minTapTarget),
        );
        expect(
          (style.shape!.resolve({})! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(HoopsRadius.md),
        );
        expect(theme.floatingActionButtonTheme.backgroundColor, c.accent);
      });

      test('headings are heavy, body text uses the ink colours', () {
        expect(theme.textTheme.headlineSmall!.fontWeight, FontWeight.w800);
        expect(theme.textTheme.titleLarge!.fontWeight, FontWeight.w700);
        expect(theme.textTheme.bodyLarge!.color, c.ink);
        expect(theme.textTheme.bodySmall!.color, c.inkMuted);
      });

      test('inputs are outlined with the 3:1 control border', () {
        final border =
            theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
        expect(border.borderSide.color, c.borderStrong);
        expect(theme.inputDecorationTheme.fillColor, c.surface);
      });
    });
  }

  test('width classes switch at 720 and 1024 px', () {
    expect(WidthClass.forWidth(360), WidthClass.compact);
    expect(WidthClass.forWidth(719), WidthClass.compact);
    expect(WidthClass.forWidth(720), WidthClass.medium);
    expect(WidthClass.forWidth(1024), WidthClass.expanded);
    expect(WidthClass.compact.gutter, HoopsSpace.md);
    expect(WidthClass.expanded.gutter, HoopsSpace.xl);
  });

  test('HoopsColors.lerp blends tones and keeps the end points', () {
    final light = HoopsColors.light;
    final dark = HoopsColors.dark;
    expect(light.lerp(dark, 0).canvas, light.canvas);
    expect(light.lerp(dark, 1).canvas, dark.canvas);
    expect(light.lerp(dark, 1).danger.container, dark.danger.container);
    expect(light.lerp(null, 0.5), same(light));
    expect(light.tone(HoopsTone.accent).container, light.accentSoft);
    expect(light.tone(HoopsTone.warning), same(light.warning));
  });
}
