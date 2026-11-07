import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/session/session.dart';
import 'package:hoops_app/core/session/session_providers.dart';
import 'package:hoops_app/features/landing/presentation/landing_screen.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

void main() {
  testWidgets('signed-out users land on the landing page (WP70)', (
    tester,
  ) async {
    final h = Harness(
      me: FakeMeRepository(userWith([tenantNorth])),
      signedIn: false,
    );
    await h.pump(tester);

    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('signed-out users opening an app route get the login screen', (
    tester,
  ) async {
    final h = Harness(
      me: FakeMeRepository(userWith([tenantNorth])),
      signedIn: false,
    );
    await h.pump(tester);
    await h.go(tester, '/teams');

    expect(find.byKey(const Key('login-button')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('signing in moves on to the role home', (tester) async {
    final h = Harness(
      me: FakeMeRepository(userWith([tenantNorth])),
      signedIn: false,
    );
    await h.pump(tester);

    await tester.tap(find.byKey(const Key('landing-header-sign-in')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-button')), findsNothing);
    expect(h.container.read(sessionProvider), isA<Ready>());
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('signing out returns to login from the profile', (tester) async {
    final h = Harness(me: FakeMeRepository(userWith([tenantNorth])));
    await h.pump(tester);

    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();
    // The profile page is a lazy list: scroll until the button is built.
    await tester.scrollUntilVisible(
      find.byKey(const Key('sign-out-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-button')), findsOneWidget);
  });

  testWidgets('a session that expires mid-use is sent back to login', (
    tester,
  ) async {
    final h = Harness(me: FakeMeRepository(userWith([tenantNorth])));
    await h.pump(tester);
    expect(find.byType(NavigationBar), findsOneWidget);

    await h.auth.expireSession();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-button')), findsOneWidget);
  });

  testWidgets('a failing /me shows an error with retry, not the app', (
    tester,
  ) async {
    final me = FakeMeRepository(
      userWith([tenantNorth]),
      error: Exception('boom'),
    );
    final h = Harness(me: me);
    await h.pump(tester);

    expect(find.byKey(const Key('retry-button')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    me.error = null;
    await tester.tap(find.byKey(const Key('retry-button')));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
