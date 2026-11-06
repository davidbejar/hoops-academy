import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;

import '../support/fake_platform.dart';
import '../support/fake_repos.dart';
import '../support/fixtures.dart';
import '../support/harness.dart';

/// Regenerate with `flutter test --update-goldens test/golden/platform_admins_golden_test.dart`.
void main() {
  final ana = adminOf(
    'p-ana',
    'Ana',
    'Ruiz',
    email: 'ana.ruiz@club-norte.example',
    otherRoles: {api.TenantRole.COACH, api.TenantRole.PARENT},
  );
  final bea = adminOf(
    'p-bea',
    'Beatriz',
    'Soto Fernández',
    email: 'beatriz.soto@club-norte.example',
    status: api.InvitationStatus.PENDING,
  );

  Future<void> pumpDetail(
    WidgetTester tester,
    Size size,
    List<api.TenantAdmin> admins, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final h = Harness(
      me: FakeMeRepository(userWith(const [], superAdmin: true)),
      core: FakeCore(),
      platform: FakePlatform(
        repo: FakePlatformRepository(
          tenants: [tenantOf('t-a', 'Club Norte')],
          admins: {'t-a': admins},
        ),
      ),
    );
    await h.pump(tester, size: size);
    await h.go(tester, '/platform/t-a');
  }

  testWidgets('academy detail with administrators, 360x780', (tester) async {
    await pumpDetail(tester, const Size(360, 780), [ana, bea]);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/platform_admins_360x780.png'),
    );
  });

  testWidgets('academy detail with administrators, 360x780, dark', (
    tester,
  ) async {
    await pumpDetail(tester, const Size(360, 780), [
      ana,
      bea,
    ], brightness: Brightness.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/platform_admins_360x780_dark.png'),
    );
  });

  testWidgets('academy detail with administrators, 1024x768', (tester) async {
    await pumpDetail(tester, const Size(1024, 768), [ana, bea]);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/platform_admins_1024x768.png'),
    );
  });

  testWidgets('academy detail with a single (last) administrator, 360x780', (
    tester,
  ) async {
    await pumpDetail(tester, const Size(360, 780), [ana]);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/platform_admins_last_360x780.png'),
    );
  });

  testWidgets('add administrator dialog, 360x780', (tester) async {
    await pumpDetail(tester, const Size(360, 780), [ana, bea]);
    await tester.tap(find.byKey(const Key('admin-add')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/platform_admin_add_360x780.png'),
    );
  });
}
