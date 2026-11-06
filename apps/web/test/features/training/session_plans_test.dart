import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/fake_athlete.dart';
import '../../support/pump_helpers.dart';

/// WP78 (decisions 53 and 54, ADR-0041): a session picks any plan or template
/// directly, the picker searches item titles, and exercises are quick-added.
FakeAthlete plansAthlete() {
  final athlete = weekAthlete();
  athlete.plans.planList.addAll([
    planOf(
      'tpl-fin',
      'Finalización junto al aro',
      template: true,
      items: [
        planItem('tf1', 'Bandeja', 0, minutes: 6),
        planItem('tf2', 'Paso europeo', 1, minutes: 6),
      ],
    ),
    planOf(
      'tpl-cond',
      'Acondicionamiento',
      template: true,
      items: [
        planItem('tc1', 'Test de Cooper 12 min', 0, minutes: 12),
        planItem('tc2', 'Suicidios', 1, minutes: 8),
      ],
    ),
  ]);
  return athlete;
}

/// Types into a search box and lets the results load.
Future<void> search(WidgetTester tester, String key, String text) async {
  await enter(tester, key, text);
  await tester.pumpAndSettle();
}

void main() {
  group('plan picker', () {
    testWidgets('lists academy plans and templates in two groups', (
      tester,
    ) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: plansAthlete(),
        location: '/training/session/s2',
      );
      await tapKey(tester, 'session-edit');
      await tapKey(tester, 'session-plan');

      expect(find.text('Planes de la academia'), findsOneWidget);
      expect(find.text('Plantillas'), findsOneWidget);
      expect(find.byKey(const Key('plan-option-plan-1')), findsOneWidget);
      expect(find.byKey(const Key('plan-option-tpl-fin')), findsOneWidget);
      expect(find.byKey(const Key('plan-option-tpl-cond')), findsOneWidget);
    });

    testWidgets(
      'a template is picked directly; the search finds it by an exercise',
      (tester) async {
        final athlete = plansAthlete();
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: athleteCore(),
          athlete: athlete,
          location: '/training/session/s2',
        );
        await tapKey(tester, 'session-edit');
        await tapKey(tester, 'session-plan');
        await search(tester, 'plan-search', 'cooper');

        expect(find.byKey(const Key('plan-option-tpl-fin')), findsNothing);
        expect(find.text('Encontrado: Test de Cooper 12 min'), findsOneWidget);
        await tapKey(tester, 'plan-option-tpl-cond');
        expect(find.text('Acondicionamiento'), findsOneWidget); // the field
        await tapKey(tester, 'form-submit');

        expect(athlete.training.updatedSession!.planId, 'tpl-cond');
      },
    );

    testWidgets('a search without results says so', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: plansAthlete(),
        location: '/training/session/s2',
      );
      await tapKey(tester, 'session-edit');
      await tapKey(tester, 'session-plan');
      await search(tester, 'plan-search', 'zzz');

      expect(find.text('Ningún plan ni ejercicio coincide'), findsOneWidget);
    });
  });

  group('quick-add', () {
    testWidgets(
      'staff search exercises, pick several and add them to the session',
      (tester) async {
        final athlete = plansAthlete();
        await pumpAs(
          tester,
          roles: {TenantRole.coach},
          staffTeamIds: {'t1'},
          core: athleteCore(),
          athlete: athlete,
          location: '/training/session/s2',
        );
        await tapKey(tester, 'session-add-exercises');
        expect(
          find.text('Escribe para buscar en tus planes y plantillas'),
          findsOneWidget,
        );
        await search(tester, 'exercise-search', 'cooper');
        expect(find.text('Acondicionamiento'), findsOneWidget);
        await tapKey(tester, 'exercise-tpl-cond-tc1');
        await search(tester, 'exercise-search', 'paso');
        await tapKey(tester, 'exercise-tpl-fin-tf2');
        expect(find.text('Añadir (2)'), findsOneWidget);
        await tapKey(tester, 'exercise-add');

        final sent = athlete.training.quickAdded.single;
        expect(
          [for (final r in sent) '${r.planId}/${r.itemId}'],
          ['tpl-cond/tc1', 'tpl-fin/tf2'],
        );
        expect(find.text('Ejercicios añadidos: 2'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(
          find.text('Test de Cooper 12 min', skipOffstage: false),
          findsOneWidget,
        );
        expect(find.text('Paso europeo', skipOffstage: false), findsOneWidget);
        expect(find.text('Plan propio de la sesión'), findsOneWidget);
      },
    );

    testWidgets('a plan found by its name offers all of its exercises', (
      tester,
    ) async {
      final athlete = plansAthlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: athlete,
        location: '/training/session/s2',
      );
      await tapKey(tester, 'session-add-exercises');
      await search(tester, 'exercise-search', 'acondicionamiento');
      expect(find.byKey(const Key('exercise-tpl-cond-tc1')), findsOneWidget);
      expect(find.byKey(const Key('exercise-tpl-cond-tc2')), findsOneWidget);
      expect(find.text('Añadir (0)'), findsOneWidget);
      final add = tester.widget<FilledButton>(
        find.byKey(const Key('exercise-add')),
      );
      expect(add.onPressed, isNull);
    });

    testWidgets('quick-adding to a session with a plan keeps its exercises', (
      tester,
    ) async {
      final athlete = plansAthlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: athlete,
        location: '/training/session/s1',
      );
      await tapKey(tester, 'session-add-exercises');
      await search(tester, 'exercise-search', 'suicid');
      await tapKey(tester, 'exercise-tpl-cond-tc2');
      await tapKey(tester, 'exercise-add');
      await tester.pumpAndSettle();

      final own = athlete.plans.planList.firstWhere((p) => p.sessionId == 's1');
      expect(
        [for (final i in own.items) i.title],
        ['Calentamiento', 'Tiros libres', 'Suicidios'],
      );
      expect(
        athlete.plans.planList.firstWhere((p) => p.id == 'plan-1').itemCount,
        2,
      );
    });

    testWidgets('leaving the session\'s own plan warns that it goes away', (
      tester,
    ) async {
      final athlete = plansAthlete();
      athlete.plans.planList.add(
        planOf(
          'own-s2',
          'Sesión',
          sessionId: 's2',
          items: [planItem('o1', 'Bandeja', 0)],
        ),
      );
      final i = athlete.training.sessionList.indexWhere((s) => s.id == 's2');
      athlete.training.sessionList[i] = athlete.training.sessionList[i].rebuild(
        (b) => b..planId = 'own-s2',
      );
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: athlete,
        location: '/training/session/s2',
      );
      await tapKey(tester, 'session-edit');
      expect(
        find.text('Los ejercicios añadidos a esta sesión se eliminarán'),
        findsNothing,
      );
      await tapKey(tester, 'session-plan');
      expect(
        find.byKey(const Key('plan-option-own-s2')),
        findsNothing,
      ); // never listed
      await tapKey(tester, 'plan-option-tpl-fin');
      expect(
        find.text('Los ejercicios añadidos a esta sesión se eliminarán'),
        findsOneWidget,
      );
    });

    testWidgets(
      'parents, other teams\' coaches and cancelled sessions cannot',
      (tester) async {
        await pumpAs(
          tester,
          roles: {TenantRole.parent},
          linkedPlayerIds: {'p1'},
          core: athleteCore(),
          athlete: plansAthlete(),
          location: '/training/session/s2',
        );
        expect(find.byKey(const Key('session-add-exercises')), findsNothing);
        await pumpAs(
          tester,
          roles: {TenantRole.coach},
          staffTeamIds: {'t2'},
          core: athleteCore(),
          athlete: plansAthlete(),
          location: '/training/session/s2',
        );
        expect(find.byKey(const Key('session-add-exercises')), findsNothing);
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: athleteCore(),
          athlete: plansAthlete(),
          location: '/training/session/s4',
        );
        expect(find.byKey(const Key('session-add-exercises')), findsNothing);
      },
    );
  });
}
