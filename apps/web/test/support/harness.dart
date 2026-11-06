import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/app.dart';
import 'package:hoops_app/app/feature_modules.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/core/auth/auth_providers.dart';
import 'package:hoops_app/core/auth/auth_service.dart';
import 'package:hoops_app/core/auth/mock_auth_service.dart';
import 'package:hoops_app/core/connectivity/connectivity_providers.dart';
import 'package:hoops_app/core/storage/preferences.dart';
import 'package:hoops_app/core/ui/deferred_screen.dart';
import 'package:hoops_app/features/admin/application/admin_providers.dart';
import 'package:hoops_app/features/me/application/me_providers.dart';
import 'package:hoops_app/features/roster/application/roster_providers.dart';
import 'package:hoops_app/features/me/data/me_repository.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/tenant/application/tenant_providers.dart';
import 'package:hoops_app/features/tenant/data/tenant_repository.dart';
import 'package:hoops_app/features/tenant/domain/tenant_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_athlete.dart';
import 'fake_game.dart';
import 'fake_platform.dart';
import 'fake_repos.dart';

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

  /// `revalidate` flag of every logo fetch (cache-busting checks).
  final List<bool> logoFetches = [];

  @override
  Future<TenantProfile> profile(String tenantId) async => TenantProfile(
    id: tenantId,
    name: 'profile-$tenantId',
    defaultLocaleCode: defaultLocale,
    hasLogo: logoBytes != null,
  );

  @override
  Future<Uint8List?> logo(String tenantId, {bool revalidate = false}) async {
    logoFetches.add(revalidate);
    return logoBytes;
  }
}

class Harness {
  Harness({
    required this.me,
    AuthService? auth,
    FakeTenantRepository? tenant,
    Map<String, Object> prefs = const {},
    bool signedIn = true,
    this.core,
    FakeGame? game,
    FakeAthlete? athlete,
    FakePlatform? platform,
    this.extraOverrides = const [],
  }) : game = game ?? FakeGame(),
       athlete = athlete ?? FakeAthlete(),
       platform = platform ?? FakePlatform(),
       auth =
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

  /// In-memory admin / roster repositories (null: not needed by the test).
  final FakeCore? core;

  /// In-memory game side (matches, events, Drift store); empty by default so
  /// every screen that opens the match module works without a backend.
  final FakeGame game;

  /// In-memory athlete-service side (training, plans, health, fitness).
  final FakeAthlete athlete;

  /// In-memory platform console repository.
  final FakePlatform platform;
  final List<Override> extraOverrides;
  final online = StreamController<bool>.broadcast();
  late SharedPreferences prefs;
  late ProviderContainer container;

  /// Navigates the real router (guard included) to [location] and settles.
  Future<void> go(WidgetTester tester, String location) async {
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }

  /// Like [go] but only pumps frames (for screens that never settle, e.g.
  /// while a spinner is shown).
  Future<void> goAndPump(WidgetTester tester, String location) async {
    container.read(routerProvider).go(location);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

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
      () => Future.wait([
        for (final m in featureModules.values) ...[
          m.load(),
          for (final sub in m.subPages) sub.load(),
        ],
      ]),
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
        if (core != null) ...[
          academyRepositoryProvider.overrideWithValue(core!.academy),
          membersRepositoryProvider.overrideWithValue(core!.members),
          seasonsRepositoryProvider.overrideWithValue(core!.seasons),
          ageCategoriesRepositoryProvider.overrideWithValue(core!.categories),
          teamsRepositoryProvider.overrideWithValue(core!.teams),
          playersRepositoryProvider.overrideWithValue(core!.players),
          approvalsRepositoryProvider.overrideWithValue(core!.approvals),
          casesRepositoryProvider.overrideWithValue(core!.cases),
        ],
        ...game.overrides,
        ...athlete.overrides,
        ...platform.overrides,
        ...extraOverrides,
        // Deferred libraries load in real time; make them instant in tests.
        libraryLoaderProvider.overrideWithValue(
          (_) => SynchronousFuture<void>(null),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HoopsApp()),
    );
    await tester.pumpAndSettle();
  }
}

Finder navLabel(String text) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NavigationBar || w is NavigationRail),
  matching: find.text(text),
);
