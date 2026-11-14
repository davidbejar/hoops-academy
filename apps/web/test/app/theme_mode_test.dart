import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/l10n/theme_mode_controller.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

/// WP105 (decision 79): light, dark or system, remembered in the browser.
void main() {
  final admin = membershipWithRoles({TenantRole.admin});

  Harness harness({Map<String, Object> prefs = const {}}) =>
      Harness(me: FakeMeRepository(userWith([admin])), prefs: prefs);

  ThemeMode appThemeMode(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

  Brightness shownBrightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

  testWidgets('nothing stored: system', (tester) async {
    final h = harness();
    await h.pump(tester);

    expect(h.container.read(themeModePreferenceProvider), ThemeMode.system);
    expect(appThemeMode(tester), ThemeMode.system);
  });

  testWidgets('an unknown stored value means system', (tester) async {
    final h = harness(prefs: {'hoops.themeMode': 'sepia'});
    await h.pump(tester);

    expect(appThemeMode(tester), ThemeMode.system);
  });

  testWidgets('system follows the platform brightness', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final h = harness();
    await h.pump(tester);
    expect(shownBrightness(tester), Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(shownBrightness(tester), Brightness.light);
  });

  testWidgets('an explicit choice beats the platform and is stored', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final h = harness();
    await h.pump(tester);

    await h.container
        .read(themeModePreferenceProvider.notifier)
        .set(ThemeMode.light);
    await tester.pumpAndSettle();

    expect(appThemeMode(tester), ThemeMode.light);
    expect(shownBrightness(tester), Brightness.light);
    expect(h.prefs.getString('hoops.themeMode'), 'light');

    await h.container
        .read(themeModePreferenceProvider.notifier)
        .set(ThemeMode.dark);
    expect(h.prefs.getString('hoops.themeMode'), 'dark');
    await h.container
        .read(themeModePreferenceProvider.notifier)
        .set(ThemeMode.system);
    expect(h.prefs.getString('hoops.themeMode'), 'system');
  });

  testWidgets('a stored choice survives a reload', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final h = harness(prefs: {'hoops.themeMode': 'dark'});
    await h.pump(tester);

    expect(appThemeMode(tester), ThemeMode.dark);
    expect(shownBrightness(tester), Brightness.dark);
  });
}
