import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/app.dart';
import 'package:hoops_app/app/feature_modules.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/core/config/app_config.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/core/storage/preferences.dart';
import 'package:hoops_app/features/match/application/match_providers.dart';
import 'package:hoops_app/features/match/data/local/match_database.dart';
import 'package:hoops_app/features/match/data/local/match_store.dart';
import 'package:hoops_app/features/match/data/mock_game_api.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/match/presentation/match_screens_test.dart'
    show coreWithTeam, gameWith, seasonStatsFixture;
import '../support/fake_game.dart' show teamA;
import '../support/pump_helpers.dart';

/// Match screens of WP74 (ADR-0040). Regenerate with
/// `flutter test --update-goldens test/golden/live_match_golden_test.dart`.
///
/// The live match, its stat sheet and the final box score come from the demo
/// mock (the whole app in mock mode, signed in as the demo coach, like the
/// landing's `live_match.png`). The match list, the season statistics and the
/// setup show dates or need a scheduled match the mock derives from today, so
/// they use the fixed fixtures of the widget tests.
void main() {
  const phone = Size(360, 780);
  const desktop = Size(1024, 768);

  void brightness(WidgetTester tester, Brightness value) {
    tester.platformDispatcher.platformBrightnessTestValue = value;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }

  Future<void> golden(String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/match/$name.png'),
  );

  group('demo mock', () {
    for (final (size, dark, name) in [
      (phone, false, 'live_match_360x780'),
      (phone, true, 'live_match_360x780_dark'),
      (desktop, false, 'live_match_1024x768'),
      (desktop, true, 'live_match_1024x768_dark'),
    ]) {
      testWidgets('live match, demo coach, $name', (tester) async {
        if (dark) brightness(tester, Brightness.dark);
        final app = await _MockApp.signIn(tester, size);
        await app.go('/matches/${MockGameApi.liveMatchId}');
        await golden(name);
        await app.close();
      });
    }

    testWidgets('stat sheet of an on-court player, light and dark', (
      tester,
    ) async {
      final app = await _MockApp.signIn(tester, phone);
      await app.go('/matches/${MockGameApi.liveMatchId}');
      await tester.tap(find.byKey(const Key('player-p-ana')));
      await tester.pumpAndSettle();
      await golden('live_match_stat_sheet_360x780');
      brightness(tester, Brightness.dark);
      await tester.pumpAndSettle();
      await golden('live_match_stat_sheet_360x780_dark');
      await app.close();
    });

    testWidgets('final box score, light and dark', (tester) async {
      final app = await _MockApp.signIn(tester, phone);
      await app.go('/matches/${MockGameApi.finishedMatchId}');
      await golden('box_score_360x780');
      brightness(tester, Brightness.dark);
      await tester.pumpAndSettle();
      await golden('box_score_360x780_dark');
      await app.close();
    });
  });

  group('fixtures', () {
    Future<void> pumpCoach(
      WidgetTester tester,
      String location, {
      Size size = phone,
    }) async {
      final game = gameWith();
      game.matches.seasonStatsResult = seasonStatsFixture();
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        staffTeamIds: {teamA},
        core: coreWithTeam(),
        game: game,
        location: location,
        size: size,
      );
    }

    for (final (size, dark, name) in [
      (phone, false, 'match_list_360x780'),
      (phone, true, 'match_list_360x780_dark'),
      (desktop, false, 'match_list_1024x768'),
    ]) {
      testWidgets('match list, coach, $name', (tester) async {
        if (dark) brightness(tester, Brightness.dark);
        await pumpCoach(tester, '/matches', size: size);
        await golden(name);
      });
    }

    for (final (dark, name) in [
      (false, 'season_stats_360x780'),
      (true, 'season_stats_360x780_dark'),
    ]) {
      testWidgets('season statistics, $name', (tester) async {
        if (dark) brightness(tester, Brightness.dark);
        await pumpCoach(tester, '/matches/stats/p1');
        await golden(name);
      });
    }

    testWidgets('match setup, 360x780', (tester) async {
      await pumpCoach(tester, '/matches/m-sched/setup');
      await golden('match_setup_360x780');
    });
  });
}

/// The whole app in mock mode (in-memory APIs, the data of `lib/core/mock`),
/// signed in to Academia Demo as the demo user (ADMIN + COACH), Spanish UI.
class _MockApp {
  _MockApp(this.tester, this.container);

  final WidgetTester tester;
  final ProviderContainer container;

  static Future<_MockApp> signIn(WidgetTester tester, Size size) async {
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
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HoopsApp()),
    );
    await tester.pumpAndSettle();
    final app = _MockApp(tester, container);
    await app.go('/login');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tenant-$mockTenantAId')));
    await tester.pumpAndSettle();
    return app;
  }

  Future<void> go(String location) async {
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
    // The match loads from the in-memory store and the mock in real async.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  /// Leaves the match so its timers stop, then disposes the app (the sync
  /// worker's timers stop with the container).
  Future<void> close() async {
    container.read(routerProvider).go('/training');
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(minutes: 1));
  }
}
