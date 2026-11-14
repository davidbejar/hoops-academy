// WP18 browser smoke: landing (WP70) -> login -> academy -> matches -> open the live match -> enter one event -> it syncs.
//
//   # mock mode (in-memory core + game API, nothing else needed) - needs chromedriver, see tool/web_smoke.sh
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/journey_smoke_test.dart -d web-server --dart-define=HOOPS_MOCK_API=true
//
//   # real mode (compose stack up, `just seed-users`): only boots against the real Keycloak origin and checks the
//   # login screen. The Keycloak form lives on another page/origin and cannot be driven from inside the app
//   # (the credential half is `tool/keycloak_login_check.sh` and e2e/'s KeycloakUserTokens).
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/journey_smoke_test.dart -d web-server --web-port 5173 \
//     --dart-define=HOOPS_E2E_REAL=true
//
// Without either define the whole file is skipped, so `flutter test integration_test` never runs it by accident.
// "Offline" leg: a page cannot cut its own network, so the test checks the queue path (event stored locally,
// shown as pending/unsynced, then drained by the sync worker); the true offline/reconnect behaviour is covered by
// test/features/match/presentation/match_screens_test.dart ('reconnect: the banner retry syncs the queue') and the
// manual DevTools step in README.md.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/main.dart' as app;
import 'package:integration_test/integration_test.dart';

const _mock = bool.fromEnvironment('HOOPS_MOCK_API');
const _real = bool.fromEnvironment('HOOPS_E2E_REAL');

// Fixture ids of lib/features/match/data/mock_game_api.dart (live match vs Tigres, starter Ana Ruiz).
const _liveMatch = '0190b6a0-0000-7000-8000-00000000c001';
const _starter = 'p-ana';
const _demoTenant = '11111111-1111-4111-8111-111111111111'; // mockTenantAId

/// Pumps frames until [finder] matches or [timeout] passes (the live screen has timers, so no pumpAndSettle).
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets, reason: 'timed out waiting for $finder');
}

Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isEmpty) return;
  }
  expect(finder, findsNothing, reason: 'still present after $timeout: $finder');
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data ?? '';

/// Reads the score behind [key] once it has kept the same value for a full second (the projection has caught up).
Future<int> settledScore(
  WidgetTester tester,
  String key, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  var last = int.parse(_text(tester, key));
  var stableSince = DateTime.now();
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    final now = int.parse(_text(tester, key));
    if (now != last) {
      last = now;
      stableSince = DateTime.now();
    } else if (DateTime.now().difference(stableSince) >=
        const Duration(seconds: 1)) {
      return now;
    }
  }
  return last;
}

Finder _navItem(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NavigationBar || w is NavigationRail),
  matching: find.text(label),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'mock mode: sign in, pick the academy, open the live match, enter an event, it syncs',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // the anonymous root is the landing page (WP70); its sign-in leads to the login screen
      expect(find.byKey(const Key('landing-hero')), findsOneWidget);
      expect(find.byKey(const Key('landing-header-sign-in')), findsOneWidget);
      await tester.tap(find.byKey(const Key('landing-header-sign-in')));
      await tester.pumpAndSettle();

      // login (the mock OIDC port signs in without leaving the page)
      await tester.tap(find.byKey(const Key('login-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('tenant-list')),
        findsOneWidget,
        reason: 'two memberships -> academy switcher',
      );
      await tester.tap(find.text('Academia Demo'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mock-banner')), findsOneWidget);

      // matches module (mock user is ADMIN + COACH, Spanish UI). The shell shows a NavigationBar on phones and a
      // NavigationRail from 720 px (tool/web_smoke.sh drives a phone-sized window, but accept both).
      await tester.tap(_navItem('Partidos'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('match-$_liveMatch')), findsOneWidget);
      await tester.tap(find.byKey(const Key('match-$_liveMatch')));
      await pumpUntil(tester, find.byKey(const Key('court-panel')));

      // enter one event: a made three-pointer by the starter. The court panel renders before the stored events are
      // loaded and projected, so wait for the score to stop changing instead of reading it at once.
      final before = await settledScore(tester, 'score-team');
      await tester.tap(find.byKey(const Key('player-$_starter')));
      await tester.pump(const Duration(milliseconds: 300));
      await pumpUntil(tester, find.byKey(const Key('action-3pt-made')));
      await tester.tap(find.byKey(const Key('action-3pt-made')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        int.parse(_text(tester, 'score-team')),
        before + 3,
        reason: 'the local projection updates at once',
      );

      // the event is stored locally first and then synced: the queue drains and the log shows no pending entry
      await pumpUntilGone(tester, find.byKey(const Key('sync-banner')));
      await tester.tap(find.byKey(const Key('tab-log')));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 200),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(
        find.text('Pendiente'),
        findsNothing,
        reason: 'every own event is acknowledged by the server',
      );

      // training (WP41): the week calendar lists the demo sessions served by the mock athlete API
      await pumpUntil(tester, _navItem('Entrenos'));
      await tester.tap(_navItem('Entrenos'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('week-calendar')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('session-ses-'),
        ),
        findsWidgets,
        reason: 'a week of demo sessions',
      );

      // application admin (WP41, WP99): the mock user is a super admin, so the context switcher lists Application
      // admin next to the academies; its hub opens the academies area
      await tester.tap(find.byKey(const Key('tenant-chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tenant-platform')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('app-admin-hub')), findsOneWidget);
      await tester.tap(find.byKey(const Key('app-admin-academies')));
      await tester.pumpAndSettle();
      expect(
        find.text('Academia Sur'),
        findsWidgets,
        reason: 'the platform lists every demo academy',
      );
      await tester.tap(find.byKey(const Key('tenant-$_demoTenant')));
      await tester.pumpAndSettle();
      expect(find.text('Administradores'), findsWidgets);
    },
    skip: !_mock,
  );

  testWidgets(
    'real mode: boots against the real origin to the landing; sign in shows the login screen without the mock banner',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('landing-hero')), findsOneWidget);
      await tester.tap(find.byKey(const Key('landing-header-sign-in')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login-button')), findsOneWidget);
      expect(find.byKey(const Key('mock-banner')), findsNothing);
    },
    skip: !_real,
  );
}
