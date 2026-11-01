import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/session/session_providers.dart';

import '../support/fixtures.dart';
import '../support/harness.dart';

void main() {
  testWidgets('zero memberships shows the no-access screen', (tester) async {
    final h = Harness(me: FakeMeRepository(userWith([])));
    await h.pump(tester);

    expect(find.byKey(const Key('no-access')), findsOneWidget);
  });

  testWidgets('exactly one membership is auto-selected, no switcher', (tester) async {
    final h = Harness(me: FakeMeRepository(userWith([tenantNorth])));
    await h.pump(tester);

    expect(find.byKey(const Key('tenant-list')), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(h.container.read(activeTenantIdProvider), tenantNorth.tenantId);
  });

  testWidgets('several memberships list every academy with its roles', (tester) async {
    final h = Harness(me: FakeMeRepository(userWith([tenantNorth, tenantSouth])));
    await h.pump(tester);

    expect(find.byKey(const Key('tenant-list')), findsOneWidget);
    expect(find.text('Club Norte'), findsOneWidget);
    expect(find.text('Academia Sur'), findsOneWidget);
    expect(find.textContaining('Administrador'), findsOneWidget);
    expect(find.textContaining('Familia'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('choosing an academy persists it and opens the role home', (tester) async {
    final h = Harness(me: FakeMeRepository(userWith([tenantNorth, tenantSouth])));
    await h.pump(tester);

    await tester.tap(find.byKey(Key('tenant-${tenantSouth.tenantId}')));
    await tester.pumpAndSettle();

    expect(h.prefs.getString('hoops.selectedTenantId'), tenantSouth.tenantId);
    expect(h.container.read(activeTenantIdProvider), tenantSouth.tenantId);
    // PARENT: Matches, Training, My players
    expect(navLabel('Partidos'), findsOneWidget);
    expect(navLabel('Mis jugadores'), findsOneWidget);
  });

  testWidgets('a stored selection is restored on the next visit', (tester) async {
    final h = Harness(
      me: FakeMeRepository(userWith([tenantNorth, tenantSouth])),
      prefs: {'hoops.selectedTenantId': tenantNorth.tenantId},
    );
    await h.pump(tester);

    expect(find.byKey(const Key('tenant-list')), findsNothing);
    expect(h.container.read(activeTenantIdProvider), tenantNorth.tenantId);
  });

  testWidgets('a stored selection that is no longer a membership asks again', (tester) async {
    final h = Harness(
      me: FakeMeRepository(userWith([tenantNorth, tenantSouth])),
      prefs: {'hoops.selectedTenantId': 'gone'},
    );
    await h.pump(tester);

    expect(find.byKey(const Key('tenant-list')), findsOneWidget);
  });

  testWidgets('the app bar chip switches academy when there are several', (tester) async {
    final h = Harness(
      me: FakeMeRepository(userWith([tenantNorth, tenantSouth])),
      prefs: {'hoops.selectedTenantId': tenantNorth.tenantId},
    );
    await h.pump(tester);

    await tester.tap(find.byKey(const Key('tenant-chip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tenant-list')), findsOneWidget);
  });

  testWidgets('the app bar shows the academy name and initials without a logo', (tester) async {
    final h = Harness(me: FakeMeRepository(userWith([tenantNorth])));
    await h.pump(tester);

    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Club Norte')), findsOneWidget);
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('CN')), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
