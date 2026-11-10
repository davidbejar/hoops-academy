import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/training/data/exercises_repository.dart';
import 'package:hoops_app/features/training/data/plans_repository.dart';
import 'package:hoops_app/features/training/data/training_repository.dart';

/// WP92 (athlete 3.0.0, decision 72, ADR-0047) in the demo backend: the
/// exercise catalogue (localised global exercises and the academy's own) and
/// quick-add from it or from plan items.
void main() {
  const t = mockTenantAId;
  const team = 'team-mini-a';
  late ath.HoopsAthleteApi athlete;
  late ExercisesRepository exercises;
  late PlansRepository plans;
  late TrainingRepository training;

  ath.HoopsAthleteApi apiAs(List<String> roles) {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://mock',
        headers: {'Authorization': 'Bearer x'},
      ),
    )..httpClientAdapter = MockApiAdapter(roles: roles);
    return ath.HoopsAthleteApi(dio: dio, interceptors: const []);
  }

  setUp(() {
    athlete = apiAs(['ADMIN']);
    exercises = ApiExercisesRepository(athlete, t);
    plans = ApiPlansRepository(athlete, t);
    training = ApiTrainingRepository(athlete, t);
  });

  Matcher problem(int status, [String? code]) => throwsA(
    isA<DioException>()
        .having((e) => e.response?.statusCode, 'status', status)
        .having(
          (e) => (e.response?.data as Map?)?['code'],
          'code',
          code ?? anything,
        ),
  );

  ath.PlanItemSource fromExercise(String id) =>
      ath.PlanItemSource((b) => b..exerciseId = id);
  ath.PlanItemSource fromItem(String plan, String item) => ath.PlanItemSource(
    (b) => b
      ..planId = plan
      ..itemId = item,
  );

  Future<List<String>> titles({
    String? query,
    ath.ExerciseScope? scope,
    bool includeArchived = false,
    String? language,
  }) async => [
    for (final e in (await exercises.exercises(
      query: query,
      scope: scope,
      includeArchived: includeArchived,
      language: language,
    )).items)
      e.title,
  ];

  group('catalogue', () {
    test('globals and the academy\'s own, ordered by the shown title; '
        'archived ones left out; English without a language', () async {
      expect(await titles(), [
        '20 m sprints',
        'Cooper test (12 min)',
        'Free throws',
        'Rueda de pases',
        'Shot off the dribble',
        'Slalom crossovers',
        'Stationary shooting',
        'Suicide runs',
        'Two-ball dribbling',
      ]);
    });

    test('global exercises follow Accept-Language, fallback English', () async {
      Future<ath.Exercise> cooper(String language) async =>
          (await exercises.exercises(
            query: 'cooper',
            language: language,
          )).items.single;

      final es = await cooper('es');
      expect(
        (es.id, es.title, es.description, es.durationMinutes),
        (
          'ex-cooper-test',
          'Test de Cooper (12 min)',
          'Corre la mayor distancia posible en 12 minutos; anota la distancia '
              'en metros.',
          12,
        ),
      );
      expect(
        (es.global, es.nameKey, es.archived),
        (true, 'cooper-test', false),
      );
      expect((await cooper('id')).title, 'Tes Cooper (12 menit)');
      expect(
        (await cooper('id')).description,
        'Lari sejauh mungkin dalam 12 menit; catat jaraknya dalam meter.',
      );
      expect((await cooper('fr')).title, 'Cooper test (12 min)');
      expect((await cooper('fr, id;q=0.8')).title, 'Tes Cooper (12 menit)');
      expect(
        (await cooper('en')).description,
        'Run as far as you can in 12 minutes; record the distance in metres.',
      );
    });

    test('q matches a part of the shown title, case-insensitively', () async {
      expect(await titles(query: 'TIRO', language: 'es'), [
        'Tiro en estático',
        'Tiro tras bote',
      ]);
      expect(await titles(query: 'tiro'), isEmpty); // English titles
    });

    test('scope and includeArchived', () async {
      final global = (await exercises.exercises(
        scope: ath.ExerciseScope.GLOBAL,
      )).items;
      expect(global, hasLength(8));
      expect(global.every((e) => e.global && e.nameKey != null), isTrue);
      expect(await titles(scope: ath.ExerciseScope.TENANT), ['Rueda de pases']);
      final own = (await exercises.exercises(
        scope: ath.ExerciseScope.TENANT,
        includeArchived: true,
      )).items;
      expect(
        [for (final e in own) (e.title, e.archived, e.nameKey)],
        [('Defensa en zona 2-3', true, null), ('Rueda de pases', false, null)],
      );
    });

    test('pages', () async {
      final last = await exercises.exercises(page: 2, size: 4);
      expect([for (final e in last.items) e.title], ['Two-ball dribbling']);
      expect(
        (last.page.page, last.page.totalElements, last.page.totalPages),
        (2, 9, 3),
      );
    });

    test('one exercise by id, archived ones included; unknown 404', () async {
      final archived = (await athlete.getExercisesApi().getExercise(
        xTenantId: t,
        exerciseId: 'ex-own-zone',
      )).data!;
      expect(
        (archived.title, archived.archived),
        ('Defensa en zona 2-3', true),
      );
      final cooper = (await athlete.getExercisesApi().getExercise(
        xTenantId: t,
        exerciseId: 'ex-cooper-test',
        acceptLanguage: 'es',
      )).data!;
      expect(cooper.title, 'Test de Cooper (12 min)');
      await expectLater(
        athlete.getExercisesApi().getExercise(xTenantId: t, exerciseId: 'nope'),
        problem(404),
      );
    });
  });

  group('the academy\'s own exercises', () {
    test('are created, edited with clear and archived idempotently', () async {
      final created = await exercises.create(
        ath.ExerciseInput(
          (b) => b
            ..title = 'Tres hombres'
            ..description = 'Contraataque'
            ..durationMinutes = 10
            ..sets = 3,
        ),
      );
      expect(
        (created.global, created.nameKey, created.archived),
        (false, null, false),
      );
      expect(await titles(scope: ath.ExerciseScope.TENANT), [
        'Rueda de pases',
        'Tres hombres',
      ]);

      final edited = await exercises.update(
        created.id,
        ath.UpdateExerciseRequest(
          (b) => b
            ..repetitions = 5
            ..clear.replace([ath.UpdateExerciseRequestClearEnum.description]),
        ),
      );
      expect(
        (edited.title, edited.description, edited.sets, edited.repetitions),
        ('Tres hombres', null, 3, 5),
      );

      expect((await exercises.archive(created.id)).archived, isTrue);
      expect((await exercises.archive(created.id)).archived, isTrue);
      expect(await titles(scope: ath.ExerciseScope.TENANT), ['Rueda de pases']);
      expect((await exercises.unarchive(created.id)).archived, isFalse);
      expect((await exercises.unarchive(created.id)).archived, isFalse);
    });

    test('global exercises are read-only: 403 EXERCISE_IS_GLOBAL', () async {
      await expectLater(
        exercises.update(
          'ex-cooper-test',
          ath.UpdateExerciseRequest((b) => b..title = 'Cooper'),
        ),
        problem(403, 'EXERCISE_IS_GLOBAL'),
      );
      await expectLater(
        exercises.archive('ex-cooper-test'),
        problem(403, 'EXERCISE_IS_GLOBAL'),
      );
      await expectLater(
        exercises.unarchive('ex-cooper-test'),
        problem(403, 'EXERCISE_IS_GLOBAL'),
      );
    });

    for (final role in ['PARENT', 'PLAYER']) {
      test('$role reads the catalogue and cannot write it (403)', () async {
        final repo = ApiExercisesRepository(apiAs([role]), t);
        expect((await repo.exercises()).items, hasLength(9));
        await expectLater(
          repo.create(ath.ExerciseInput((b) => b..title = 'X')),
          problem(403),
        );
        await expectLater(repo.archive('ex-own-passing'), problem(403));
      });
    }

    for (final role in ['COACH', 'ASSISTANT_COACH']) {
      test('$role manages them', () async {
        final repo = ApiExercisesRepository(apiAs([role]), t);
        final e = await repo.create(ath.ExerciseInput((b) => b..title = 'X'));
        expect((await repo.archive(e.id)).archived, isTrue);
      });
    }
  });

  group('templates and quick-add', () {
    test('template items reference their catalogue exercise', () async {
      final conditioning = await plans.plan('tpl-conditioning');
      expect(
        [for (final i in conditioning.items) (i.title, i.exerciseId)],
        [
          ('Test de Cooper (12 min)', 'ex-cooper-test'),
          ('Suicidios', 'ex-suicide-runs'),
          ('Sprints de 20 m', 'ex-sprints-20m'),
        ],
      );
      final found = await plans.plans(templates: true, query: 'cooper');
      final match = found.single.matchedItems!.single;
      expect((match.id, match.exerciseId), ('tpl-c1', 'ex-cooper-test'));
      expect((await plans.plan('plan-warmup')).items.map((i) => i.exerciseId), [
        null,
        null,
        null,
      ]);
    });

    Future<ath.TrainingPlan> quickAddToSession(
      String sessionId,
      List<ath.PlanItemSource> items, {
      String? language,
    }) async => (await athlete.getTrainingSessionsApi().copyItemsToSession(
      xTenantId: t,
      sessionId: sessionId,
      acceptLanguage: language,
      copyPlanItemsRequest: ath.CopyPlanItemsRequest(
        (b) => b.items.replace(items),
      ),
    )).data!;

    Future<String> newSession() async => (await training.createSession(
      ath.CreateTrainingSessionRequest(
        (b) => b
          ..teamId = team
          ..startsAt = DateTime.utc(2027, 9, 7, 15)
          ..durationMinutes = 60,
      ),
    )).id;

    test('a session takes catalogue exercises and plan items, in order; '
        'each copy keeps its exercise reference', () async {
      final own = await quickAddToSession(await newSession(), [
        fromExercise('ex-cooper-test'),
        fromItem('tpl-conditioning', 'tpl-c2'),
        fromItem('plan-warmup', 'w1'),
        fromExercise('ex-own-passing'),
      ], language: 'es');
      expect(
        [
          for (final i in own.items)
            (i.position, i.title, i.durationMinutes, i.exerciseId),
        ],
        [
          (0, 'Test de Cooper (12 min)', 12, 'ex-cooper-test'),
          (1, 'Suicidios', 8, 'ex-suicide-runs'),
          (2, 'Trote y movilidad', 5, null),
          (3, 'Rueda de pases', 8, 'ex-own-passing'),
        ],
      );
      expect(
        own.items.first.description,
        'Corre la mayor distancia posible en 12 minutos; anota la distancia '
        'en metros.',
      );
    });

    test('a tenant plan takes them too, in the caller\'s language', () async {
      final target = await plans.createPlan(
        ath.CreateTrainingPlanRequest((b) => b..name = 'Martes'),
      );
      final changed = await plans.copyItems(target.id, [
        fromExercise('ex-free-throws'),
        fromExercise('ex-free-throws'),
      ], language: 'id');
      expect(
        [for (final i in changed.items) (i.title, i.sets, i.exerciseId)],
        [
          ('Lemparan bebas', 2, 'ex-free-throws'),
          ('Lemparan bebas', 2, 'ex-free-throws'),
        ],
      );
      expect(changed.items[0].id, isNot(changed.items[1].id));
    });

    test('editing a copy keeps its reference; plan copies keep them', () async {
      final target = await plans.createPlan(
        ath.CreateTrainingPlanRequest((b) => b..name = 'Martes'),
      );
      final item = (await plans.copyItems(target.id, [
        fromExercise('ex-own-passing'),
      ])).items.single;
      final edited = await plans.updateItem(
        target.id,
        item.id,
        ath.UpdatePlanItemRequest((b) => b..title = 'Rueda larga'),
      );
      expect(
        (edited.title, edited.exerciseId),
        ('Rueda larga', 'ex-own-passing'),
      );
      final copy = await plans.copyPlan('tpl-conditioning');
      expect(copy.items.map((i) => i.exerciseId), [
        'ex-cooper-test',
        'ex-suicide-runs',
        'ex-sprints-20m',
      ]);
    });

    test('an archived exercise is 422 EXERCISE_ARCHIVED; unknown 404; '
        'a source that is not exactly one kind 400', () async {
      final session = await newSession();
      await expectLater(
        quickAddToSession(session, [fromExercise('ex-own-zone')]),
        problem(422, 'EXERCISE_ARCHIVED'),
      );
      await expectLater(
        plans.copyItems('plan-warmup', [fromExercise('ex-own-zone')]),
        problem(422, 'EXERCISE_ARCHIVED'),
      );
      await expectLater(
        quickAddToSession(session, [fromExercise('nope')]),
        problem(404),
      );
      await expectLater(
        quickAddToSession(session, [
          fromItem(
            'tpl-conditioning',
            'tpl-c1',
          ).rebuild((b) => b..exerciseId = 'ex-cooper-test'),
        ]),
        problem(400),
      );
      await expectLater(
        quickAddToSession(session, [ath.PlanItemSource()]),
        problem(400),
      );
      await expectLater(
        quickAddToSession(session, [
          ath.PlanItemSource((b) => b..planId = 'tpl-conditioning'),
        ]),
        problem(400),
      );
      expect((await plans.plan('plan-warmup')).itemCount, 3);
    });
  });
}
