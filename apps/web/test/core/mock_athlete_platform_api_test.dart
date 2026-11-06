import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/api/clear_list.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/audit/data/audit_repository.dart';
import 'package:hoops_app/features/audit/domain/audit_entry.dart';
import 'package:hoops_app/features/health/data/fitness_repository.dart';
import 'package:hoops_app/features/health/data/health_repository.dart';
import 'package:hoops_app/features/platform/data/platform_repository.dart';
import 'package:hoops_app/features/training/data/plans_repository.dart';
import 'package:hoops_app/features/training/data/training_repository.dart';

/// WP41: the demo backend serves `/platform/*` and `/api/athlete/*`. Every call below goes through the generated
/// clients (and the app's repositories), so a response that does not match the contract models fails the parse.
void main() {
  const t = mockTenantAId;
  const team = 'team-mini-a';
  late Dio dio;
  late api.HoopsCoreApi core;
  late ath.HoopsAthleteApi athlete;

  Dio dioFor({bool superAdmin = true}) => Dio(BaseOptions(baseUrl: 'http://mock', headers: {'Authorization': 'Bearer x'}))
    ..httpClientAdapter = MockApiAdapter(roles: ['ADMIN'], superAdmin: superAdmin);

  setUp(() {
    dio = dioFor();
    core = api.HoopsCoreApi(dio: dio, interceptors: const []);
    athlete = ath.HoopsAthleteApi(dio: dio, interceptors: const []);
  });

  ath.Date today() => ath.Date.now();
  ath.Date inDays(int d) {
    final day = DateTime.now().add(Duration(days: d));
    return ath.Date(day.year, day.month, day.day);
  }

  group('platform', () {
    test('only the super admin may call it', () async {
      final repo = ApiPlatformRepository(api.HoopsCoreApi(dio: dioFor(superAdmin: false), interceptors: const []));
      await expectLater(
        repo.tenants(),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 403)),
      );
    });

    test('tenants: list, filters, detail', () async {
      final repo = ApiPlatformRepository(core);
      final all = await repo.tenants();
      expect(all.map((x) => x.slug), containsAll(['demo', 'norte']));
      expect(all.map((x) => x.status).toSet(), containsAll([api.TenantStatus.ACTIVE, api.TenantStatus.SUSPENDED]));
      expect((await repo.tenants(status: api.TenantStatus.SUSPENDED)).every((x) => x.status == api.TenantStatus.SUSPENDED), isTrue);
      expect((await repo.tenants(query: 'demo')).single.name, 'Academia Demo');
      expect((await repo.tenant(t)).slug, 'demo');
    });

    test('lifecycle: create (password returned once), suspend, reactivate, withdraw', () async {
      final repo = ApiPlatformRepository(core);
      final created = await repo.create(
        api.CreateTenantRequest((b) => b
          ..slug = 'nueva'
          ..name = 'Nueva'
          ..timezone = 'Asia/Jakarta'
          ..defaultLocale = api.ApiLocale.id
          ..firstAdmin.update((a) => a
            ..email = 'boss@nueva.io'
            ..givenName = 'Bo'
            ..familyName = 'Ss')),
      );
      expect(created.temporaryPassword, isNotEmpty);
      expect((await repo.tenant(created.id)).timezone, 'Asia/Jakarta');
      expect((await repo.admins(created.id)).single.invitationStatus, api.InvitationStatus.PENDING);
      expect((await repo.suspend(created.id, 'Impago')).status, api.TenantStatus.SUSPENDED);
      expect((await repo.reactivate(created.id)).status, api.TenantStatus.ACTIVE);
      final withdrawn = await repo.withdraw(created.id, 'Cierra');
      expect(withdrawn.status, api.TenantStatus.WITHDRAWN);
      expect(withdrawn.retainUntil, isNotNull);
      await expectLater(
        repo.admins(created.id),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 409)),
      );
    });

    test('usage: one report per service; history: a few months, ascending, one per day', () async {
      final repo = ApiPlatformRepository(core);
      final usage = await repo.usage(t);
      expect(usage.services.map((s) => s.service.name).toSet(), {'core', 'game', 'athlete'});
      final history = await repo.usageHistory(t);
      final dates = history.snapshots.map((s) => s.date.toString()).toList();
      expect(dates.length, greaterThanOrEqualTo(4));
      expect(dates.toSet().length, dates.length);
      expect([...dates]..sort(), dates);
      expect(history.snapshots.any((s) => s.unavailableServices.isNotEmpty), isTrue, reason: 'a partial snapshot to show');
    });

    test('administrators: add, update, temporary password, remove', () async {
      final repo = ApiPlatformRepository(core);
      expect((await repo.admins(t)), isNotEmpty);
      final added = await repo.addAdmin(
        t,
        api.AddTenantAdminRequest((b) => b
          ..email = 'ana.admin@x.io'
          ..givenName = 'Ana'
          ..familyName = 'Admin'),
      );
      expect(added.temporaryPassword, isNotEmpty);
      final updated = await repo.updateAdmin(t, added.personId, api.UpdateTenantAdminRequest((b) => b..givenName = 'Anita'));
      expect(updated.givenName, 'Anita');
      final again = await repo.issueAdminTemporaryPassword(t, added.personId);
      expect(again.temporaryPassword, isNot(added.temporaryPassword));
      await repo.removeAdmin(t, added.personId);
      expect((await repo.admins(t)).any((a) => a.personId == added.personId), isFalse);
    });

    test('audit list: every academy, the platform actor unmasked, filters', () async {
      final repo = ApiAuditRepository(core);
      final page = await repo.platform(const AuditQuery());
      expect(page.items, isNotEmpty);
      expect(page.items.every((e) => e.tenantName != null), isTrue);
      final platform = page.items.where((e) => e.actorKind == api.AuditActorKind.PLATFORM);
      expect(platform, isNotEmpty);
      expect(platform.map((e) => e.actorSubject), everyElement(isNotNull), reason: 'the super admin sees who acted');
      final one = await repo.platform(const AuditQuery(), tenantId: mockTenantBId);
      expect(one.items.map((e) => e.tenantId).toSet(), {mockTenantBId});
      final created = await repo.platform(const AuditQuery(actions: {api.AuditAction.tenantPeriodCreated}));
      expect(created.items.map((e) => e.action).toSet(), {api.AuditAction.tenantPeriodCreated});
    });
  });

  group('athlete: training', () {
    test('a week of sessions with attendance, create, update with clear, cancel', () async {
      final repo = ApiTrainingRepository(athlete, t);
      final sessions = await repo.sessions(teamId: team, from: inDays(-3), to: inDays(10));
      expect(sessions.length, greaterThanOrEqualTo(4));
      expect(sessions.map((s) => s.status).toSet(), containsAll([ath.TrainingSessionStatus.DONE, ath.TrainingSessionStatus.PLANNED]));
      expect((await repo.sessions(teamId: 'team-inf-a', from: inDays(-3), to: inDays(10))).every((s) => s.teamId == 'team-inf-a'), isTrue);

      final created = await repo.createSession(
        ath.CreateTrainingSessionRequest((b) => b
          ..teamId = team
          ..startsAt = DateTime.now().toUtc().add(const Duration(days: 20))
          ..durationMinutes = 60
          ..location = 'Pista 2'
          ..notes = 'Tiro'),
      );
      expect((await repo.session(created.id)).location, 'Pista 2');
      final updated = await repo.updateSession(
        created.id,
        ath.UpdateTrainingSessionRequest((b) => b
          ..durationMinutes = 75
          ..clear = clearList({ath.UpdateTrainingSessionRequestClearEnum.location: null, ath.UpdateTrainingSessionRequestClearEnum.notes: 'x'})),
      );
      expect(updated.durationMinutes, 75);
      expect(updated.location, isNull);
      expect(updated.notes, 'Tiro');
      final cancelled = await repo.cancelSession(created.id, 'Lluvia');
      expect((cancelled.status, cancelled.cancelReason), (ath.TrainingSessionStatus.CANCELLED, 'Lluvia'));
    });

    test('attendance: expected absence and injury overlay, record, late needs minutes', () async {
      final repo = ApiTrainingRepository(athlete, t);
      final planned = (await repo.sessions(teamId: team, from: today(), to: inDays(10)))
          .firstWhere((s) => s.status == ath.TrainingSessionStatus.PLANNED);
      final before = await repo.attendance(planned.id);
      expect(before.entries.map((e) => e.playerId), containsAll(['p-ana', 'p-leo']));
      final saved = await repo.recordAttendance(planned.id, [
        ath.AttendanceInput((b) => b
          ..playerId = 'p-ana'
          ..status = ath.AttendanceStatus.LATE
          ..minutesLate = 7),
        ath.AttendanceInput((b) => b
          ..playerId = 'p-leo'
          ..status = ath.AttendanceStatus.PRESENT),
      ]);
      final ana = saved.entries.firstWhere((e) => e.playerId == 'p-ana');
      expect((ana.status, ana.minutesLate), (ath.AttendanceStatus.LATE, 7));
      await expectLater(
        repo.recordAttendance(planned.id, [
          ath.AttendanceInput((b) => b
            ..playerId = 'p-ana'
            ..status = ath.AttendanceStatus.LATE),
        ]),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 400)),
      );
      // the seeded open injury of Leo shows on the sheet
      expect(saved.entries.firstWhere((e) => e.playerId == 'p-leo').unavailableInjuryId, isNotNull);
    });

    test('schedules: list, create, update with clear, delete', () async {
      final repo = ApiTrainingRepository(athlete, t);
      expect((await repo.schedules(teamId: team)), isNotEmpty);
      final s = await repo.createSchedule(
        ath.TrainingScheduleInput((b) => b
          ..teamId = team
          ..dayOfWeek = ath.DayOfWeek.SATURDAY
          ..startTime = '10:00'
          ..durationMinutes = 90
          ..location = 'Pista 1'
          ..validFrom = today()
          ..validUntil = inDays(60)),
      );
      final u = await repo.updateSchedule(
        s.id,
        ath.UpdateTrainingScheduleRequest((b) => b
          ..startTime = '11:00'
          ..clear = clearList({ath.UpdateTrainingScheduleRequestClearEnum.location: null, ath.UpdateTrainingScheduleRequestClearEnum.validUntil: null})),
      );
      expect([u.startTime, u.location, u.validUntil], ['11:00', isNull, isNull]);
      await repo.deleteSchedule(s.id);
      expect((await repo.schedules(teamId: team)).any((x) => x.id == s.id), isFalse);
    });

    test('planned absences: list, create, update with clear, delete', () async {
      final repo = ApiTrainingRepository(athlete, t);
      expect(await repo.absences(), isNotEmpty);
      final a = await repo.createAbsence(
        ath.PlannedAbsenceInput((b) => b
          ..playerId = 'p-ana'
          ..fromDate = inDays(30)
          ..toDate = inDays(32)
          ..reason = 'Viaje'),
      );
      expect((await repo.absences(playerId: 'p-ana')).any((x) => x.id == a.id), isTrue);
      final u = await repo.updateAbsence(a.id, ath.UpdatePlannedAbsenceRequest((b) => b..clear = clearList({ath.UpdatePlannedAbsenceRequestClearEnum.reason: null})));
      expect(u.reason, isNull);
      await repo.deleteAbsence(a.id);
      expect((await repo.absences(playerId: 'p-ana')).any((x) => x.id == a.id), isFalse);
    });
  });

  group('athlete: plans', () {
    test('templates, copy, items, reorder, update with clear, delete', () async {
      final repo = ApiPlansRepository(athlete, t);
      final templates = await repo.plans(templates: true);
      expect(templates, isNotEmpty);
      expect(templates.every((p) => p.template), isTrue);
      final copy = await repo.copyPlan(templates.first.id, name: 'Mi copia');
      expect((copy.name, copy.template, copy.sourceTemplateId), ('Mi copia', false, templates.first.id));
      expect((await repo.plans(templates: false)).any((p) => p.id == copy.id), isTrue);

      final item = await repo.addItem(copy.id, ath.PlanItemInput((b) => b..title = 'Tiros libres'..sets = 3));
      final changed = await repo.updateItem(
        copy.id,
        item.id,
        ath.UpdatePlanItemRequest((b) => b
          ..title = 'Libres'
          ..clear = clearList({ath.UpdatePlanItemRequestClearEnum.sets: null})),
      );
      expect([changed.title, changed.sets], ['Libres', isNull]);
      final full = await repo.plan(copy.id);
      final order = full.items.reversed.map((i) => i.id).toList();
      expect((await repo.reorder(copy.id, order)).map((i) => i.id), order);
      await repo.deleteItem(copy.id, item.id);
      final renamed = await repo.updatePlan(
        copy.id,
        ath.UpdateTrainingPlanRequest((b) => b
          ..name = 'Otra'
          ..clear = clearList({ath.UpdateTrainingPlanRequestClearEnum.description: null})),
      );
      expect([renamed.name, renamed.description], ['Otra', isNull]);
      await repo.deletePlan(copy.id);
      await expectLater(
        repo.plan(copy.id),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 404)),
      );
      final created = await repo.createPlan(ath.CreateTrainingPlanRequest((b) => b..name = 'Nuevo'));
      expect(created.itemCount, 0);
    });

    test('assignments and completions', () async {
      final repo = ApiPlansRepository(athlete, t);
      final seeded = await repo.assignments(teamId: team);
      expect(seeded, isNotEmpty);
      final plan = (await repo.plans(templates: false)).first;
      final a = await repo.assign(ath.CreatePlanAssignmentRequest((b) => b
        ..planId = plan.id
        ..playerId = 'p-leo'
        ..dueOn = inDays(7)));
      expect((await repo.assignments(playerId: 'p-leo')).any((x) => x.id == a.id), isTrue);
      final c = await repo.record(a.id, 'p-leo', ath.CompletionStatus.PARTIAL, comment: 'A medias');
      expect((c.status, c.comment), (ath.CompletionStatus.PARTIAL, 'A medias'));
      final again = await repo.record(a.id, 'p-leo', ath.CompletionStatus.DONE);
      expect(again.id, c.id, reason: 'one completion per player and assignment');
      expect((await repo.completions(assignmentId: a.id)).single.status, ath.CompletionStatus.DONE);
      await repo.deleteAssignment(a.id);
      expect((await repo.assignments(playerId: 'p-leo')).any((x) => x.id == a.id), isFalse);
    });
  });

  group('athlete: health and fitness', () {
    test('injuries: two seeded, filters, create, update with clear (recovered), delete', () async {
      final repo = ApiHealthRepository(athlete, t);
      final all = await repo.injuries();
      expect(all.length, greaterThanOrEqualTo(2));
      expect((await repo.injuries(status: ath.InjuryStatus.OPEN)).every((i) => i.status == ath.InjuryStatus.OPEN), isTrue);
      expect((await repo.injuries(playerId: 'p-leo')).every((i) => i.playerId == 'p-leo'), isTrue);
      final i = await repo.createInjury(ath.CreateInjuryRequest((b) => b
        ..playerId = 'p-ana'
        ..occurredOn = today()
        ..bodyPart = 'tobillo'
        ..severity = ath.InjurySeverity.MINOR
        ..description = 'Torcedura'
        ..expectedReturnOn = inDays(7)));
      final u = await repo.updateInjury(
        i.id,
        ath.UpdateInjuryRequest((b) => b
          ..status = ath.InjuryStatus.RECOVERED
          ..actualReturnOn = today()
          ..clear = clearList({ath.UpdateInjuryRequestClearEnum.expectedReturnOn: null, ath.UpdateInjuryRequestClearEnum.description: null})),
      );
      expect([u.status, u.expectedReturnOn, u.description], [ath.InjuryStatus.RECOVERED, isNull, isNull]);
      await repo.deleteInjury(i.id);
      expect((await repo.injuries()).any((x) => x.id == i.id), isFalse);
    });

    test('measurements: list per player, create, update with clear, delete', () async {
      final repo = ApiHealthRepository(athlete, t);
      expect((await repo.measurements('p-ana')).length, greaterThanOrEqualTo(2));
      final m = await repo.createMeasurement(ath.BodyMeasurementInput((b) => b
        ..playerId = 'p-ana'
        ..measuredOn = today()
        ..heightCm = 150
        ..weightKg = 40));
      final u = await repo.updateMeasurement(
        m.id,
        ath.UpdateBodyMeasurementRequest((b) => b..clear = clearList({ath.UpdateBodyMeasurementRequestClearEnum.weightKg: null})),
      );
      expect([u.heightCm, u.weightKg], [150, isNull]);
      await repo.deleteMeasurement(m.id);
      expect((await repo.measurements('p-ana')).any((x) => x.id == m.id), isFalse);
    });

    test('test types: global read-only, create, rename the code, clear, delete (WP39)', () async {
      final repo = ApiFitnessRepository(athlete, t);
      final types = await repo.types();
      expect(types.any((x) => x.global), isTrue);
      await expectLater(
        repo.deleteType(types.firstWhere((x) => x.global).id),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 404)),
      );
      final created = await repo.createType(ath.PhysicalTestTypeInput((b) => b
        ..code = 'PLANK'
        ..name = 'Plancha'
        ..unit = 's'
        ..higherIsBetter = true
        ..description = 'Aguantar'));
      await expectLater(
        repo.createType(ath.PhysicalTestTypeInput((b) => b
          ..code = 'PLANK'
          ..name = 'Otra'
          ..unit = 's'
          ..higherIsBetter = true)),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 409)),
      );
      final renamed = await repo.updateType(
        created.id,
        ath.UpdatePhysicalTestTypeRequest((b) => b
          ..code = 'PLANK_60'
          ..clear = clearList({ath.UpdatePhysicalTestTypeRequestClearEnum.description: null})),
      );
      expect([renamed.code, renamed.description], ['PLANK_60', isNull]);
      await repo.deleteType(created.id);
      expect((await repo.types()).any((x) => x.id == created.id), isFalse);
    });

    test('results: a few seeded with their band, create is banded, update with clear, delete', () async {
      final repo = ApiFitnessRepository(athlete, t);
      final results = await repo.results();
      expect(results.length, greaterThanOrEqualTo(3));
      expect(results.any((r) => r.bandStatus == ath.BandStatus.MATCHED && r.expectedBand != null), isTrue);
      expect((await repo.results(playerId: 'p-ana')).every((r) => r.playerId == 'p-ana'), isTrue);
      final type = (await repo.types()).first;
      final r = await repo.createResult(ath.PhysicalTestResultInput((b) => b
        ..playerId = 'p-ana'
        ..testTypeId = type.id
        ..measuredOn = today()
        ..value = 3.5
        ..notes = 'Seco'));
      expect((r.testCode, r.unit), (type.code, type.unit));
      final u = await repo.updateResult(
        r.id,
        ath.UpdatePhysicalTestResultRequest((b) => b
          ..value = 3.4
          ..clear = clearList({ath.UpdatePhysicalTestResultRequestClearEnum.notes: null})),
      );
      expect([u.value, u.notes], [3.4, isNull]);
      await repo.deleteResult(r.id);
      expect((await repo.results(testTypeId: type.id)).any((x) => x.id == r.id), isFalse);
    });

    test('norms: effective / global / tenant scopes, create, replace, delete', () async {
      final repo = ApiFitnessRepository(athlete, t);
      final type = (await repo.types()).first;
      expect(await repo.norms(testTypeId: type.id), isNotEmpty);
      expect((await repo.norms(scope: 'GLOBAL')).every((n) => n.global), isTrue);
      expect(await repo.norms(scope: 'TENANT'), isEmpty);
      final input = ath.PhysicalTestNormInput((b) => b
        ..testTypeId = type.id
        ..gender = ath.Gender.FEMALE
        ..minAge = 10
        ..maxAge = 11
        ..band = ath.NormBand.AVERAGE
        ..minValue = 3
        ..maxValue = 4);
      final n = await repo.createNorm(input);
      expect((n.global, n.referencePending), (false, true));
      final r = await repo.replaceNorm(n.id, input.rebuild((b) => b..source_ = 'Estudio X'));
      expect((r.source_, r.referencePending), ('Estudio X', false));
      expect(await repo.norms(scope: 'TENANT'), hasLength(1));
      await repo.deleteNorm(n.id);
      expect(await repo.norms(scope: 'TENANT'), isEmpty);
    });
  });

  test('athlete routes are for the demo academy only', () async {
    await expectLater(
      ApiHealthRepository(athlete, mockTenantBId).injuries(),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 404)),
    );
  });
}
