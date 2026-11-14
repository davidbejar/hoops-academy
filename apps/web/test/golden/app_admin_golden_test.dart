import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/fake_academy_requests.dart';
import '../support/fake_platform.dart';
import '../support/fake_repos.dart';
import '../support/fixtures.dart';
import '../support/harness.dart';

/// The application admin hub, the Users area and the context switcher (WP99).
/// Regenerate with
/// `flutter test --update-goldens test/golden/app_admin_golden_test.dart`.
const _hangtuah = TenantMembership(
  tenantId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  tenantName: 'Hangtuah',
  slug: 'hangtuah',
  hasLogo: false,
  roles: {TenantRole.admin},
);
const _dewa = TenantMembership(
  tenantId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  tenantName: 'Dewa United',
  slug: 'dewa-united',
  hasLogo: false,
  roles: {TenantRole.admin, TenantRole.coach},
);
const _baskonia = TenantMembership(
  tenantId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  tenantName: 'Baskonia',
  slug: 'baskonia',
  hasLogo: false,
  roles: {TenantRole.coach},
);

Future<void> _matches(WidgetTester tester, String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('goldens/$name.png'),
);

Future<Harness> _pumpApplicationAdmin(
  WidgetTester tester,
  Size size,
  String location, {
  Brightness brightness = Brightness.light,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final platform = FakePlatformRepository(
    tenants: [tenantOf('t-a', 'Hangtuah'), tenantOf('t-b', 'Dewa United')],
  );
  platform.userList.addAll([
    platformUserOf(
      'u-1',
      'ana@example.org',
      memberships: [
        userMembership(
          't-a',
          'Hangtuah',
          given: 'Ana',
          family: 'García',
          roles: {api.TenantRole.ADMIN},
        ),
        userMembership(
          't-b',
          'Dewa United',
          given: 'Ana',
          family: 'García',
          roles: {api.TenantRole.COACH, api.TenantRole.PARENT},
        ),
      ],
    ),
    platformUserOf(
      'u-2',
      'budi@example.org',
      memberships: [
        userMembership(
          't-b',
          'Dewa United',
          given: 'Budi',
          family: 'Santoso',
          roles: {api.TenantRole.ADMIN},
          active: false,
        ),
      ],
    ),
    platformUserOf('u-3', 'nuevo@example.org'),
  ]);
  final h = Harness(
    me: FakeMeRepository(userWith(const [], superAdmin: true)),
    core: FakeCore(),
    platform: FakePlatform(repo: platform),
    academyRequests: FakeAcademyRequestRepository([
      academyRequestOf('r-1', 'Escuela de Baloncesto Valle'),
      academyRequestOf('r-2', 'Hoops Bali'),
      academyRequestOf('r-3', 'Canasta Club'),
    ]),
  );
  await h.pump(tester, size: size);
  if (location != '/app-admin') await h.go(tester, location);
  return h;
}

void main() {
  group('application admin hub', () {
    testWidgets('360x780', (tester) async {
      await _pumpApplicationAdmin(tester, const Size(360, 780), '/app-admin');
      await _matches(tester, 'app_admin_hub_360x780');
    });

    testWidgets('360x780, dark', (tester) async {
      await _pumpApplicationAdmin(
        tester,
        const Size(360, 780),
        '/app-admin',
        brightness: Brightness.dark,
      );
      await _matches(tester, 'app_admin_hub_360x780_dark');
    });

    testWidgets('1024x768', (tester) async {
      await _pumpApplicationAdmin(tester, const Size(1024, 768), '/app-admin');
      await _matches(tester, 'app_admin_hub_1024x768');
    });
  });

  group('users', () {
    testWidgets('360x780', (tester) async {
      await _pumpApplicationAdmin(
        tester,
        const Size(360, 780),
        '/app-admin/users',
      );
      await _matches(tester, 'app_admin_users_360x780');
    });

    testWidgets('360x780, dark', (tester) async {
      await _pumpApplicationAdmin(
        tester,
        const Size(360, 780),
        '/app-admin/users',
        brightness: Brightness.dark,
      );
      await _matches(tester, 'app_admin_users_360x780_dark');
    });

    testWidgets('1024x768', (tester) async {
      await _pumpApplicationAdmin(
        tester,
        const Size(1024, 768),
        '/app-admin/users',
      );
      await _matches(tester, 'app_admin_users_1024x768');
    });
  });

  group('context switcher', () {
    Future<void> openSwitcher(
      WidgetTester tester,
      Size size,
      String language,
      Key trigger,
    ) async {
      final h = Harness(
        me: FakeMeRepository(
          userWith([_hangtuah, _dewa, _baskonia], superAdmin: true),
        ),
        core: FakeCore(),
        platform: FakePlatform(repo: FakePlatformRepository()),
        prefs: {
          'hoops.selectedTenantId': _hangtuah.tenantId,
          'hoops.locale': language,
        },
      );
      await h.pump(tester, size: size);
      await tester.tap(find.byKey(trigger));
      await tester.pumpAndSettle();
    }

    for (final language in ['es', 'en', 'id']) {
      testWidgets('360x780, $language', (tester) async {
        await openSwitcher(
          tester,
          const Size(360, 780),
          language,
          const Key('tenant-chip'),
        );
        await _matches(tester, 'context_switcher_360x780_$language');
      });

      testWidgets('1024x768, $language', (tester) async {
        await openSwitcher(
          tester,
          const Size(1024, 768),
          language,
          const Key('rail-context'),
        );
        await _matches(tester, 'context_switcher_1024x768_$language');
      });
    }
  });
}
