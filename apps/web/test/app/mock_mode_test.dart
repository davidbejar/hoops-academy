import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/app.dart';
import 'package:hoops_app/app/feature_modules.dart';
import 'package:hoops_app/core/config/app_config.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/core/storage/preferences.dart';
import 'package:hoops_app/features/tenant/application/tenant_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/harness.dart';

/// Whole stack in dev-mock mode: real Dio + interceptors + generated clients +
/// the in-memory API, no fakes for repositories.
void main() {
  testWidgets('login, pick academy, tenant headers, logo and locale', (tester) async {
    await tester.runAsync(
      () => Future.wait(featureModules.values.map((m) => m.load())),
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
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HoopsApp()),
    );
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

    // Switch to Club Norte: PARENT, academy default locale is English.
    await tester.tap(find.byKey(const Key('tenant-chip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenant-$mockTenantBId')));
    await tester.pumpAndSettle();
    expect(navLabel('My players'), findsOneWidget);
    expect(navLabel('Admin'), findsNothing);
    expect(container.read(tenantLogoProvider).value, isNull); // 404 -> initials
  });
}
