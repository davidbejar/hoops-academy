import 'package:material_ui/material_ui.dart';
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
