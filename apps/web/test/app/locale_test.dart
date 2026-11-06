import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/l10n/locale_controller.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

void main() {
  final admin = membershipWithRoles({TenantRole.admin});

  testWidgets('defaults to the academy defaultLocale', (tester) async {
    final h = Harness(
      me: FakeMeRepository(userWith([admin])),
      tenant: FakeTenantRepository(defaultLocale: 'en'),
    );
    await h.pump(tester);

    expect(navLabel('Teams'), findsOneWidget);
    expect(navLabel('Equipos'), findsNothing);
  });

  testWidgets('falls back to Spanish when nothing is known', (tester) async {
    final h = Harness(me: FakeMeRepository(userWith([admin])));
    await h.pump(tester);

    expect(navLabel('Equipos'), findsOneWidget);
  });

  testWidgets('the language picker switches es -> en -> id and persists', (
    tester,
  ) async {
    final me = FakeMeRepository(userWith([admin]));
    final h = Harness(me: me);
    await h.pump(tester);

    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('lang-en')));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(h.prefs.getString('hoops.locale'), 'en');
    expect(h.container.read(effectiveLocaleProvider), const Locale('en'));

    await tester.tap(find.byKey(const Key('lang-id')));
    await tester.pumpAndSettle();
    expect(find.text('Profil'), findsOneWidget);
    expect(h.prefs.getString('hoops.locale'), 'id');
    expect(me.localeUpdates, ['en', 'id']);

    await tester.tap(find.byKey(const Key('lang-es')));
    await tester.pumpAndSettle();
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('a stored choice beats the academy default', (tester) async {
    final h = Harness(
      me: FakeMeRepository(userWith([admin])),
      tenant: FakeTenantRepository(defaultLocale: 'en'),
      prefs: {'hoops.locale': 'id'},
    );
    await h.pump(tester);

    expect(navLabel('Tim'), findsOneWidget);
  });
}
