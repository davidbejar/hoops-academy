import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/fake_athlete.dart';
import '../../support/pump_helpers.dart';

/// WP78 (decisions 53 and 54, ADR-0041): a session picks any plan or template
/// directly, the picker searches item titles, and exercises are quick-added.
FakeAthlete plansAthlete() {
  final week = weekAthlete();
  final athlete = FakeAthlete(
    training: week.training,
    plans: week.plans,
    exercises: FakeExercisesRepository(exercises: catalogueExercises()),
  );
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
          find.text('Escribe para buscar también en tus planes y plantillas'),
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

  group('quick-add from the catalogue (WP92)', () {
    String sources(List<dynamic> sent) => [
      for (final s in sent)
        s.exerciseId != null ? 'ex:${s.exerciseId}' : '${s.planId}/${s.itemId}',
    ].join(', ');

    testWidgets('the session search lists the catalogue first; plan items '
        'written by hand stay reachable; the order of picking is kept', (
      tester,
    ) async {
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
      expect(find.byKey(const Key('catalogue-g-cooper')), findsOneWidget);
      expect(find.byKey(const Key('catalogue-own-1')), findsOneWidget);
      expect(find.byKey(const Key('catalogue-own-old')), findsNothing);
      expect(find.text('Acondicionamiento'), findsNothing); // no plan section

      await search(tester, 'exercise-search', 'cooper');
      expect(find.text('Catálogo de ejercicios'), findsOneWidget);
      expect(find.text('En tus planes y plantillas'), findsOneWidget);
      expect(find.byKey(const Key('exercise-tpl-cond-tc1')), findsOneWidget);
      await tapKey(tester, 'exercise-tpl-cond-tc1');
      await tapKey(tester, 'catalogue-g-cooper');
      await search(tester, 'exercise-search', 'rueda');
      await tapKey(tester, 'catalogue-own-1');
      expect(find.text('Añadir (3)'), findsOneWidget);
      await tapKey(tester, 'exercise-add');

      expect(
        sources(athlete.training.quickAdded.single),
        'tpl-cond/tc1, ex:g-cooper, ex:own-1',
      );
      expect(find.text('Ejercicios añadidos: 3'), findsOneWidget);
      await tester.pumpAndSettle();
      final own = athlete.plans.planList.firstWhere((p) => p.sessionId == 's2');
      expect(
        [for (final i in own.items) (i.title, i.exerciseId)],
        [
          ('Test de Cooper 12 min', null),
          ('Test de Cooper (12 min)', 'g-cooper'),
          ('Rueda de pases', 'own-1'),
        ],
      );
      expect(
        find.byKey(
          Key('item-from-catalogue-${own.items[1].id}'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          Key('item-from-catalogue-${own.items[0].id}'),
          skipOffstage: false,
        ),
        findsNothing,
      );
    });

    testWidgets('an item that came from a catalogue exercise shown above is '
        'not offered twice', (tester) async {
      final athlete = plansAthlete();
      athlete.plans.planList.add(
        planOf(
          'tpl-tests',
          'Tests físicos',
          template: true,
          items: [
            planItem(
              'tt1',
              'Test de Cooper (12 min)',
              0,
              exerciseId: 'g-cooper',
            ),
          ],
        ),
      );
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: athlete,
        location: '/training/session/s2',
      );
      await tapKey(tester, 'session-add-exercises');
      await search(tester, 'exercise-search', 'cooper');

      expect(find.byKey(const Key('catalogue-g-cooper')), findsOneWidget);
      expect(find.byKey(const Key('exercise-tpl-tests-tt1')), findsNothing);
      expect(find.text('Tests físicos'), findsNothing);
      expect(find.byKey(const Key('exercise-tpl-cond-tc1')), findsOneWidget);
    });

    testWidgets('an archived exercise is explained and the search stays', (
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
      await tapKey(tester, 'catalogue-own-1');
      athlete.training.failWith = const AppError(
        kind: AppErrorKind.validation,
        status: 422,
        code: 'EXERCISE_ARCHIVED',
      );
      await tapKey(tester, 'exercise-add');

      expect(
        find.text('Ese ejercicio está archivado: elige otro'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('exercise-add')), findsOneWidget);
    });

    testWidgets('the plan editor adds catalogue exercises at its end', (
      tester,
    ) async {
      final athlete = plansAthlete();
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        staffTeamIds: {'t1'},
        core: athleteCore(),
        athlete: athlete,
        location: '/training/plans/plan-1',
      );
      await tapKey(tester, 'plan-add-from-catalogue');
      await tapKey(tester, 'catalogue-own-1');
      await tapKey(tester, 'catalogue-g-ft');
      await tapKey(tester, 'exercise-add');

      expect(sources(athlete.plans.quickAdded.single), 'ex:own-1, ex:g-ft');
      expect(athlete.plans.languages.last, 'es');
      expect(find.text('Ejercicios añadidos: 2'), findsOneWidget);
      final plan = athlete.plans.planList.firstWhere((p) => p.id == 'plan-1');
      expect(
        [for (final i in plan.items) i.title],
        ['Calentamiento', 'Tiros libres', 'Rueda de pases', 'Tiros libres'],
      );
      expect(
        find.byKey(
          Key('item-from-catalogue-${plan.items[2].id}'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          Key('item-from-catalogue-${plan.items[1].id}'),
          skipOffstage: false,
        ),
        findsNothing,
      );
    });

    testWidgets('the plan editor explains an archived exercise', (
      tester,
    ) async {
      final athlete = plansAthlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: athlete,
        location: '/training/plans/plan-1',
      );
      await tapKey(tester, 'plan-add-from-catalogue');
      await tapKey(tester, 'catalogue-own-1');
      athlete.plans.failWith = const AppError(
        kind: AppErrorKind.validation,
        status: 422,
        code: 'EXERCISE_ARCHIVED',
      );
      await tapKey(tester, 'exercise-add');

      expect(
        find.text('Ese ejercicio está archivado: elige otro'),
        findsOneWidget,
      );
    });

    testWidgets('templates and parents get no catalogue quick-add', (
      tester,
    ) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: plansAthlete(),
        location: '/training/plans/tpl-fin',
      );
      expect(find.byKey(const Key('plan-add-from-catalogue')), findsNothing);
      await pumpAs(
        tester,
        roles: {TenantRole.parent},
        linkedPlayerIds: {'p1'},
        core: athleteCore(),
        athlete: plansAthlete(),
        location: '/training/plans/plan-1',
      );
      expect(find.byKey(const Key('plan-add-from-catalogue')), findsNothing);
    });

    testWidgets('a new session takes exercises: picked first, added to the '
        'session once it exists', (tester) async {
      final athlete = plansAthlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: athlete,
        location: '/training',
      );
      await tapKey(tester, 'session-new');
      await tapKey(tester, 'session-team');
      await tester.tap(find.text('Mini A (Leones)').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'session-exercises');
      await tapKey(tester, 'catalogue-g-cooper');
      await tapKey(tester, 'catalogue-own-1');
      await tapKey(tester, 'catalogue-g-ft');
      await tapKey(tester, 'exercise-add');
      expect(athlete.training.quickAdded, isEmpty); // no session yet
      expect(find.byKey(const Key('session-pick-0')), findsOneWidget);
      await tapKey(tester, 'session-pick-remove-1');
      expect(find.text('Rueda de pases'), findsNothing);
      await tapKey(tester, 'form-submit');

      expect(athlete.training.createdSession!.teamId, 't1');
      final created = athlete.training.sessionList.last;
      expect(
        sources(athlete.training.quickAdded.single),
        'ex:g-cooper, ex:g-ft',
      );
      expect(created.planId, 'own-${created.id}');
      expect(find.text('Sesión creada'), findsOneWidget);
    });

    testWidgets('a new session without exercises is only created', (
      tester,
    ) async {
      final athlete = plansAthlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: athlete,
        location: '/training',
      );
      await tapKey(tester, 'session-new');
      await tapKey(tester, 'session-team');
      await tester.tap(find.text('Mini A (Leones)').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'form-submit');

      expect(athlete.training.createdSession, isNotNull);
      expect(athlete.training.calls, isNot(contains('copyItemsToSession')));
    });

    testWidgets('a session created without its exercises closes the dialog '
        'and says why', (tester) async {
      final athlete = plansAthlete();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: athleteCore(),
        athlete: athlete,
        location: '/training',
      );
      await tapKey(tester, 'session-new');
      await tapKey(tester, 'session-team');
      await tester.tap(find.text('Mini A (Leones)').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'session-exercises');
      await tapKey(tester, 'catalogue-own-1');
      await tapKey(tester, 'exercise-add');
      athlete.training.failCopyWith = const AppError(
        kind: AppErrorKind.validation,
        status: 422,
        code: 'EXERCISE_ARCHIVED',
      );
      await tapKey(tester, 'form-submit');

      expect(athlete.training.createdSession, isNotNull);
      expect(find.byKey(const Key('form-submit')), findsNothing);
      expect(
        find.text(
          'Sesión creada, pero sin los ejercicios: Ese ejercicio está '
          'archivado: elige otro',
        ),
        findsOneWidget,
      );
    });
  });
}
