import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/http/request_context.dart';
import 'package:hoops_app/core/session/session.dart';
import 'package:hoops_app/core/session/session_providers.dart';
import 'package:hoops_app/core/tenancy/tenant_selection.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/fake_academy_requests.dart';
import '../support/fixtures.dart';
import '../support/harness.dart';

/// Contexts and landing (WP99, decisions 71 and 73): the academies of the
/// login plus "Application admin" for a super admin, each with its own menu.
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

String _path(Harness h) => h.container.read(routerProvider).state.uri.path;

Future<void> _openSwitcher(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('tenant-chip')));
  await tester.pumpAndSettle();
}

void main() {
  group('landing', () {
    testWidgets('a super admin without academies lands on the hub', (
      tester,
    ) async {
      final h = Harness(me: FakeMeRepository(userWith([], superAdmin: true)));
      await h.pump(tester);

      expect(_path(h), '/app-admin');
      expect(find.byKey(const Key('app-admin-hub')), findsOneWidget);
      expect(h.container.read(activeTenantIdProvider), isNull);
      // Nothing to switch to: the chip is plain, no switcher.
      await tester.tap(find.byKey(const Key('tenant-chip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('context-switcher')), findsNothing);
    });

    // Step 1 of WP99: the owner reports landing on the audit trail after
    // signing in as the super admin. No path through the router leads there:
    // whatever the browser held (a deep link to the audit trail, the sign-in
    // page, the splash), a super admin without academies ends on the hub.
    for (final start in [
      '/platform/activity',
      '/app-admin/activity',
      '/login',
      '/splash',
      '/',
    ]) {
      testWidgets('a cold start at $start still lands on the hub', (
        tester,
      ) async {
        tester.binding.platformDispatcher.defaultRouteNameTestValue = start;
        addTearDown(
          tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
        );
        final h = Harness(me: FakeMeRepository(userWith([], superAdmin: true)));
        await h.pump(tester);

        expect(_path(h), '/app-admin');
      });
    }

    testWidgets('signing in from the landing page opens the hub', (
      tester,
    ) async {
      final h = Harness(
        me: FakeMeRepository(userWith([], superAdmin: true)),
        signedIn: false,
      );
      await h.pump(tester);
      await tester.tap(find.byKey(const Key('landing-header-sign-in')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('login-button')));
      await tester.pumpAndSettle();

      expect(_path(h), '/app-admin');
    });

    testWidgets('a login with exactly one context lands in it', (tester) async {
      final h = Harness(me: FakeMeRepository(userWith([_hangtuah])));
      await h.pump(tester);

      expect(_path(h), '/admin');
      expect(h.container.read(activeTenantIdProvider), _hangtuah.tenantId);
    });

    testWidgets('several contexts and none remembered: the switcher', (
      tester,
    ) async {
      final h = Harness(
        me: FakeMeRepository(userWith([_hangtuah, _dewa, _baskonia])),
      );
      await h.pump(tester);

      expect(_path(h), '/tenants');
      for (final m in [_hangtuah, _dewa, _baskonia]) {
        expect(find.byKey(Key('tenant-${m.tenantId}')), findsOneWidget);
      }
      expect(find.byKey(const Key('tenant-platform')), findsNothing);
    });

    testWidgets('the last used context is entered, an academy', (tester) async {
      final h = Harness(
        me: FakeMeRepository(
          userWith([_hangtuah, _dewa, _baskonia], superAdmin: true),
        ),
        prefs: {'hoops.selectedTenantId': _dewa.tenantId},
      );
      await h.pump(tester);

      expect(h.container.read(activeTenantIdProvider), _dewa.tenantId);
      expect(_path(h), '/admin');
    });

    testWidgets('the last used context is entered, Application admin', (
      tester,
    ) async {
      final h = Harness(
        me: FakeMeRepository(userWith([_hangtuah, _dewa], superAdmin: true)),
        prefs: {'hoops.selectedTenantId': 'platform'},
      );
      await h.pump(tester);

      expect(_path(h), '/app-admin');
      expect(h.container.read(activeTenantIdProvider), isNull);
    });

    testWidgets('a remembered context that is gone is ignored', (tester) async {
      final h = Harness(
        me: FakeMeRepository(userWith([_hangtuah, _dewa])),
        // "platform" remembered by someone who is no longer a super admin.
        prefs: {'hoops.selectedTenantId': 'platform'},
      );
      await h.pump(tester);

      expect(_path(h), '/tenants');
    });

    testWidgets('a super admin who is also a member of one academy chooses', (
      tester,
    ) async {
      final h = Harness(
        me: FakeMeRepository(userWith([_hangtuah], superAdmin: true)),
      );
      await h.pump(tester);

      expect(_path(h), '/tenants');
      expect(find.byKey(const Key('tenant-platform')), findsOneWidget);
      expect(find.byKey(Key('tenant-${_hangtuah.tenantId}')), findsOneWidget);
    });
  });

  group('a super admin who is also a member of two academies', () {
    Future<Harness> pump(WidgetTester tester, {Size? size}) async {
      final h = Harness(
        me: FakeMeRepository(
          userWith([_hangtuah, _baskonia], superAdmin: true),
        ),
      );
      await h.pump(tester, size: size ?? const Size(360, 780));
      return h;
    }

    testWidgets('the chooser lists Application admin and both academies', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Administración de la aplicación'), findsOneWidget);
      expect(find.text('Super administrador'), findsOneWidget);
      expect(find.text('Hangtuah'), findsOneWidget);
      expect(find.text('Administrador'), findsOneWidget);
      expect(find.text('Baskonia'), findsOneWidget);
      expect(find.text('Entrenador'), findsOneWidget);
    });

    testWidgets('choosing Application admin: its menu, no tenant header, '
        'remembered', (tester) async {
      final h = await pump(tester);

      await tester.tap(find.byKey(const Key('tenant-platform')));
      await tester.pumpAndSettle();

      expect(_path(h), '/app-admin');
      expect(navLabel('Academias'), findsOneWidget);
      expect(navLabel('Equipos'), findsNothing);
      expect(h.container.read(activeTenantIdProvider), isNull);
      expect(h.prefs.getString('hoops.selectedTenantId'), 'platform');
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Administración de la aplicación'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('choosing an academy: its menu and its tenant header', (
      tester,
    ) async {
      final h = await pump(tester);

      await tester.tap(find.byKey(Key('tenant-${_baskonia.tenantId}')));
      await tester.pumpAndSettle();

      expect(_path(h), '/teams');
      expect(navLabel('Equipos'), findsOneWidget);
      expect(navLabel('Academias'), findsNothing);
      expect(h.container.read(activeTenantIdProvider), _baskonia.tenantId);
    });

    testWidgets('the switcher moves between contexts and lands on each home', (
      tester,
    ) async {
      final h = await pump(tester);
      await tester.tap(find.byKey(Key('tenant-${_hangtuah.tenantId}')));
      await tester.pumpAndSettle();
      expect(_path(h), '/admin');

      await _openSwitcher(tester);
      expect(find.byKey(const Key('context-switcher')), findsOneWidget);
      await tester.tap(find.byKey(const Key('tenant-platform')));
      await tester.pumpAndSettle();
      expect(_path(h), '/app-admin');
      expect(find.byKey(const Key('context-switcher')), findsNothing);

      await _openSwitcher(tester);
      await tester.tap(find.byKey(Key('tenant-${_baskonia.tenantId}')));
      await tester.pumpAndSettle();
      expect(_path(h), '/teams');
      expect(h.container.read(activeTenantIdProvider), _baskonia.tenantId);
    });

    testWidgets('the switcher marks the active context', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(Key('tenant-${_hangtuah.tenantId}')));
      await tester.pumpAndSettle();

      await _openSwitcher(tester);

      Finder check(String id) => find.descendant(
        of: find.byKey(Key('tenant-$id')),
        matching: find.byIcon(Icons.check_circle),
      );
      expect(check(_hangtuah.tenantId), findsOneWidget);
      expect(check('platform'), findsNothing);
      expect(check(_baskonia.tenantId), findsNothing);
    });

    testWidgets('wide screens: a panel beside the rail, not a sheet', (
      tester,
    ) async {
      final h = await pump(tester, size: const Size(1024, 768));
      await tester.tap(find.byKey(Key('tenant-${_hangtuah.tenantId}')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('rail-context')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('context-panel')), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      await tester.tap(find.byKey(const Key('tenant-platform')));
      await tester.pumpAndSettle();
      expect(_path(h), '/app-admin');
    });

    testWidgets('leaving the application admin from one of its screens does '
        'not bounce back', (tester) async {
      final h = await pump(tester);
      await tester.tap(find.byKey(const Key('tenant-platform')));
      await tester.pumpAndSettle();
      await h.go(tester, '/app-admin/users');

      await _openSwitcher(tester);
      await tester.tap(find.byKey(Key('tenant-${_hangtuah.tenantId}')));
      await tester.pumpAndSettle();

      expect(_path(h), '/admin');
      expect(h.container.read(activeTenantIdProvider), _hangtuah.tenantId);
      expect(h.prefs.getString('hoops.selectedTenantId'), _hangtuah.tenantId);
    });

    testWidgets('a link to the application admin enters that context', (
      tester,
    ) async {
      final h = await pump(tester);
      await tester.tap(find.byKey(Key('tenant-${_hangtuah.tenantId}')));
      await tester.pumpAndSettle();

      await h.go(tester, '/platform/requests');

      expect(_path(h), '/app-admin/requests');
      expect(h.container.read(activeTenantIdProvider), isNull);
      expect(h.prefs.getString('hoops.selectedTenantId'), 'platform');
    });
  });

  testWidgets('a plain member is not let into the application admin', (
    tester,
  ) async {
    final h = Harness(me: FakeMeRepository(userWith([_baskonia])));
    await h.pump(tester);

    await h.go(tester, '/app-admin');

    expect(_path(h), '/teams');
    expect(h.container.read(selectedTenantIdProvider), isNot('platform'));
  });

  testWidgets('signing out forgets the remembered context', (tester) async {
    final h = Harness(
      me: FakeMeRepository(userWith([_hangtuah], superAdmin: true)),
      prefs: {'hoops.selectedTenantId': 'platform'},
    );
    await h.pump(tester);
    expect(h.container.read(sessionProvider), isA<Ready>());

    await h.container.read(selectedTenantIdProvider.notifier).clear();

    expect(h.container.read(sessionProvider), isA<NeedsTenant>());
    expect(h.container.read(requestContextProvider).tenantId, isNull);
  });

  group('pending approvals', () {
    testWidgets('the count is a badge on the hub and in the navigation', (
      tester,
    ) async {
      final h = Harness(
        me: FakeMeRepository(userWith([], superAdmin: true)),
        academyRequests: FakeAcademyRequestRepository([
          academyRequestOf('r-1', 'Escuela Valle'),
          academyRequestOf('r-2', 'Hoops Bali'),
          academyRequestOf(
            'r-3',
            'Ya aceptada',
            status: api.AcademyRequestStatus.ACCEPTED,
            tenantId: 't',
          ),
        ]),
      );
      await h.pump(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key('app-admin-requests-badge')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('nav-requests-badge')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('no pending request: no badge', (tester) async {
      final h = Harness(me: FakeMeRepository(userWith([], superAdmin: true)));
      await h.pump(tester);

      expect(find.byKey(const Key('app-admin-requests-badge')), findsNothing);
      expect(find.byKey(const Key('nav-requests-badge')), findsNothing);
    });

    testWidgets('an academy menu never asks for them', (tester) async {
      final requests = FakeAcademyRequestRepository();
      final h = Harness(
        me: FakeMeRepository(userWith([_hangtuah], superAdmin: true)),
        prefs: {'hoops.selectedTenantId': _hangtuah.tenantId},
        academyRequests: requests,
      );
      await h.pump(tester);

      expect(requests.calls, isEmpty);
    });
  });
}
