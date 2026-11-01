import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/app.dart';
import 'package:hoops_app/app/feature_modules.dart';
import 'package:hoops_app/core/auth/auth_providers.dart';
import 'package:hoops_app/core/auth/auth_service.dart';
import 'package:hoops_app/core/auth/mock_auth_service.dart';
import 'package:hoops_app/core/connectivity/connectivity_providers.dart';
import 'package:hoops_app/core/storage/preferences.dart';
import 'package:hoops_app/core/ui/deferred_screen.dart';
import 'package:hoops_app/features/me/application/me_providers.dart';
import 'package:hoops_app/features/me/data/me_repository.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/tenant/application/tenant_providers.dart';
import 'package:hoops_app/features/tenant/data/tenant_repository.dart';
import 'package:hoops_app/features/tenant/domain/tenant_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeMeRepository implements MeRepository {
  FakeMeRepository(this.user, {this.error});
  CurrentUser user;
  Object? error;
  final List<String> localeUpdates = [];

  @override
  Future<CurrentUser> fetch() async {
    if (error != null) throw error!;
    return user;
  }

  @override
  Future<void> updateLocale(String localeCode) async =>
      localeUpdates.add(localeCode);
}

class FakeTenantRepository implements TenantRepository {
  FakeTenantRepository({this.defaultLocale = 'es', this.logoBytes});
  final String defaultLocale;
  final Uint8List? logoBytes;

  @override
  Future<TenantProfile> profile(String tenantId) async => TenantProfile(
    id: tenantId,
    name: 'profile-$tenantId',
    defaultLocaleCode: defaultLocale,
    hasLogo: logoBytes != null,
  );

  @override
  Future<Uint8List?> logo(String tenantId) async => logoBytes;
}

class Harness {
  Harness({
    required this.me,
    AuthService? auth,
    FakeTenantRepository? tenant,
    Map<String, Object> prefs = const {},
    bool signedIn = true,
  }) : auth =
           auth ??
           MockAuthService(
             initial: signedIn
                 ? AuthStatus.authenticated
                 : AuthStatus.unauthenticated,
           ),
       tenant = tenant ?? FakeTenantRepository(),
       initialPrefs = prefs;

  final FakeMeRepository me;
  final AuthService auth;
  final FakeTenantRepository tenant;
  final Map<String, Object> initialPrefs;
  final online = StreamController<bool>.broadcast();
  late SharedPreferences prefs;
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(360, 780),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(online.close);

    await tester.runAsync(
      () => Future.wait(featureModules.values.map((m) => m.load())),
    );
    SharedPreferences.setMockInitialValues(initialPrefs);
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(auth),
        meRepositoryProvider.overrideWithValue(me),
        tenantRepositoryProvider.overrideWithValue(tenant),
        onlineProvider.overrideWith((ref) => online.stream),
        // Deferred libraries load in real time; make them instant in tests.
        libraryLoaderProvider.overrideWithValue((_) => SynchronousFuture<void>(null)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HoopsApp(),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Finder navLabel(String text) => find.descendant(
  of: find.byWidgetPredicate(
    (w) => w is NavigationBar || w is NavigationRail,
  ),
  matching: find.text(text),
);
