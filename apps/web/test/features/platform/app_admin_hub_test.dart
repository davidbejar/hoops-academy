import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/app/shell.dart';
import 'package:hoops_app/core/navigation/destinations.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/fake_academy_requests.dart';
import '../../support/fake_platform.dart';
import '../../support/fake_repos.dart';
import '../../support/fixtures.dart';
import '../../support/harness.dart';
import '../../support/pump_helpers.dart';

/// The application admin hub (WP99): one entry per area of what a super
/// admin can do, like the academy admin hub of WP75.
Future<Harness> _pump(
  WidgetTester tester, {
  FakePlatformRepository? repo,
  FakeAcademyRequestRepository? requests,
  Size size = const Size(360, 780),
  String location = '/app-admin',
}) async {
  final h = Harness(
    me: FakeMeRepository(userWith(const [], superAdmin: true)),
    core: FakeCore(),
    platform: FakePlatform(repo: repo ?? FakePlatformRepository()),
    academyRequests: requests,
  );
  await h.pump(tester, size: size);
  if (location != '/app-admin') await h.go(tester, location);
  return h;
}

void main() {
  testWidgets('shows the five areas, billing marked as coming soon', (
    tester,
  ) async {
    await _pump(tester);

    for (final key in [
      'app-admin-academies',
      'app-admin-users',
      'app-admin-requests',
      'app-admin-activity',
      'app-admin-billing',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(find.text('Próximamente'), findsOneWidget);
  });

  group('each entry opens its area', () {
    const areas = {
      'app-admin-academies': '/app-admin/academies',
      'app-admin-users': '/app-admin/users',
      'app-admin-requests': '/app-admin/requests',
      'app-admin-activity': '/app-admin/activity',
      'app-admin-billing': '/app-admin/billing',
    };
    for (final MapEntry(key: key, value: path) in areas.entries) {
      testWidgets(path, (tester) async {
        final h = await _pump(tester);
        await tapKey(tester, key);
        expect(h.container.read(routerProvider).state.uri.path, path);
      });
    }
  });

  testWidgets('the navigation highlights the area, the hub for billing', (
    tester,
  ) async {
    await _pump(tester, location: '/app-admin/users');
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
  });

  testWidgets('billing is a placeholder and its screen calls nothing', (
    tester,
  ) async {
    final repo = FakePlatformRepository();
    await _pump(tester, repo: repo, location: '/app-admin/billing');

    expect(find.byKey(const Key('billing-soon')), findsOneWidget);
    expect(find.text('La facturación llega pronto'), findsOneWidget);
    expect(repo.calls, isEmpty);
    // The back arrow returns to the hub.
    await tester.tap(find.byKey(const Key('back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app-admin-hub')), findsOneWidget);
  });

  testWidgets('the hub badge follows the decisions of the workbench', (
    tester,
  ) async {
    final requests = FakeAcademyRequestRepository([
      academyRequestOf('r-1', 'Escuela Valle'),
    ]);
    final h = await _pump(
      tester,
      requests: requests,
      size: const Size(390, 1400),
    );
    expect(find.byKey(const Key('app-admin-requests-badge')), findsOneWidget);

    await h.go(tester, '/app-admin/requests');
    await tester.tap(find.byKey(const Key('request-reject-r-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('reject-reason')), 'No encaja');
    await tester.tap(find.widgetWithText(FilledButton, 'Rechazar').last);
    await tester.pumpAndSettle();

    await h.go(tester, '/app-admin');
    expect(find.byKey(const Key('app-admin-requests-badge')), findsNothing);
    expect(find.byKey(const Key('nav-requests-badge')), findsNothing);
  });

  test('selectedDestination picks the longest matching path', () {
    final nav = destinationsFor(roles: const {}, applicationAdmin: true);
    int at(String location) => selectedDestination(nav, location);
    expect(at('/app-admin'), 0);
    expect(at('/app-admin/billing'), 0);
    expect(at('/app-admin/academies'), 1);
    expect(at('/app-admin/academies/t-1/activity'), 1);
    expect(at('/app-admin/users'), 2);
    expect(at('/app-admin/requests'), 3);
    expect(at('/app-admin/activity'), 4);
    expect(at('/elsewhere'), 0);
    expect(at('/app-adminx'), 0);
  });

  testWidgets('a coach never sees the hub', (tester) async {
    final h = Harness(
      me: FakeMeRepository(
        userWith([
          membershipWithRoles({TenantRole.coach}),
        ]),
      ),
      core: FakeCore(),
    );
    await h.pump(tester);
    await h.go(tester, '/app-admin');
    expect(find.byKey(const Key('app-admin-hub')), findsNothing);
    expect(h.container.read(routerProvider).state.uri.path, '/teams');
  });
}
