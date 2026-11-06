import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/fake_repos.dart';
import '../support/fixtures.dart';
import '../support/harness.dart';

Future<void> _expectLabels(
  WidgetTester tester, {
  required Set<TenantRole> roles,
  bool superAdmin = false,
  required List<String> present,
  required List<String> absent,
}) async {
  final memberships = roles.isEmpty
      ? <TenantMembership>[]
      : [membershipWithRoles(roles)];
  final h = Harness(
    me: FakeMeRepository(userWith(memberships, superAdmin: superAdmin)),
  );
  await h.pump(tester);
  for (final label in present) {
    expect(navLabel(label), findsOneWidget, reason: 'expected $label');
  }
  for (final label in absent) {
    expect(navLabel(label), findsNothing, reason: 'unexpected $label');
  }
}

void main() {
  testWidgets('ADMIN: Admin, Equipos, Partidos, Entrenos, Jugadores', (
    tester,
  ) async {
    await _expectLabels(
      tester,
      roles: {TenantRole.admin},
      present: ['Admin', 'Equipos', 'Partidos', 'Entrenos', 'Jugadores'],
      absent: ['Mis jugadores', 'Yo', 'Plataforma'],
    );
  });

  testWidgets('COACH: Equipos, Partidos, Entrenos, Jugadores', (tester) async {
    await _expectLabels(
      tester,
      roles: {TenantRole.coach},
      present: ['Equipos', 'Partidos', 'Entrenos', 'Jugadores'],
      absent: ['Admin', 'Mis jugadores'],
    );
  });

  testWidgets('ASSISTANT_COACH sees the coach navigation', (tester) async {
    await _expectLabels(
      tester,
      roles: {TenantRole.assistantCoach},
      present: ['Equipos', 'Partidos', 'Entrenos', 'Jugadores'],
      absent: ['Admin'],
    );
  });

  testWidgets('PARENT: Partidos, Entrenos, Mis jugadores', (tester) async {
    await _expectLabels(
      tester,
      roles: {TenantRole.parent},
      present: ['Partidos', 'Entrenos', 'Mis jugadores'],
      absent: ['Equipos', 'Admin', 'Jugadores'],
    );
  });

  testWidgets('PLAYER: Partidos, Entrenos, Yo', (tester) async {
    await _expectLabels(
      tester,
      roles: {TenantRole.player},
      present: ['Partidos', 'Entrenos', 'Yo'],
      absent: ['Equipos', 'Admin', 'Mis jugadores'],
    );
  });

  testWidgets('super_admin without memberships lands on Platform', (
    tester,
  ) async {
    final h = Harness(me: FakeMeRepository(userWith([], superAdmin: true)));
    await h.pump(tester);

    // WP14: the placeholder became the platform console (tenants list, create button).
    expect(find.byKey(const Key('tenant-new')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('tapping a destination opens its (deferred) module screen', (
    tester,
  ) async {
    final h = Harness(
      me: FakeMeRepository(
        userWith([
          membershipWithRoles({TenantRole.admin}),
        ]),
      ),
      core: FakeCore(),
    );
    await h.pump(tester);
    expect(find.byKey(const Key('admin-hub')), findsOneWidget);

    await tester.tap(navLabel('Equipos'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('season-select')), findsOneWidget);
    expect(find.text('No hay equipos en esta temporada'), findsOneWidget);
  });

  testWidgets('wide screens use a navigation rail instead of a bottom bar', (
    tester,
  ) async {
    final h = Harness(
      me: FakeMeRepository(
        userWith([
          membershipWithRoles({TenantRole.admin}),
        ]),
      ),
    );
    await h.pump(tester, size: const Size(1024, 768));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
