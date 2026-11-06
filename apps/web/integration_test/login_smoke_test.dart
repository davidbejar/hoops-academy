// Login smoke test, run in Chrome through `flutter drive` (needs chromedriver):
//
//   # mock mode: full UI flow, no backend needed
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/login_smoke_test.dart -d chrome \
//     --dart-define=HOOPS_MOCK_API=true
//
//   # real Keycloak (compose stack up, `just seed-users` done): boots, reaches the
//   # login screen and starts the PKCE redirect. The Keycloak form is another
//   # page/origin, which an in-page integration test cannot drive; the credential
//   # part is covered by `tool/keycloak_login_check.sh` (coach1@hoops-academy.com, HOOPS_E2E_PASSWORD)
//   # and the manual check in README.md.
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/login_smoke_test.dart -d chrome --web-port 5173
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/main.dart' as app;
import 'package:integration_test/integration_test.dart';

const _mock = bool.fromEnvironment('HOOPS_MOCK_API');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots to the landing; its sign-in shows the login screen', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('landing-hero')), findsOneWidget);
    await tester.tap(find.byKey(const Key('landing-header-sign-in')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-button')), findsOneWidget);
  });

  testWidgets('mock mode: sign in, pick an academy, land on the role home', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('landing-header-sign-in')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    // Two memberships in the fixture -> academy switcher first.
    expect(find.byKey(const Key('tenant-list')), findsOneWidget);
    await tester.tap(find.text('Academia Demo'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('module-admin')), findsOneWidget);
  }, skip: !_mock);
}
