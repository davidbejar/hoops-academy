import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/athlete_scenarios.dart';
import '../../support/fake_athlete.dart';
import '../../support/pump_helpers.dart';

/// WP92 (decision 72, ADR-0047): the exercise catalogue is a tab of the plan
/// library: global exercises (read-only, marked) and the academy's own,
/// created, edited and archived by staff.
FakeAthlete catalogueAthlete({List<ath.Exercise>? exercises}) => FakeAthlete(
  plans: weekAthlete().plans,
  exercises: FakeExercisesRepository(
    exercises: exercises ?? catalogueExercises(),
  ),
);

/// Opens the plan library on its exercise tab, on a phone tall enough to
/// show the whole small catalogue.
Future<void> openCatalogue(
  WidgetTester tester,
  FakeAthlete athlete, {
  Set<TenantRole> roles = const {TenantRole.coach},
  Size size = const Size(360, 1600),
}) async {
  await pumpAs(
    tester,
    roles: roles,
    staffTeamIds: {'t1'},
    core: athleteCore(),
    athlete: athlete,
    size: size,
    location: '/training/plans',
  );
  await tapKey(tester, 'tab-exercises');
}

/// Snack bars queue up: clears the one shown so the next one appears.
Future<void> dismissSnackBar(WidgetTester tester) async {
  tester
      .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
      .removeCurrentSnackBar();
  await tester.pumpAndSettle();
}

Finder row(String id) => find.byKey(Key('exercise-row-$id'));

