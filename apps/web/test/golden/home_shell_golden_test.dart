import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/fake_repos.dart';
import '../support/fixtures.dart';
import '../support/harness.dart';

/// Regenerate with `flutter test --update-goldens test/golden`.
void main() {
  Future<void> pumpHome(
    WidgetTester tester,
    Size size, {
    Set<TenantRole> roles = const {TenantRole.admin},
    Brightness brightness = Brightness.light,
  }) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final h = Harness(
      me: FakeMeRepository(userWith([membershipWithRoles(roles)])),
      core: FakeCore(),
    );
    await h.pump(tester, size: size);
  }

  testWidgets('home shell, ADMIN, 360x780', (tester) async {
    await pumpHome(tester, const Size(360, 780));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_admin_360x780.png'),
    );
  });

  testWidgets('home shell, ADMIN, 1024x768', (tester) async {
    await pumpHome(tester, const Size(1024, 768));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_admin_1024x768.png'),
    );
  });

  testWidgets('home shell, PARENT, 360x780', (tester) async {
    await pumpHome(tester, const Size(360, 780), roles: {TenantRole.parent});
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_parent_360x780.png'),
    );
  });

  testWidgets('home shell, ADMIN, 1280x800 (extended rail)', (tester) async {
    await pumpHome(tester, const Size(1280, 800));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_admin_1280x800.png'),
    );
  });

  testWidgets('home shell, ADMIN, 360x780, dark', (tester) async {
    await pumpHome(tester, const Size(360, 780), brightness: Brightness.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_admin_360x780_dark.png'),
    );
  });

  testWidgets('home shell, ADMIN, 1024x768, dark', (tester) async {
    await pumpHome(tester, const Size(1024, 768), brightness: Brightness.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_admin_1024x768_dark.png'),
    );
  });
}
