import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/l10n/locale_controller.dart';
import 'package:hoops_app/core/l10n/theme_mode_controller.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/profile/presentation/profile_screen.dart';

import '../support/avatar_menu.dart';
import '../support/fixtures.dart';
import '../support/harness.dart';

/// WP105 (decision 79): language and theme live in the menu behind the avatar.
void main() {
  final admin = membershipWithRoles({TenantRole.admin});

  Future<Harness> pumpApp(
    WidgetTester tester, {
    Size size = const Size(360, 780),
    FakeMeRepository? me,
  }) async {
    final h = Harness(me: me ?? FakeMeRepository(userWith([admin])));
    await h.pump(tester, size: size);
    return h;
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final f = find.byKey(Key(key));
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  const layouts = {
    'phone': Size(360, 780),
    'tablet': Size(800, 900),
    'desktop': Size(1280, 800),
  };

  for (final MapEntry(key: name, value: size) in layouts.entries) {
    testWidgets('$name: the avatar opens the menu with language and theme', (
      tester,
    ) async {
      await pumpApp(tester, size: size);
      expect(find.byKey(const Key('avatar-menu')), findsNothing);

      await openAvatarMenu(tester);

      expect(find.byKey(const Key('avatar-menu')), findsOneWidget);
      for (final k in [
        'avatar-menu-profile',
        'lang-es',
        'lang-en',
        'lang-id',
        'theme-system',
        'theme-light',
        'theme-dark',
      ]) {
        expect(find.byKey(Key(k)), findsOneWidget, reason: k);
      }
    });
  }

  testWidgets('the menu names the person and opens the profile', (
    tester,
  ) async {
    await pumpApp(tester);
    await openAvatarMenu(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('avatar-menu')),
        matching: find.text('Casey Coach'),
      ),
      findsOneWidget,
    );

    await tapKey(tester, 'avatar-menu-profile');

    expect(find.byKey(const Key('avatar-menu')), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('also in the application admin context', (tester) async {
    final h = Harness(me: FakeMeRepository(userWith([], superAdmin: true)));
    await h.pump(tester, size: const Size(1280, 800));

    await openAvatarMenu(tester);

    expect(find.byKey(const Key('lang-en')), findsOneWidget);
    expect(find.byKey(const Key('theme-dark')), findsOneWidget);
  });

  testWidgets('the language rows switch es -> en -> id, persist and sync', (
    tester,
  ) async {
    final me = FakeMeRepository(userWith([admin]));
    final h = await pumpApp(tester, me: me);
    await openAvatarMenu(tester);

    await tapKey(tester, 'lang-en');
    expect(h.prefs.getString('hoops.locale'), 'en');
    expect(h.container.read(effectiveLocaleProvider), const Locale('en'));
    expect(navLabel('Teams'), findsOneWidget);

    await tapKey(tester, 'lang-id');
    expect(h.prefs.getString('hoops.locale'), 'id');
    expect(navLabel('Tim'), findsOneWidget);
    expect(me.localeUpdates, ['en', 'id']);
  });

  testWidgets('the theme rows switch the whole app and persist', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    await openAvatarMenu(tester);

    await tapKey(tester, 'theme-dark');
    expect(h.container.read(themeModePreferenceProvider), ThemeMode.dark);
    expect(h.prefs.getString('hoops.themeMode'), 'dark');
    expect(
      Theme.of(tester.element(find.byKey(const Key('avatar-menu')))).brightness,
      Brightness.dark,
    );

    await tapKey(tester, 'theme-light');
    expect(h.prefs.getString('hoops.themeMode'), 'light');
    expect(
      Theme.of(tester.element(find.byKey(const Key('avatar-menu')))).brightness,
      Brightness.light,
    );

    await tapKey(tester, 'theme-system');
    expect(h.prefs.getString('hoops.themeMode'), 'system');
  });

  testWidgets('the current choice is marked', (tester) async {
    await pumpApp(tester);
    await openAvatarMenu(tester);

    Finder checkIn(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byIcon(Icons.check_circle),
    );
    expect(checkIn('lang-es'), findsOneWidget);
    expect(checkIn('lang-en'), findsNothing);
    expect(checkIn('theme-system'), findsOneWidget);
    expect(checkIn('theme-dark'), findsNothing);

    await tapKey(tester, 'theme-dark');
    expect(checkIn('theme-dark'), findsOneWidget);
    expect(checkIn('theme-system'), findsNothing);
  });

  testWidgets('the profile screen no longer has a language section', (
    tester,
  ) async {
    await pumpApp(tester);
    await openProfile(tester);

    expect(find.byKey(const Key('lang-es')), findsNothing);
    expect(find.byKey(const Key('theme-dark')), findsNothing);
  });
}