void main() {
  testWidgets('staff see the global exercises marked and the academy\'s own; '
      'archived ones are hidden', (tester) async {
    await openCatalogue(tester, catalogueAthlete());

    expect(row('g-cooper'), findsOneWidget);
    expect(row('g-ft'), findsOneWidget);
    expect(row('own-1'), findsOneWidget);
    expect(row('own-old'), findsNothing);
    expect(find.byKey(const Key('exercise-global-g-cooper')), findsOneWidget);
    expect(find.byKey(const Key('exercise-global-own-1')), findsNothing);
    expect(find.text('Dos filas'), findsOneWidget); // the description
  });

  testWidgets('the library search box also searches the exercises', (
    tester,
  ) async {
    final athlete = catalogueAthlete();
    await openCatalogue(tester, athlete);
    await enter(tester, 'plan-search', 'cooper');
    await tester.pumpAndSettle();

    expect(row('g-cooper'), findsOneWidget);
    expect(row('own-1'), findsNothing);
    expect(athlete.exercises.queries.last.query, 'cooper');
  });

  testWidgets('the scope filter shows all, the global or the academy\'s', (
    tester,
  ) async {
    final athlete = catalogueAthlete();
    await openCatalogue(tester, athlete);

    await tapKey(tester, 'exercise-scope-global');
    expect(row('g-cooper'), findsOneWidget);
    expect(row('own-1'), findsNothing);
    expect(athlete.exercises.queries.last.scope, ath.ExerciseScope.GLOBAL);

    await tapKey(tester, 'exercise-scope-academy');
    expect(row('g-cooper'), findsNothing);
    expect(row('own-1'), findsOneWidget);
    expect(athlete.exercises.queries.last.scope, ath.ExerciseScope.TENANT);

    await tapKey(tester, 'exercise-scope-all');
    expect(row('g-cooper'), findsOneWidget);
    expect(athlete.exercises.queries.last.scope, isNull);
  });

  testWidgets('staff may show the archived ones, marked as archived', (
    tester,
  ) async {
    final athlete = catalogueAthlete();
    await openCatalogue(tester, athlete);
    await tapKey(tester, 'exercise-show-archived');

    expect(row('own-old'), findsOneWidget);
    expect(find.byKey(const Key('exercise-archived-own-old')), findsOneWidget);
    expect(athlete.exercises.queries.last.includeArchived, isTrue);
  });

  testWidgets('the floating button follows the tab: new plan, new exercise', (
    tester,
  ) async {
    await pumpAs(
      tester,
      roles: {TenantRole.coach},
      staffTeamIds: {'t1'},
      core: athleteCore(),
      athlete: catalogueAthlete(),
      location: '/training/plans',
    );
    expect(find.byKey(const Key('plan-new')), findsOneWidget);
    expect(find.byKey(const Key('exercise-new')), findsNothing);
    await tapKey(tester, 'tab-exercises');
    expect(find.byKey(const Key('plan-new')), findsNothing);
    expect(find.text('Nuevo ejercicio'), findsOneWidget);
  });

  testWidgets('staff create an exercise of the academy', (tester) async {
    final athlete = catalogueAthlete();
    await openCatalogue(tester, athlete);
    await tapKey(tester, 'exercise-new');
    await enter(tester, 'exercise-title', 'Tres hombres');
    await enter(tester, 'exercise-description', 'Contraataque');
    await enter(tester, 'exercise-duration', '10');
    await enter(tester, 'exercise-sets', '3');
    await enter(tester, 'exercise-video', 'http://v.example/3h');
    await tapKey(tester, 'form-submit');
    expect(find.text('Debe empezar por https://'), findsOneWidget);
    expect(athlete.exercises.created, isNull);

    await enter(tester, 'exercise-video', 'https://v.example/3h');
    await tapKey(tester, 'form-submit');

    final input = athlete.exercises.created!;
    expect(
      (
        input.title,
        input.description,
        input.durationMinutes,
        input.sets,
        input.repetitions,
        input.videoUrl,
      ),
      ('Tres hombres', 'Contraataque', 10, 3, null, 'https://v.example/3h'),
    );
    expect(find.text('Ejercicio creado'), findsOneWidget);
    expect(row('own-4'), findsOneWidget);
  });

  testWidgets('a title is required', (tester) async {
    final athlete = catalogueAthlete();
    await openCatalogue(tester, athlete);
    await tapKey(tester, 'exercise-new');
    await tapKey(tester, 'form-submit');

    expect(find.text('Campo obligatorio'), findsOneWidget);
    expect(athlete.exercises.calls, isNot(contains('create')));
  });

  testWidgets('staff edit one of the academy: emptied fields are cleared', (
    tester,
  ) async {
    final athlete = catalogueAthlete();
    await openCatalogue(tester, athlete);
    await tapKey(tester, 'exercise-menu-own-1');
    await tapKey(tester, 'sheet-action-edit');
    expect(find.text('Rueda de pases'), findsWidgets); // prefilled
    await enter(tester, 'exercise-description', '');
    await enter(tester, 'exercise-duration', '9');
    await tapKey(tester, 'form-submit');

    final request = athlete.exercises.updated!;
    expect((request.title, request.durationMinutes), ('Rueda de pases', 9));
    expect(request.clear, {
      ath.UpdateExerciseRequestClearEnum.description,
      ath.UpdateExerciseRequestClearEnum.sets,
      ath.UpdateExerciseRequestClearEnum.repetitions,
      ath.UpdateExerciseRequestClearEnum.videoUrl,
    });
    expect(find.text('Ejercicio guardado'), findsOneWidget);
    expect(find.text('Dos filas'), findsNothing);
  });

  testWidgets('staff archive one of the academy and bring it back', (
    tester,
  ) async {
    final athlete = catalogueAthlete();
    await openCatalogue(tester, athlete);
    await tapKey(tester, 'exercise-menu-own-1');
    await tapKey(tester, 'sheet-action-archive');

    expect(find.text('Ejercicio archivado'), findsOneWidget);
    expect(row('own-1'), findsNothing);
    await dismissSnackBar(tester);

    await tapKey(tester, 'exercise-show-archived');
    await tapKey(tester, 'exercise-menu-own-1');
    expect(find.byKey(const Key('sheet-action-archive')), findsNothing);
    await tapKey(tester, 'sheet-action-unarchive');

    expect(find.text('Ejercicio restaurado'), findsOneWidget);
    expect(find.byKey(const Key('exercise-archived-own-1')), findsNothing);
    expect(
      athlete.exercises.calls,
      containsAllInOrder(['archive', 'unarchive']),
    );
  });

  testWidgets('global exercises are read-only: no actions', (tester) async {
    await openCatalogue(tester, catalogueAthlete());

    expect(find.byKey(const Key('exercise-menu-g-cooper')), findsNothing);
    expect(find.byKey(const Key('exercise-menu-own-1')), findsOneWidget);
  });

  testWidgets('a refused save is explained and the form stays open', (
    tester,
  ) async {
    final athlete = catalogueAthlete();
    await openCatalogue(tester, athlete);
    await tapKey(tester, 'exercise-menu-own-1');
    await tapKey(tester, 'sheet-action-edit');
    athlete.exercises.failWith = const AppError(
      kind: AppErrorKind.forbidden,
      status: 403,
      code: 'EXERCISE_IS_GLOBAL',
    );
    await tapKey(tester, 'form-submit');

    expect(
      find.text('Los ejercicios globales no se pueden modificar'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('exercise-title')), findsOneWidget);
    await dismissSnackBar(tester);

    athlete.exercises.failWith = const AppError(
      kind: AppErrorKind.notFound,
      status: 404,
    );
    await tapKey(tester, 'form-submit');
    expect(find.text('No hemos encontrado lo que buscas.'), findsOneWidget);
  });

  testWidgets('nothing found says so; the filters stay', (tester) async {
    await openCatalogue(tester, catalogueAthlete(exercises: []));

    expect(find.text('Ningún ejercicio coincide'), findsOneWidget);
    expect(find.byKey(const Key('exercise-scope-all')), findsOneWidget);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    final athlete = catalogueAthlete();
    athlete.exercises.failWith = const AppError(kind: AppErrorKind.server);
    // Wide: on a phone the floating button covers the centred retry button.
    await openCatalogue(tester, athlete, size: const Size(1024, 768));

    expect(
      find.text('El servidor ha tenido un problema. Inténtalo más tarde.'),
      findsOneWidget,
    );
    athlete.exercises.failWith = null;
    await tapKey(tester, 'retry-button');
    expect(row('g-cooper'), findsOneWidget);
  });

  testWidgets('loading shows a progress indicator', (tester) async {
    final athlete = catalogueAthlete();
    await pumpAs(
      tester,
      roles: {TenantRole.admin},
      core: athleteCore(),
      athlete: athlete,
      location: '/training/plans',
    );
    athlete.exercises.hang = true;
    await tester.tap(find.byKey(const Key('tab-exercises')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(row('g-cooper'), findsNothing);
  });

  testWidgets('long catalogues load page by page', (tester) async {
    final athlete = catalogueAthlete(
      exercises: [
        for (var i = 0; i < 52; i++)
          exercise('e${i.toString().padLeft(2, '0')}', 'Ejercicio ${i + 100}'),
      ],
    );
    await openCatalogue(tester, athlete);
    final list = find
        .descendant(
          of: find.byKey(const Key('exercise-list')),
          matching: find.byType(Scrollable),
        )
        .first;
    final more = find.byKey(const Key('exercise-more'));
    await tester.scrollUntilVisible(more, 400, scrollable: list);
    expect(row('e49'), findsOneWidget);
    expect(row('e50'), findsNothing);
    await tapKey(tester, 'exercise-more');

    await tester.scrollUntilVisible(row('e51'), 400, scrollable: list);
    expect(more, findsNothing);
    expect([for (final q in athlete.exercises.queries) q.page], [0, 1]);
  });

  group('roles', () {
    for (final role in [TenantRole.admin, TenantRole.assistantCoach]) {
      testWidgets('${role.name} manages the academy\'s exercises', (
        tester,
      ) async {
        await openCatalogue(tester, catalogueAthlete(), roles: {role});

        expect(find.byKey(const Key('exercise-new')), findsOneWidget);
        expect(find.byKey(const Key('exercise-menu-own-1')), findsOneWidget);
        expect(find.byKey(const Key('exercise-show-archived')), findsOneWidget);
      });
    }

    for (final role in [TenantRole.parent, TenantRole.player]) {
      testWidgets('${role.name} has no catalogue and no exercise actions', (
        tester,
      ) async {
        await pumpAs(
          tester,
          roles: {role},
          linkedPlayerIds: {'p1'},
          ownPlayerId: role == TenantRole.player ? 'p1' : null,
          core: athleteCore(),
          athlete: catalogueAthlete(),
          location: '/training/plans',
        );

        expect(find.byKey(const Key('tab-exercises')), findsNothing);
        expect(find.byKey(const Key('exercise-new')), findsNothing);
        expect(row('g-cooper'), findsNothing);
      });
    }
  });
}
