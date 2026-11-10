import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/app/router.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/session/session.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/fake_athlete.dart';
import '../../support/fixtures.dart';
import '../../support/pump_helpers.dart';

FakeAthlete _athlete() {
  final plans = FakePlansRepository(
    plans: [
      planOf(
        'plan-1',
        'Tiro básico',
        items: [planItem('i1', 'Calentamiento', 0, minutes: 10)],
      ),
    ],
  );
  plans.assignmentList.add(
    assignmentOf('as-p1', plans.planList.single, playerId: 'p1'),
  );
  plans.assignmentList.add(
    assignmentOf('as-p2', plans.planList.single, playerId: 'p2'),
  );
  plans.completionList.add(
    completionOf(
      'c1',
      'as-p1',
      'p1',
      ath.CompletionStatus.DONE,
      comment: 'Todo bien',
    ),
  );
  return FakeAthlete(
    training: FakeTrainingRepository(
      sessions: [
        session('s1', day: DateTime.now().add(const Duration(days: 1))),
        session(
          's-t2',
          teamId: 't2',
          day: DateTime.now().add(const Duration(days: 2)),
        ),
        session(
          's-old',
          day: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ],
    ),
    plans: plans,
    health: FakeHealthRepository(
      injuries: [injury('inj-1', 'p1', part: 'Rodilla')],
    ),
  );
}

void main() {
  group('Me (PLAYER)', () {
    testWidgets(
      'shows name, season stats link, upcoming trainings of the own team only',
      (tester) async {
        final h = await pumpAs(
          tester,
          roles: {TenantRole.player},
          ownPlayerId: 'p1',
          core: athleteCore(),
          athlete: _athlete(),
          location: '/me',
          size: const Size(360, 1200),
        );
        expect(find.text('Ana Ruiz'), findsOneWidget);
        expect(find.byKey(const Key('session-s1')), findsOneWidget);
        expect(find.byKey(const Key('session-s-t2')), findsNothing);
        expect(find.byKey(const Key('session-s-old')), findsNothing);
        await tapKey(tester, 'hub-season-stats');
        expect(
          h.container.read(routerProvider).state.uri.path,
          '/matches/stats/p1',
        );
      },
    );

    testWidgets(
      'plans tab shows assignments with the completion mark and comment',
      (tester) async {
        await pumpAs(
          tester,
          roles: {TenantRole.player},
          ownPlayerId: 'p1',
          core: athleteCore(),
          athlete: _athlete(),
          location: '/me',
          size: const Size(360, 1200),
        );
        await tapKey(tester, 'hub-tab-plans');
        expect(find.byKey(const Key('hub-assignment-as-p1')), findsOneWidget);
        expect(
          find.byKey(const Key('hub-assignment-as-p2')),
          findsNothing,
          reason: 'the fake filters other players',
        );
        expect(find.text('Todo bien'), findsOneWidget);
        expect(
          tester
              .widget<ChoiceChip>(find.byKey(const Key('comp-as-p1-p1-DONE')))
              .selected,
          isTrue,
        );
      },
    );

    testWidgets('health tab: injuries, growth and tests are reachable', (
      tester,
    ) async {
      await pumpAs(
        tester,
        roles: {TenantRole.player},
        ownPlayerId: 'p1',
        core: athleteCore(),
        athlete: _athlete(),
        location: '/me',
        size: const Size(360, 1600),
      );
      await tapKey(tester, 'hub-tab-health');
      expect(find.text('Rodilla'), findsOneWidget);
      await tapKey(tester, 'health-tab-growth');
      expect(find.text('Sin medidas todavía'), findsOneWidget);
      await tapKey(tester, 'health-tab-tests');
      expect(find.text('Sin resultados de pruebas'), findsOneWidget);
    });

    testWidgets('player without a linked player id', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.player},
        core: athleteCore(),
        athlete: _athlete(),
        location: '/me',
      );
      expect(
        find.text('Tu cuenta aún no está vinculada a un jugador'),
        findsOneWidget,
      );
    });

    testWidgets('error and loading while upcoming sessions load', (
      tester,
    ) async {
      final a = _athlete()..training.failWith = StateError('x');
      await pumpAs(
        tester,
        roles: {TenantRole.player},
        ownPlayerId: 'p1',
        core: athleteCore(),
        athlete: a,
        location: '/me',
      );
      expect(find.text('Reintentar'), findsOneWidget);
      final b = _athlete()..training.hang = true;
      await pumpAs(
        tester,
        roles: {TenantRole.player},
        ownPlayerId: 'p1',
        core: athleteCore(),
        athlete: b,
        location: '/me',
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('PLAYER can file own absence from the training tab', (
      tester,
    ) async {
      final h = await pumpAs(
        tester,
        roles: {TenantRole.player},
        ownPlayerId: 'p1',
        core: athleteCore(),
        athlete: _athlete(),
        location: '/me',
        size: const Size(360, 1200),
      );
      await tapKey(tester, 'hub-absences');
      expect(
        h.container.read(routerProvider).state.uri.path,
        '/training/absences',
      );
    });
  });

  group('My players (PARENT)', () {
    testWidgets('empty when no child is linked', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.parent},
        core: athleteCore(),
        athlete: _athlete(),
        location: '/my-players',
      );
      expect(find.text('No tienes jugadores vinculados'), findsOneWidget);
    });

    testWidgets('one child: no switcher, same tabs', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.parent},
        linkedPlayerIds: {'p1'},
        core: athleteCore(),
        athlete: _athlete(),
        location: '/my-players',
        size: const Size(360, 1200),
      );
      expect(find.byKey(const Key('child-p1')), findsNothing);
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.byKey(const Key('hub-tab-training')), findsOneWidget);
      expect(find.byKey(const Key('hub-tab-plans')), findsOneWidget);
      expect(find.byKey(const Key('hub-tab-health')), findsOneWidget);
    });

    testWidgets(
      'two children: the switcher swaps trainings, plans and health per child',
      (tester) async {
        await pumpAs(
          tester,
          roles: {TenantRole.parent},
          linkedPlayerIds: {'p1', 'p4'},
          core: athleteCore(),
          athlete: _athlete(),
          location: '/my-players',
          size: const Size(360, 1400),
        );
        expect(find.byKey(const Key('child-p1')), findsOneWidget);
        expect(find.byKey(const Key('child-p4')), findsOneWidget);
        // p1 is on t1 (has s1), p4 on t2 (has s-t2)
        expect(find.byKey(const Key('session-s1')), findsOneWidget);
        await tapKey(tester, 'child-p4');
        expect(find.byKey(const Key('session-s-t2')), findsOneWidget);
        expect(find.byKey(const Key('session-s1')), findsNothing);
        await tapKey(tester, 'hub-tab-health');
        expect(find.text('Sin lesiones registradas'), findsOneWidget);
        await tapKey(tester, 'child-p1');
        await tapKey(tester, 'hub-tab-health');
        expect(find.text('Rodilla'), findsOneWidget);
      },
    );

    testWidgets('parent marks the completion for the child', (tester) async {
      final a = _athlete();
      await pumpAs(
        tester,
        roles: {TenantRole.parent},
        linkedPlayerIds: {'p2'},
        core: athleteCore(),
        athlete: a,
        location: '/my-players',
        size: const Size(360, 1400),
      );
      await tapKey(tester, 'hub-tab-plans');
      await tapKey(tester, 'comp-as-p2-p2-DONE');
      await tapKey(tester, 'dialog-confirm');
      expect(a.plans.lastRecord!.playerId, 'p2');
    });
  });

  group('Profile menu and context entry', () {
    testWidgets(
      'super_admin WITH an academy can switch context; a plain member cannot',
      (tester) async {
        final h = await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: athleteCore(),
          superAdmin: true,
          location: '/profile',
        );
        // The old "Platform console" entry is gone: the switcher lists it.
        expect(find.byKey(const Key('open-platform')), findsNothing);
        expect(find.byKey(const Key('switch-academy')), findsOneWidget);
        await tapKey(tester, 'switch-academy');
        expect(h.container.read(routerProvider).state.uri.path, '/tenants');
        expect(find.byKey(const Key('tenant-platform')), findsOneWidget);
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: athleteCore(),
          location: '/profile',
        );
        expect(find.byKey(const Key('switch-academy')), findsNothing);
      },
    );

    testWidgets('language picker and sign out stay available', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.player},
        ownPlayerId: 'p1',
        core: athleteCore(),
        location: '/profile',
        size: const Size(360, 1600),
      );
      for (final k in ['lang-es', 'lang-en', 'lang-id', 'sign-out-button']) {
        expect(find.byKey(Key(k)), findsOneWidget, reason: k);
      }
    });
  });

  group('redirectFor with super_admin', () {
    final user = userWith([
      membershipWithRoles({TenantRole.coach}),
    ], superAdmin: true);
    final plain = userWith([
      membershipWithRoles({TenantRole.coach}),
    ]);

    test('an old /platform link of a super admin keeps its target (WP99)', () {
      final s = SessionState.ready(
        user: user,
        membership: user.memberships.first,
      );
      expect(redirectFor(s, '/platform'), '/app-admin/academies');
      expect(redirectFor(s, '/platform/abc'), '/app-admin/academies/abc');
    });

    test('a regular member is still bounced from /platform', () {
      final s = SessionState.ready(
        user: plain,
        membership: plain.memberships.first,
      );
      expect(redirectFor(s, '/platform'), '/teams');
      expect(redirectFor(s, '/platform/abc'), '/teams');
    });
  });
}
