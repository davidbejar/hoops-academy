import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/training/data/plans_repository.dart';
import 'package:hoops_app/features/training/data/training_repository.dart';

/// WP78 (athlete 2.3.0, ADR-0041) in the demo backend: sessions reference any
/// plan, the search finds exercises, quick-adds go to the session's own plan.
void main() {
  const t = mockTenantAId;
  const team = 'team-mini-a';
  late ath.HoopsAthleteApi athlete;
  late TrainingRepository training;
  late PlansRepository plans;

  setUp(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://mock',
        headers: {'Authorization': 'Bearer x'},
      ),
    )..httpClientAdapter = MockApiAdapter(roles: ['ADMIN']);
    athlete = ath.HoopsAthleteApi(dio: dio, interceptors: const []);
    training = ApiTrainingRepository(athlete, t);
    plans = ApiPlansRepository(athlete, t);
  });

  ath.PlanItemSource ref(String plan, String item) => ath.PlanItemSource(
    (b) => b
      ..planId = plan
      ..itemId = item,
  );

  Future<ath.TrainingSession> newSession({String? planId}) =>
      training.createSession(
        ath.CreateTrainingSessionRequest(
          (b) => b
            ..teamId = team
            ..startsAt = DateTime.utc(2027, 9, 7, 15)
            ..durationMinutes = 60
            ..planId = planId,
        ),
      );

  Matcher status(int code) => throwsA(
    isA<DioException>().having((e) => e.response?.statusCode, 'status', code),
  );

  test('"cooper" finds the conditioning template by its exercise', () async {
    final found = await plans.plans(templates: true, query: 'cooper');
    expect(found.map((p) => p.id), ['tpl-conditioning']);
    expect(found.single.matchedItems!.map((i) => (i.id, i.planId, i.title)), [
      ('tpl-c1', 'tpl-conditioning', 'Test de Cooper 12 min'),
    ]);
    final byName = await plans.plans(templates: true, query: 'manejo');
    expect(byName.single.matchedItems, isNull);
  });

  test(
    'the first quick-add creates the session\'s own plan, later ones append',
    () async {
      final session = await newSession();
      final own = await training.copyItemsToSession(session.id, [
        ref('tpl-conditioning', 'tpl-c1'),
      ]);
      expect(
        (own.sessionId, own.template, own.name),
        (session.id, false, 'Sesión 2027-09-07'),
      );
      expect((await training.session(session.id)).planId, own.id);
      final again = await training.copyItemsToSession(session.id, [
        ref('tpl-shooting', 'tpl-s2'),
        ref('tpl-conditioning', 'tpl-c1'),
      ]);
      expect(again.id, own.id);
      expect(again.items.map((i) => i.title), [
        'Test de Cooper 12 min',
        'Tiros libres',
        'Test de Cooper 12 min',
      ]);
      expect(
        (await plans.plans(templates: false)).any((p) => p.id == own.id),
        isFalse,
      );
    },
  );

  test('a session on a template gets a copy; the template stays', () async {
    final session = await newSession(planId: 'tpl-shooting');
    final own = await training.copyItemsToSession(session.id, [
      ref('tpl-conditioning', 'tpl-c2'),
    ]);
    expect(own.sourceTemplateId, 'tpl-shooting');
    expect(own.itemCount, 4);
    expect((await plans.plan('tpl-shooting')).itemCount, 3);
  });

  test('the own plan stays with its session and goes when left', () async {
    final session = await newSession();
    final own = await training.copyItemsToSession(session.id, [
      ref('tpl-conditioning', 'tpl-c1'),
    ]);
    await expectLater(newSession(planId: own.id), status(422));
    await expectLater(
      plans.assign(
        ath.CreatePlanAssignmentRequest(
          (b) => b
            ..planId = own.id
            ..teamId = team
            ..dueOn = ath.Date(2027, 9, 10),
        ),
      ),
      status(422),
    );
    await training.updateSession(
      session.id,
      ath.UpdateTrainingSessionRequest((b) => b..planId = 'tpl-handling'),
    );
    await expectLater(plans.plan(own.id), status(404));
  });

  test('items are copied to a tenant plan, never to a template', () async {
    final target = await plans.createPlan(
      ath.CreateTrainingPlanRequest((b) => b..name = 'Martes'),
    );
    final changed = (await athlete.getTrainingPlansApi().copyItemsToPlan(
      xTenantId: t,
      planId: target.id,
      copyPlanItemsRequest: ath.CopyPlanItemsRequest(
        (b) => b.items.replace([ref('tpl-conditioning', 'tpl-c3')]),
      ),
    )).data!;
    expect(changed.items.map((i) => i.title), ['Sprints de 20 m']);
    await expectLater(
      athlete.getTrainingPlansApi().copyItemsToPlan(
        xTenantId: t,
        planId: 'tpl-shooting',
        copyPlanItemsRequest: ath.CopyPlanItemsRequest(
          (b) => b.items.replace([ref('tpl-conditioning', 'tpl-c3')]),
        ),
      ),
      status(403),
    );
    await expectLater(
      training.copyItemsToSession((await newSession()).id, [
        ref('tpl-conditioning', 'nope'),
      ]),
      status(404),
    );
  });
}
