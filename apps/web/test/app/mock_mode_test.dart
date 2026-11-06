import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/app.dart';
import 'package:hoops_app/app/feature_modules.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/core/config/app_config.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/core/storage/preferences.dart';
import 'package:hoops_app/core/ui/list_row.dart';
import 'package:hoops_app/features/match/application/match_providers.dart';
import 'package:hoops_app/features/match/data/local/match_database.dart';
import 'package:hoops_app/features/match/data/local/match_store.dart';
import 'package:hoops_app/features/tenant/application/tenant_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/harness.dart';

/// Whole stack in dev-mock mode: real Dio + interceptors + generated clients +
/// the in-memory API, no fakes for repositories.
void main() {
  testWidgets('login, pick academy, tenant headers, logo and locale', (
    tester,
  ) async {
    await tester.runAsync(
      () => Future.wait([
        for (final m in featureModules.values) ...[
          m.load(),
          for (final sub in m.subPages) sub.load(),
        ],
      ]),
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // The Norte parent lands on the match list, which caches the matches in the local store.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final store = MatchStore(
      MatchDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      ),
    );
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        matchStoreProvider.overrideWithValue(store),
        appConfigProvider.overrideWithValue(
          AppConfig(
            issuer: Uri.parse('http://unused'),
            clientId: 'web',
            apiBase: 'http://mock.local',
            mockApi: true,
            scopes: const ['openid'],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HoopsApp()),
    );
    await tester.pumpAndSettle();
    // Anonymous root: the landing page (WP70); its header leads to the login.
    await tester.tap(find.byKey(const Key('landing-header-sign-in')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    // Two memberships in the fixture: the switcher is shown.
    expect(find.byKey(const Key('tenant-list')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tenant-$mockTenantAId')));
    await tester.pumpAndSettle();

    // Academia Demo: ADMIN + COACH -> admin navigation, Spanish default.
    expect(navLabel('Admin'), findsOneWidget);
    expect(navLabel('Equipos'), findsOneWidget);
    // The mock rejects tenant calls without X-Tenant-Id, so a profile and a
    // logo prove the header interceptor works through the generated client.
    expect(container.read(tenantProfileProvider).value?.name, 'Academia Demo');
    expect(container.read(tenantLogoProvider).value, isNotEmpty);
    expect(
      container.read(tenantZoneProvider).label,
      'Europe/Madrid',
    ); // from /me, not the profile

    // The demo data behind the admin / roster screens (real generated client).
    await tester.tap(navLabel('Equipos'));
    await tester.pumpAndSettle();
    expect(find.text('Mini A (Leones)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('team-team-mini-a')));
    await tester.pumpAndSettle();
    expect(find.text('Ana Ruiz'), findsOneWidget);
    expect(find.text('Tomás Entrenador'), findsOneWidget);

    // Switch to Club Norte: PARENT, academy default locale is English.
    await tester.tap(find.byKey(const Key('tenant-chip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenant-$mockTenantBId')));
    await tester.pumpAndSettle();
    expect(navLabel('My players'), findsOneWidget);
    expect(navLabel('Admin'), findsNothing);
    expect(container.read(tenantLogoProvider).value, isNull); // 404 -> initials

    // WP47: Club Norte has its own training week and health data, the PARENT's hub shows the linked player.
    container.read(routerProvider).go('/training');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('week-calendar')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith(
              'session-ses-sch-norte',
            ),
      ),
      findsWidgets,
    );
    container.read(routerProvider).go('/my-players');
    await tester.pumpAndSettle();
    expect(find.text('Nora Vega'), findsWidgets);
    expect(find.text('Upcoming training'), findsWidgets);
    expect(find.text('Health and fitness'), findsWidgets);
  });

  testWidgets(
    'WP41: the platform console and the training / health screens show the demo data',
    (tester) async {
      await tester.runAsync(
        () => Future.wait([
          for (final m in featureModules.values) ...[
            m.load(),
            for (final sub in m.subPages) sub.load(),
          ],
        ]),
      );
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appConfigProvider.overrideWithValue(
            AppConfig(
              issuer: Uri.parse('http://unused'),
              clientId: 'web',
              apiBase: 'http://mock.local',
              mockApi: true,
              scopes: const ['openid'],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HoopsApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('landing-header-sign-in')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('login-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tenant-$mockTenantAId')));
      await tester.pumpAndSettle();

      Future<void> go(String location) async {
        container.read(routerProvider).go(location);
        await tester.pumpAndSettle();
      }

      Finder keyed(String prefix) => find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith(prefix),
      );

      await go('/training');
      expect(find.byKey(const Key('week-calendar')), findsOneWidget);
      expect(keyed('session-ses-'), findsWidgets);

      await go('/training/plans');
      expect(find.text('Calentamiento Mini'), findsWidgets);
      await go('/training/absences');
      expect(find.textContaining('Torneo de ajedrez'), findsWidgets);
      await go('/training/assignments');
      expect(find.byType(Card), findsWidgets);

      await go('/players/p-leo/health');
      expect(find.textContaining('rodilla izquierda'), findsWidgets);
      await go('/players/tests');
      expect(find.textContaining('Sprint 20 m'), findsWidgets);
      await go('/players/norms');
      expect(keyed('norm-nm-'), findsWidgets);

      // the platform console, reached as the demo user is a super admin
      await go('/platform');
      expect(find.text('Academia Demo'), findsWidgets);
      expect(find.text('Academia Sur'), findsWidgets);
      await go('/platform/$mockTenantAId');
      await tester.scrollUntilVisible(
        find.byKey(const Key('usage-trend')),
        300,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('usage-trend-error')), findsNothing);
      expect(find.byKey(const Key('usage-trend')), findsOneWidget);
      await go('/platform/activity');
      expect(find.byType(ListRow), findsWidgets);
    },
  );
}
