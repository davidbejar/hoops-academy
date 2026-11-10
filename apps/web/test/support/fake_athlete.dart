import 'package:built_collection/built_collection.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/health/application/health_providers.dart';
import 'package:hoops_app/features/health/data/fitness_repository.dart';
import 'package:hoops_app/features/health/data/health_repository.dart';
import 'package:hoops_app/features/training/application/exercise_providers.dart';
import 'package:hoops_app/features/training/application/training_providers.dart';
import 'package:hoops_app/features/training/data/exercises_repository.dart';
import 'package:hoops_app/features/training/data/plans_repository.dart';
import 'package:hoops_app/features/training/data/training_repository.dart';

import 'fake_repos.dart' show Faulty;

/// An update field as the server applies it (ADR-0032): named in `clear` = null, null = unchanged.
T? patched<T, E>(BuiltSet<E>? clear, E name, T? value, T? current) =>
    (clear?.contains(name) ?? false) ? null : value ?? current;

// ------------------------------------------------------------------ fixtures

final _who = ath.PersonRef(
  (b) => b
    ..personId = 'person-coach'
    ..displayName = 'Casey Coach',
);

/// A session on [day] at [hour]:00 local time.
ath.TrainingSession session(
  String id, {
  String teamId = 't1',
  required DateTime day,
  int hour = 18,
  int minutes = 90,
  ath.TrainingSessionStatus status = ath.TrainingSessionStatus.PLANNED,
  String? location = 'Pabellón Norte',
  String? planId,
  String? notes,
  String? cancelReason,
}) => ath.TrainingSession(
  (b) => b
    ..id = id
    ..teamId = teamId
    ..startsAt = DateTime(day.year, day.month, day.day, hour).toUtc()
    ..durationMinutes = minutes
    ..location = location
    ..status = status
    ..planId = planId
    ..notes = notes
    ..cancelReason = cancelReason,
);

ath.AttendanceEntry attEntry(
  String playerId, {
  ath.AttendanceStatus? status,
  int? late,
  bool expected = false,
  String? injuryId,
}) => ath.AttendanceEntry(
  (b) => b
    ..playerId = playerId
    ..status = status
    ..minutesLate = late
    ..expectedAbsent = expected
    ..unavailableInjuryId = injuryId,
);

ath.TrainingSchedule schedule(
  String id, {
  String teamId = 't1',
  ath.DayOfWeek day = ath.DayOfWeek.TUESDAY,
  String time = '18:00:00',
  int minutes = 90,
  String? location = 'Pabellón Norte',
}) => ath.TrainingSchedule(
  (b) => b
    ..id = id
    ..teamId = teamId
    ..dayOfWeek = day
    ..startTime = time
    ..durationMinutes = minutes
    ..location = location
    ..validFrom = ath.Date(2026, 9, 1),
);

ath.PlannedAbsence absence(String id, String playerId, {String? reason}) =>
    ath.PlannedAbsence(
      (b) => b
        ..id = id
        ..playerId = playerId
        ..fromDate = ath.Date(2026, 11, 10)
        ..toDate = ath.Date(2026, 11, 12)
        ..reason = reason
        ..recordedBy = _who.toBuilder()
        ..recordedAt = DateTime.utc(2026, 11, 1),
    );

ath.PlanItem planItem(
  String id,
  String title,
  int position, {
  int? minutes,
  int? sets,
  int? reps,
  String? video,
  String? exerciseId,
}) => ath.PlanItem(
  (b) => b
    ..id = id
    ..position = position
    ..title = title
    ..durationMinutes = minutes
    ..sets = sets
    ..repetitions = reps
    ..videoUrl = video
    ..exerciseId = exerciseId,
);

/// A catalogue exercise (athlete 3.0.0): [global] ones are the platform's.
ath.Exercise exercise(
  String id,
  String title, {
  bool global = false,
  bool archived = false,
  String? description,
  int? minutes,
  int? sets,
  int? reps,
  String? video,
}) => ath.Exercise(
  (b) => b
    ..id = id
    ..title = title
    ..description = description
    ..durationMinutes = minutes
    ..sets = sets
    ..repetitions = reps
    ..videoUrl = video
    ..global = global
    ..nameKey = global ? id : null
    ..archived = archived,
);

/// What a quick-add appends for [source] (athlete 3.0.0, before the server
/// gives it an id and a position): a catalogue exercise becomes an item that
/// references it; an item of a plan is copied with its own reference.
ath.PlanItem quickAddCopy(
  ath.PlanItemSource source, {
  required List<ath.TrainingPlan> plans,
  required List<ath.Exercise> exercises,
}) {
  final exerciseId = source.exerciseId;
  if (exerciseId != null) {
    final e = exercises.firstWhere((e) => e.id == exerciseId);
    return planItem(
      e.id,
      e.title,
      0,
      minutes: e.durationMinutes,
      sets: e.sets,
      reps: e.repetitions,
      video: e.videoUrl,
      exerciseId: e.id,
    ).rebuild((b) => b..description = e.description);
  }
  return plans
      .firstWhere((p) => p.id == source.planId)
      .items
      .firstWhere((i) => i.id == source.itemId);
}

ath.TrainingPlan planOf(
  String id,
  String name, {
  bool template = false,
  List<ath.PlanItem> items = const [],
  String? description,
  String? sessionId,
}) => ath.TrainingPlan(
  (b) => b
    ..id = id
    ..name = name
    ..description = description
    ..template = template
    ..sessionId = sessionId
    ..itemCount = items.length
    ..totalDurationMinutes = items.fold<int>(
      0,
      (s, i) => s + (i.durationMinutes ?? 0),
    )
    ..items.replace(items),
);

ath.TrainingPlanSummary summaryOf(ath.TrainingPlan p) =>
    ath.TrainingPlanSummary(
      (b) => b
        ..id = p.id
        ..name = p.name
        ..description = p.description
        ..template = p.template
        ..sessionId = p.sessionId
        ..itemCount = p.itemCount
        ..totalDurationMinutes = p.totalDurationMinutes,
    );

ath.PlanAssignment assignmentOf(
  String id,
  ath.TrainingPlan p, {
  String? teamId,
  String? playerId,
  ath.Date? due,
  String? notes,
}) => ath.PlanAssignment(
  (b) => b
    ..id = id
    ..plan.replace(summaryOf(p))
    ..teamId = teamId
    ..playerId = playerId
    ..dueOn = due ?? ath.Date(2026, 11, 20)
    ..notes = notes
    ..recordedBy = _who.toBuilder()
    ..recordedAt = DateTime.utc(2026, 11, 1),
);

ath.PlanCompletion completionOf(
  String id,
  String assignmentId,
  String playerId,
  ath.CompletionStatus status, {
  String? comment,
}) => ath.PlanCompletion(
  (b) => b
    ..id = id
    ..assignmentId = assignmentId
    ..playerId = playerId
    ..status = status
    ..comment = comment
    ..recordedBy = _who.toBuilder()
    ..recordedAt = DateTime.utc(2026, 11, 1),
);

ath.Injury injury(
  String id,
  String playerId, {
  String part = 'Rodilla',
  ath.InjurySeverity severity = ath.InjurySeverity.MODERATE,
  ath.InjuryStatus status = ath.InjuryStatus.OPEN,
  ath.Date? expected,
  ath.Date? actual,
}) => ath.Injury(
  (b) => b
    ..id = id
    ..playerId = playerId
    ..bodyPart = part
    ..severity = severity
    ..status = status
    ..occurredOn = ath.Date(2026, 10, 20)
    ..expectedReturnOn = expected
    ..actualReturnOn = actual
    ..recordedBy = _who.toBuilder()
    ..recordedAt = DateTime.utc(2026, 10, 20),
);

ath.BodyMeasurement measurement(
  String id,
  String playerId,
  ath.Date on, {
  double? height,
  double? weight,
}) => ath.BodyMeasurement(
  (b) => b
    ..id = id
    ..playerId = playerId
    ..measuredOn = on
    ..heightCm = height
    ..weightKg = weight
    ..recordedBy = _who.toBuilder()
    ..recordedAt = DateTime.utc(2026, 10, 1),
);

ath.PhysicalTestType testType(
  String id,
  String code,
  String name,
  String unit, {
  bool global = true,
  bool higher = true,
}) => ath.PhysicalTestType(
  (b) => b
    ..id = id
    ..code = code
    ..name = name
    ..unit = unit
    ..higherIsBetter = higher
    ..global = global,
);

ath.PhysicalTestNorm norm(
  String id,
  String typeId, {
  ath.NormBand band = ath.NormBand.AVERAGE,
  double? min,
  double? max,
  bool global = true,
  bool pending = false,
  int minAge = 10,
  int maxAge = 12,
  ath.Gender gender = ath.Gender.MALE,
  String? source,
}) => ath.PhysicalTestNorm(
  (b) => b
    ..id = id
    ..testTypeId = typeId
    ..gender = gender
    ..minAge = minAge
    ..maxAge = maxAge
    ..band = band
    ..minValue = min
    ..maxValue = max
    ..source_ = source
    ..global = global
    ..referencePending = pending,
);

ath.PhysicalTestResult testResult(
  String id,
  String playerId,
  ath.PhysicalTestType type,
  double value,
  ath.Date on, {
  ath.NormBand? band,
  bool pending = false,
}) => ath.PhysicalTestResult(
  (b) => b
    ..id = id
    ..playerId = playerId
    ..testTypeId = type.id
    ..testCode = type.code
    ..unit = type.unit
    ..measuredOn = on
    ..value = value
    ..ageAtMeasurement = 11
    ..expectedBand = band
    ..bandStatus = band == null
        ? ath.BandStatus.NO_NORM
        : ath.BandStatus.MATCHED
    ..referencePending = pending
    ..recordedBy = _who.toBuilder()
    ..recordedAt = DateTime.utc(2026, 10, 1),
);

// --------------------------------------------------------------------- fakes

class FakeTrainingRepository with Faulty implements TrainingRepository {
  /// The plans quick-adds read from and write to (set by [FakeAthlete]).
  FakePlansRepository? plans;

  /// The catalogue quick-adds copy exercises from (set by [FakeAthlete]).
  FakeExercisesRepository? exercises;
  final List<List<ath.PlanItemSource>> quickAdded = [];

  /// Fails quick-adds only (a session is still created).
  Object? failCopyWith;

  FakeTrainingRepository({
    List<ath.TrainingSession>? sessions,
    List<ath.TrainingSchedule>? schedules,
    List<ath.PlannedAbsence>? absences,
    Map<String, List<ath.AttendanceEntry>>? attendance,
  }) : sessionList = sessions ?? [],
       scheduleList = schedules ?? [],
       absenceList = absences ?? [],
       attendanceBySession = attendance ?? {};

  final List<ath.TrainingSession> sessionList;
  final List<ath.TrainingSchedule> scheduleList;
  final List<ath.PlannedAbsence> absenceList;
  final Map<String, List<ath.AttendanceEntry>> attendanceBySession;
  final List<String> sessionQueries = [];
  ath.CreateTrainingSessionRequest? createdSession;
  ath.UpdateTrainingSessionRequest? updatedSession;
  List<ath.AttendanceInput>? recorded;
  String? cancelledReason;
  ath.TrainingScheduleInput? createdSchedule;
  ath.PlannedAbsenceInput? createdAbsence;
  ath.UpdatePlannedAbsenceRequest? updatedAbsence;
  ath.UpdateTrainingScheduleRequest? updatedSchedule;

  @override
  Future<List<ath.TrainingSession>> sessions({
    String? teamId,
    required ath.Date from,
    required ath.Date to,
  }) => run('sessions', () {
    sessionQueries.add('${teamId ?? '*'}:$from..$to');
    return [
      for (final s in sessionList)
        if ((teamId == null || s.teamId == teamId) &&
            !_day(s.startsAt).isBefore(from.toDateTime()) &&
            !_day(s.startsAt).isAfter(to.toDateTime()))
          s,
    ];
  });

  DateTime _day(DateTime t) {
    final l = t.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  @override
  Future<ath.TrainingSession> session(String sessionId) =>
      run('session', () => sessionList.firstWhere((s) => s.id == sessionId));

  /// Like athlete 3.0.0: copies go to the session's own plan, created on the
  /// first quick-add with the items of the plan it referenced.
  @override
  Future<ath.TrainingPlan> copyItemsToSession(
    String sessionId,
    List<ath.PlanItemSource> items,
  ) => run('copyItemsToSession', () {
    if (failCopyWith case final error?) throw error;
    quickAdded.add(items);
    final store = plans!;
    final index = sessionList.indexWhere((s) => s.id == sessionId);
    final session = sessionList[index];
    final current = store.planList
        .where((p) => p.id == session.planId)
        .firstOrNull;
    var own = current?.sessionId == sessionId
        ? current!
        : planOf(
            'own-$sessionId',
            current?.name ?? 'Sesión',
            items: current?.items.toList() ?? const [],
            sessionId: sessionId,
          );
    final copies = [
      for (final source in items)
        quickAddCopy(
          source,
          plans: store.planList,
          exercises: exercises?.exerciseList ?? const [],
        ),
    ];
    final all = [...own.items, ...copies];
    own = planOf(
      own.id,
      own.name,
      sessionId: sessionId,
      items: [
        for (var n = 0; n < all.length; n++)
          all[n].rebuild(
            (b) => b
              ..id = '${own.id}-i$n'
              ..position = n,
          ),
      ],
    );
    store.planList
      ..removeWhere((p) => p.id == own.id)
      ..add(own);
    sessionList[index] = session.rebuild((b) => b..planId = own.id);
    return own;
  });

  @override
  Future<ath.TrainingSession> createSession(
    ath.CreateTrainingSessionRequest request,
  ) => run('createSession', () {
    createdSession = request;
    final s = ath.TrainingSession(
      (b) => b
        ..id = 'new-${sessionList.length}'
        ..teamId = request.teamId
        ..startsAt = request.startsAt
        ..durationMinutes = request.durationMinutes
        ..location = request.location
        ..planId = request.planId
        ..status = ath.TrainingSessionStatus.PLANNED,
    );
    sessionList.add(s);
    return s;
  });

  @override
  Future<ath.TrainingSession> updateSession(
    String sessionId,
    ath.UpdateTrainingSessionRequest request,
  ) => run('updateSession', () {
    updatedSession = request;
    final i = sessionList.indexWhere((s) => s.id == sessionId);
    sessionList[i] = sessionList[i].rebuild(
      (b) => b
        ..startsAt = request.startsAt ?? b.startsAt
        ..durationMinutes = request.durationMinutes ?? b.durationMinutes
        ..location = patched(
          request.clear,
          ath.UpdateTrainingSessionRequestClearEnum.location,
          request.location,
          b.location,
        )
        ..planId = patched(
          request.clear,
          ath.UpdateTrainingSessionRequestClearEnum.planId,
          request.planId,
          b.planId,
        )
        ..notes = patched(
          request.clear,
          ath.UpdateTrainingSessionRequestClearEnum.notes,
          request.notes,
          b.notes,
        ),
    );
    return sessionList[i];
  });

  @override
  Future<ath.TrainingSession> cancelSession(String sessionId, String reason) =>
      run('cancelSession', () {
        cancelledReason = reason;
        final i = sessionList.indexWhere((s) => s.id == sessionId);
        sessionList[i] = sessionList[i].rebuild(
          (b) => b
            ..status = ath.TrainingSessionStatus.CANCELLED
            ..cancelReason = reason,
        );
        return sessionList[i];
      });

  @override
  Future<List<ath.TrainingSchedule>> schedules({String? teamId}) => run(
    'schedules',
    () => [
      for (final s in scheduleList)
        if (teamId == null || s.teamId == teamId) s,
    ],
  );

  @override
  Future<ath.TrainingSchedule> createSchedule(
    ath.TrainingScheduleInput input,
  ) => run('createSchedule', () {
    createdSchedule = input;
    final s = ath.TrainingSchedule(
      (b) => b
        ..id = 'sch-${scheduleList.length}'
        ..teamId = input.teamId
        ..dayOfWeek = input.dayOfWeek
        ..startTime = '${input.startTime}:00'
        ..durationMinutes = input.durationMinutes
        ..location = input.location
        ..validFrom = input.validFrom
        ..validUntil = input.validUntil,
    );
    scheduleList.add(s);
    return s;
  });

  @override
  Future<ath.TrainingSchedule> updateSchedule(
    String scheduleId,
    ath.UpdateTrainingScheduleRequest request,
  ) => run('updateSchedule', () {
    updatedSchedule = request;
    final i = scheduleList.indexWhere((s) => s.id == scheduleId);
    scheduleList[i] = scheduleList[i].rebuild(
      (b) => b
        ..dayOfWeek = request.dayOfWeek
        ..startTime = '${request.startTime}:00'
        ..durationMinutes = request.durationMinutes
        ..location = patched(
          request.clear,
          ath.UpdateTrainingScheduleRequestClearEnum.location,
          request.location,
          b.location,
        )
        ..validUntil = patched(
          request.clear,
          ath.UpdateTrainingScheduleRequestClearEnum.validUntil,
          request.validUntil,
          b.validUntil,
        ),
    );
    return scheduleList[i];
  });

  @override
  Future<void> deleteSchedule(String scheduleId) => run(
    'deleteSchedule',
    () => scheduleList.removeWhere((s) => s.id == scheduleId),
  );

  @override
  Future<ath.SessionAttendance> attendance(String sessionId) => run(
    'attendance',
    () => ath.SessionAttendance(
      (b) => b
        ..sessionId = sessionId
        ..entries.replace(attendanceBySession[sessionId] ?? const []),
    ),
  );

  @override
  Future<ath.SessionAttendance> recordAttendance(
    String sessionId,
    List<ath.AttendanceInput> entries,
  ) => run('recordAttendance', () {
    recorded = entries;
    attendanceBySession[sessionId] = [
      for (final e in entries)
        attEntry(e.playerId, status: e.status, late: e.minutesLate),
    ];
    return ath.SessionAttendance(
      (b) => b
        ..sessionId = sessionId
        ..entries.replace(attendanceBySession[sessionId]!),
    );
  });

  @override
  Future<List<ath.PlannedAbsence>> absences({
    String? playerId,
    String? teamId,
    ath.Date? from,
    ath.Date? to,
  }) => run(
    'absences',
    () => [
      for (final a in absenceList)
        if (playerId == null || a.playerId == playerId) a,
    ],
  );

  @override
  Future<ath.PlannedAbsence> createAbsence(ath.PlannedAbsenceInput input) =>
      run('createAbsence', () {
        createdAbsence = input;
        final a = absence(
          'abs-${absenceList.length}',
          input.playerId,
          reason: input.reason,
        );
        absenceList.add(a);
        return a;
      });

  @override
  Future<ath.PlannedAbsence> updateAbsence(
    String absenceId,
    ath.UpdatePlannedAbsenceRequest request,
  ) => run('updateAbsence', () {
    updatedAbsence = request;
    final i = absenceList.indexWhere((a) => a.id == absenceId);
    absenceList[i] = absenceList[i].rebuild(
      (b) => b
        ..fromDate = request.fromDate ?? b.fromDate
        ..toDate = request.toDate ?? b.toDate
        ..reason = patched(
          request.clear,
          ath.UpdatePlannedAbsenceRequestClearEnum.reason,
          request.reason,
          b.reason,
        ),
    );
    return absenceList[i];
  });

  @override
  Future<void> deleteAbsence(String absenceId) => run(
    'deleteAbsence',
    () => absenceList.removeWhere((a) => a.id == absenceId),
  );
}

class FakePlansRepository with Faulty implements PlansRepository {
  FakePlansRepository({
    List<ath.TrainingPlan>? plans,
    List<ath.PlanAssignment>? assignments,
    List<ath.PlanCompletion>? completions,
  }) : planList = plans ?? [],
       assignmentList = assignments ?? [],
       completionList = completions ?? [];

  final List<ath.TrainingPlan> planList;
  final List<ath.PlanAssignment> assignmentList;
  final List<ath.PlanCompletion> completionList;
  String? lastQuery;

  /// The catalogue quick-adds copy exercises from (set by [FakeAthlete]).
  FakeExercisesRepository? exercises;

  /// The sources of every quick-add into a plan, per call.
  final List<List<ath.PlanItemSource>> quickAdded = [];

  /// `Accept-Language` code of every plan read / copy, in call order (null = none given).
  final List<String?> languages = [];
  ath.CreatePlanAssignmentRequest? assigned;
  String? copiedFrom;

  ath.TrainingPlan _get(String id) => planList.firstWhere((p) => p.id == id);
  void _put(ath.TrainingPlan p) =>
      planList[planList.indexWhere((x) => x.id == p.id)] = p;

  ath.TrainingPlan _recount(ath.TrainingPlan p, List<ath.PlanItem> items) =>
      p.rebuild(
        (b) => b
          ..items.replace(items)
          ..itemCount = items.length
          ..totalDurationMinutes = items.fold<int>(
            0,
            (s, i) => s + (i.durationMinutes ?? 0),
          ),
      );

  /// Like athlete 2.3.0: a session's own plan is never listed; [query]
  /// matches the name or item titles, the latter reported in `matchedItems`.
  @override
  Future<List<ath.TrainingPlanSummary>> plans({
    required bool templates,
    String? query,
    String? language,
  }) => run('plans', () {
    lastQuery = query;
    languages.add(language);
    final q = query?.toLowerCase();
    return [
      for (final p in planList)
        if (p.template == templates && p.sessionId == null)
          if (q == null)
            summaryOf(p)
          else if (_matches(p, q) case final found
              when found.isNotEmpty || p.name.toLowerCase().contains(q))
            summaryOf(p).rebuild((b) {
              if (found.isNotEmpty) b.matchedItems.replace(found);
            }),
    ];
  });

  static List<ath.PlanItemMatch> _matches(ath.TrainingPlan p, String q) => [
    for (final i in p.items)
      if (i.title.toLowerCase().contains(q))
        ath.PlanItemMatch(
          (b) => b
            ..id = i.id
            ..planId = p.id
            ..title = i.title
            ..exerciseId = i.exerciseId,
        ),
  ];

  @override
  Future<ath.TrainingPlan> plan(String planId, {String? language}) =>
      run('plan', () {
        languages.add(language);
        return _get(planId);
      });

  @override
  Future<ath.TrainingPlan> createPlan(ath.CreateTrainingPlanRequest request) =>
      run('createPlan', () {
        final p = planOf(
          'plan-${planList.length}',
          request.name,
          description: request.description,
        );
        planList.add(p);
        return p;
      });

  @override
  Future<ath.TrainingPlan> updatePlan(
    String planId,
    ath.UpdateTrainingPlanRequest request,
  ) => run('updatePlan', () {
    _put(_get(planId).rebuild((b) => b..name = request.name ?? b.name));
    return _get(planId);
  });

  @override
  Future<void> deletePlan(String planId) =>
      run('deletePlan', () => planList.removeWhere((p) => p.id == planId));

  @override
  Future<ath.TrainingPlan> copyPlan(
    String planId, {
    String? name,
    String? language,
  }) => run('copyPlan', () {
    copiedFrom = planId;
    languages.add(language);
    final src = _get(planId);
    final copy = planOf(
      'copy-${planList.length}',
      name ?? src.name,
      items: src.items.toList(),
    );
    planList.add(copy);
    return copy;
  });

  @override
  Future<ath.PlanItem> addItem(String planId, ath.PlanItemInput input) =>
      run('addItem', () {
        final p = _get(planId);
        final item = planItem(
          'i-${p.items.length + 1}',
          input.title,
          p.items.length,
          minutes: input.durationMinutes,
          sets: input.sets,
          reps: input.repetitions,
          video: input.videoUrl,
        );
        _put(_recount(p, [...p.items, item]));
        return item;
      });

  @override
  Future<ath.PlanItem> updateItem(
    String planId,
    String itemId,
    ath.UpdatePlanItemRequest request,
  ) => run('updateItem', () {
    updatedItem = request;
    final p = _get(planId);
    final items = [
      for (final i in p.items)
        i.id == itemId
            ? i.rebuild(
                (b) => b
                  ..title = request.title ?? b.title
                  ..description = patched(
                    request.clear,
                    ath.UpdatePlanItemRequestClearEnum.description,
                    request.description,
                    b.description,
                  )
                  ..durationMinutes = patched(
                    request.clear,
                    ath.UpdatePlanItemRequestClearEnum.durationMinutes,
                    request.durationMinutes,
                    b.durationMinutes,
                  )
                  ..sets = patched(
                    request.clear,
                    ath.UpdatePlanItemRequestClearEnum.sets,
                    request.sets,
                    b.sets,
                  )
                  ..repetitions = patched(
                    request.clear,
                    ath.UpdatePlanItemRequestClearEnum.repetitions,
                    request.repetitions,
                    b.repetitions,
                  )
                  ..videoUrl = patched(
                    request.clear,
                    ath.UpdatePlanItemRequestClearEnum.videoUrl,
                    request.videoUrl,
                    b.videoUrl,
                  ),
              )
            : i,
    ];
    _put(_recount(p, items));
    return items.firstWhere((i) => i.id == itemId);
  });

  @override
  Future<void> deleteItem(String planId, String itemId) =>
      run('deleteItem', () {
        final p = _get(planId);
        _put(
          _recount(p, [
            for (final i in p.items)
              if (i.id != itemId) i,
          ]),
        );
      });

  /// Like athlete 3.0.0: copies of the sources at the end of the plan.
  @override
  Future<ath.TrainingPlan> copyItems(
    String planId,
    List<ath.PlanItemSource> items, {
    String? language,
  }) => run('copyItems', () {
    quickAdded.add(items);
    languages.add(language);
    final p = _get(planId);
    final copies = [
      for (final source in items)
        quickAddCopy(
          source,
          plans: planList,
          exercises: exercises?.exerciseList ?? const [],
        ),
    ];
    final first = p.items.length;
    _put(
      _recount(p, [
        ...p.items,
        for (var n = 0; n < copies.length; n++)
          copies[n].rebuild(
            (b) => b
              ..id = '$planId-c${first + n}'
              ..position = first + n,
          ),
      ]),
    );
    return _get(planId);
  });

  List<String>? lastOrder;
  ath.UpdatePlanItemRequest? updatedItem;

  @override
  Future<List<ath.PlanItem>> reorder(String planId, List<String> itemIds) =>
      run('reorder', () {
        lastOrder = itemIds;
        final p = _get(planId);
        final byId = {for (final i in p.items) i.id: i};
        final items = [
          for (var n = 0; n < itemIds.length; n++)
            byId[itemIds[n]]!.rebuild((b) => b.position = n),
        ];
        _put(_recount(p, items));
        return items;
      });

  @override
  Future<List<ath.PlanAssignment>> assignments({
    String? teamId,
    String? playerId,
  }) => run(
    'assignments',
    () => [
      for (final a in assignmentList)
        if (playerId == null || a.playerId == playerId || a.teamId != null) a,
    ],
  );

  @override
  Future<ath.PlanAssignment> assign(ath.CreatePlanAssignmentRequest request) =>
      run('assign', () {
        assigned = request;
        final a = assignmentOf(
          'as-${assignmentList.length}',
          _get(request.planId),
          teamId: request.teamId,
          playerId: request.playerId,
          due: request.dueOn,
          notes: request.notes,
        );
        assignmentList.add(a);
        return a;
      });

  @override
  Future<void> deleteAssignment(String assignmentId) => run(
    'deleteAssignment',
    () => assignmentList.removeWhere((a) => a.id == assignmentId),
  );

  @override
  Future<List<ath.PlanCompletion>> completions({
    String? assignmentId,
    String? playerId,
  }) => run(
    'completions',
    () => [
      for (final c in completionList)
        if ((assignmentId == null || c.assignmentId == assignmentId) &&
            (playerId == null || c.playerId == playerId))
          c,
    ],
  );

  ({
    String assignmentId,
    String playerId,
    ath.CompletionStatus status,
    String? comment,
  })?
  lastRecord;

  @override
  Future<ath.PlanCompletion> record(
    String assignmentId,
    String playerId,
    ath.CompletionStatus status, {
    String? comment,
  }) => run('record', () {
    lastRecord = (
      assignmentId: assignmentId,
      playerId: playerId,
      status: status,
      comment: comment,
    );
    completionList.removeWhere(
      (c) => c.assignmentId == assignmentId && c.playerId == playerId,
    );
    final c = completionOf(
      'c-${completionList.length}',
      assignmentId,
      playerId,
      status,
      comment: comment,
    );
    completionList.add(c);
    return c;
  });
}

class FakeHealthRepository with Faulty implements HealthRepository {
  FakeHealthRepository({
    List<ath.Injury>? injuries,
    List<ath.BodyMeasurement>? measurements,
  }) : injuryList = injuries ?? [],
       measurementList = measurements ?? [];

  final List<ath.Injury> injuryList;
  final List<ath.BodyMeasurement> measurementList;
  ath.CreateInjuryRequest? createdInjury;
  ath.UpdateInjuryRequest? lastInjuryUpdate;
  ath.BodyMeasurementInput? createdMeasurement;
  ath.UpdateBodyMeasurementRequest? updatedMeasurement;

  @override
  Future<List<ath.Injury>> injuries({
    String? playerId,
    String? teamId,
    ath.InjuryStatus? status,
  }) => run(
    'injuries',
    () => [
      for (final i in injuryList)
        if ((playerId == null || i.playerId == playerId) &&
            (status == null || i.status == status))
          i,
    ],
  );

  @override
  Future<ath.Injury> createInjury(ath.CreateInjuryRequest request) =>
      run('createInjury', () {
        createdInjury = request;
        final i = injury(
          'inj-${injuryList.length}',
          request.playerId,
          part: request.bodyPart,
          severity: request.severity,
          expected: request.expectedReturnOn,
        );
        injuryList.add(i);
        return i;
      });

  @override
  Future<ath.Injury> updateInjury(
    String injuryId,
    ath.UpdateInjuryRequest request,
  ) => run('updateInjury', () {
    lastInjuryUpdate = request;
    final n = injuryList.indexWhere((i) => i.id == injuryId);
    injuryList[n] = injuryList[n].rebuild((b) {
      if (request.occurredOn != null) b.occurredOn = request.occurredOn;
      if (request.bodyPart != null) b.bodyPart = request.bodyPart;
      if (request.severity != null) b.severity = request.severity;
      if (request.description != null) b.description = request.description;
      if (request.status != null) b.status = request.status;
      if (request.actualReturnOn != null)
        b.actualReturnOn = request.actualReturnOn;
      if (request.expectedReturnOn != null)
        b.expectedReturnOn = request.expectedReturnOn;
      final clear = request.clear?.toSet() ?? {};
      if (clear.contains(ath.UpdateInjuryRequestClearEnum.description))
        b.description = null;
      if (clear.contains(ath.UpdateInjuryRequestClearEnum.expectedReturnOn))
        b.expectedReturnOn = null;
      if (clear.contains(ath.UpdateInjuryRequestClearEnum.actualReturnOn))
        b.actualReturnOn = null;
    });
    return injuryList[n];
  });

  @override
  Future<void> deleteInjury(String injuryId) => run(
    'deleteInjury',
    () => injuryList.removeWhere((i) => i.id == injuryId),
  );

  @override
  Future<List<ath.BodyMeasurement>> measurements(String playerId) => run(
    'measurements',
    () => [
      for (final m in measurementList)
        if (m.playerId == playerId) m,
    ],
  );

  @override
  Future<ath.BodyMeasurement> createMeasurement(
    ath.BodyMeasurementInput input,
  ) => run('createMeasurement', () {
    createdMeasurement = input;
    final m = measurement(
      'm-${measurementList.length}',
      input.playerId,
      input.measuredOn,
      height: input.heightCm,
      weight: input.weightKg,
    );
    measurementList.add(m);
    return m;
  });

  @override
  Future<ath.BodyMeasurement> updateMeasurement(
    String id,
    ath.UpdateBodyMeasurementRequest request,
  ) => run('updateMeasurement', () {
    updatedMeasurement = request;
    final i = measurementList.indexWhere((m) => m.id == id);
    measurementList[i] = measurementList[i].rebuild(
      (b) => b
        ..measuredOn = request.measuredOn ?? b.measuredOn
        ..heightCm = patched(
          request.clear,
          ath.UpdateBodyMeasurementRequestClearEnum.heightCm,
          request.heightCm,
          b.heightCm,
        )
        ..weightKg = patched(
          request.clear,
          ath.UpdateBodyMeasurementRequestClearEnum.weightKg,
          request.weightKg,
          b.weightKg,
        ),
    );
    return measurementList[i];
  });

  @override
  Future<void> deleteMeasurement(String id) => run(
    'deleteMeasurement',
    () => measurementList.removeWhere((m) => m.id == id),
  );
}

class FakeFitnessRepository with Faulty implements FitnessRepository {
  FakeFitnessRepository({
    List<ath.PhysicalTestType>? types,
    List<ath.PhysicalTestNorm>? norms,
    List<ath.PhysicalTestResult>? results,
  }) : typeList = types ?? [],
       normList = norms ?? [],
       resultList = results ?? [];

  final List<ath.PhysicalTestType> typeList;
  final List<ath.PhysicalTestNorm> normList;
  final List<ath.PhysicalTestResult> resultList;
  final List<String> normScopes = [];
  ath.PhysicalTestNormInput? savedNorm;
  ath.PhysicalTestTypeInput? createdType;
  ath.UpdatePhysicalTestResultRequest? updatedResult;
  ath.UpdatePhysicalTestTypeRequest? updatedType;
  Object? deleteTypeError;

  @override
  Future<List<ath.PhysicalTestType>> types() =>
      run('types', () => [...typeList]);

  @override
  Future<ath.PhysicalTestType> createType(ath.PhysicalTestTypeInput input) =>
      run('createType', () {
        createdType = input;
        final t = testType(
          'type-${typeList.length}',
          input.code,
          input.name,
          input.unit,
          global: false,
          higher: input.higherIsBetter,
        );
        typeList.add(t);
        return t;
      });

  @override
  Future<ath.PhysicalTestType> updateType(
    String id,
    ath.UpdatePhysicalTestTypeRequest request,
  ) => run('updateType', () {
    updatedType = request;
    final i = typeList.indexWhere((t) => t.id == id);
    typeList[i] = typeList[i].rebuild(
      (b) => b
        ..code = request.code ?? b.code
        ..name = request.name ?? b.name
        ..unit = request.unit ?? b.unit
        ..higherIsBetter = request.higherIsBetter ?? b.higherIsBetter
        ..description = patched(
          request.clear,
          ath.UpdatePhysicalTestTypeRequestClearEnum.description,
          request.description,
          b.description,
        ),
    );
    return typeList[i];
  });

  /// Like the server: a type that results use is a 409 `TEST_TYPE_HAS_RESULTS` (set [deleteTypeError] to override).
  @override
  Future<void> deleteType(String id) => run('deleteType', () {
    if (deleteTypeError != null) throw deleteTypeError!;
    typeList.removeWhere((t) => t.id == id);
  });

  @override
  Future<List<ath.PhysicalTestResult>> results({
    String? playerId,
    String? teamId,
    String? testTypeId,
  }) => run(
    'results',
    () => [
      for (final r in resultList)
        if ((playerId == null || r.playerId == playerId) &&
            (testTypeId == null || r.testTypeId == testTypeId))
          r,
    ],
  );

  @override
  Future<ath.PhysicalTestResult> createResult(
    ath.PhysicalTestResultInput input,
  ) => run('createResult', () {
    final type = typeList.firstWhere((t) => t.id == input.testTypeId);
    ath.PhysicalTestNorm? hit;
    for (final n in normList) {
      if (n.testTypeId == type.id &&
          (n.minValue ?? double.negativeInfinity) <= input.value &&
          input.value < (n.maxValue ?? double.infinity)) {
        hit = n;
      }
    }
    final r = testResult(
      'res-${resultList.length}',
      input.playerId,
      type,
      input.value,
      input.measuredOn,
      band: hit?.band,
      pending: hit?.referencePending ?? false,
    );
    resultList.add(r);
    return r;
  });

  @override
  Future<ath.PhysicalTestResult> updateResult(
    String id,
    ath.UpdatePhysicalTestResultRequest request,
  ) => run('updateResult', () {
    updatedResult = request;
    final i = resultList.indexWhere((r) => r.id == id);
    resultList[i] = resultList[i].rebuild(
      (b) => b
        ..measuredOn = request.measuredOn ?? b.measuredOn
        ..value = request.value ?? b.value
        ..notes = patched(
          request.clear,
          ath.UpdatePhysicalTestResultRequestClearEnum.notes,
          request.notes,
          b.notes,
        ),
    );
    return resultList[i];
  });

  @override
  Future<void> deleteResult(String id) =>
      run('deleteResult', () => resultList.removeWhere((r) => r.id == id));

  @override
  Future<List<ath.PhysicalTestNorm>> norms({
    String? testTypeId,
    ath.Gender? gender,
    String scope = 'EFFECTIVE',
  }) => run('norms', () {
    normScopes.add(scope);
    return [
      for (final n in normList)
        if ((testTypeId == null || n.testTypeId == testTypeId) &&
            (scope == 'EFFECTIVE' ||
                (scope == 'GLOBAL' && n.global) ||
                (scope == 'TENANT' && !n.global)))
          n,
    ];
  });

  @override
  Future<ath.PhysicalTestNorm> createNorm(ath.PhysicalTestNormInput input) =>
      run('createNorm', () {
        savedNorm = input;
        final n = norm(
          'norm-${normList.length}',
          input.testTypeId,
          band: input.band,
          min: input.minValue,
          max: input.maxValue,
          global: false,
          minAge: input.minAge,
          maxAge: input.maxAge,
          gender: input.gender,
          source: input.source_,
          pending: input.source_ == null,
        );
        normList.add(n);
        return n;
      });

  @override
  Future<ath.PhysicalTestNorm> replaceNorm(
    String id,
    ath.PhysicalTestNormInput input,
  ) => run('replaceNorm', () {
    savedNorm = input;
    final i = normList.indexWhere((n) => n.id == id);
    normList[i] = norm(
      id,
      input.testTypeId,
      band: input.band,
      min: input.minValue,
      max: input.maxValue,
      global: false,
      minAge: input.minAge,
      maxAge: input.maxAge,
      gender: input.gender,
      source: input.source_,
      pending: input.source_ == null,
    );
    return normList[i];
  });

  @override
  Future<void> deleteNorm(String id) =>
      run('deleteNorm', () => normList.removeWhere((n) => n.id == id));
}

/// One `listExercises` call as the server gets it.
typedef ExerciseQuery = ({
  String? query,
  ath.ExerciseScope? scope,
  bool includeArchived,
  int page,
  int size,
  String? language,
});

/// The catalogue order: the shown title, case-insensitive, then the id.
int byTitleThenId(ath.Exercise a, ath.Exercise b) {
  final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
}

/// The exercise catalogue like athlete 3.0.0: ordered by title (then id),
/// `query` a part of the title, archived ones only on request, paged.
class FakeExercisesRepository with Faulty implements ExercisesRepository {
  FakeExercisesRepository({List<ath.Exercise>? exercises})
    : exerciseList = exercises ?? [];

  final List<ath.Exercise> exerciseList;
  final List<ExerciseQuery> queries = [];
  ath.ExerciseInput? created;
  ath.UpdateExerciseRequest? updated;

  @override
  Future<ath.ExercisePage> exercises({
    String? query,
    ath.ExerciseScope? scope,
    bool includeArchived = false,
    int page = 0,
    int size = 50,
    String? language,
  }) => run('exercises', () {
    queries.add((
      query: query,
      scope: scope,
      includeArchived: includeArchived,
      page: page,
      size: size,
      language: language,
    ));
    final q = query?.toLowerCase();
    final found = [
      for (final e in exerciseList)
        if ((includeArchived || !e.archived) &&
            (scope == null ||
                e.global == (scope == ath.ExerciseScope.GLOBAL)) &&
            (q == null || e.title.toLowerCase().contains(q)))
          e,
    ]..sort(byTitleThenId);
    final from = (page * size).clamp(0, found.length);
    final to = (from + size).clamp(0, found.length);
    return ath.ExercisePage(
      (b) => b
        ..items.replace(found.sublist(from, to))
        ..page.page = page
        ..page.size = size
        ..page.totalElements = found.length
        ..page.totalPages = (found.length + size - 1) ~/ size,
    );
  });

  ath.Exercise _put(String id, ath.Exercise Function(ath.Exercise) change) {
    final i = exerciseList.indexWhere((e) => e.id == id);
    return exerciseList[i] = change(exerciseList[i]);
  }

  @override
  Future<ath.Exercise> create(ath.ExerciseInput input) => run('create', () {
    created = input;
    final e = exercise(
      'own-${exerciseList.length}',
      input.title,
      description: input.description,
      minutes: input.durationMinutes,
      sets: input.sets,
      reps: input.repetitions,
      video: input.videoUrl,
    );
    exerciseList.add(e);
    return e;
  });

  @override
  Future<ath.Exercise> update(
    String exerciseId,
    ath.UpdateExerciseRequest request,
  ) => run('update', () {
    updated = request;
    final clear = request.clear;
    return _put(
      exerciseId,
      (e) => e.rebuild(
        (b) => b
          ..title = request.title ?? b.title
          ..description = patched(
            clear,
            ath.UpdateExerciseRequestClearEnum.description,
            request.description,
            b.description,
          )
          ..durationMinutes = patched(
            clear,
            ath.UpdateExerciseRequestClearEnum.durationMinutes,
            request.durationMinutes,
            b.durationMinutes,
          )
          ..sets = patched(
            clear,
            ath.UpdateExerciseRequestClearEnum.sets,
            request.sets,
            b.sets,
          )
          ..repetitions = patched(
            clear,
            ath.UpdateExerciseRequestClearEnum.repetitions,
            request.repetitions,
            b.repetitions,
          )
          ..videoUrl = patched(
            clear,
            ath.UpdateExerciseRequestClearEnum.videoUrl,
            request.videoUrl,
            b.videoUrl,
          ),
      ),
    );
  });

  @override
  Future<ath.Exercise> archive(String exerciseId) => run(
    'archive',
    () => _put(exerciseId, (e) => e.rebuild((b) => b..archived = true)),
  );

  @override
  Future<ath.Exercise> unarchive(String exerciseId) => run(
    'unarchive',
    () => _put(exerciseId, (e) => e.rebuild((b) => b..archived = false)),
  );
}

/// All athlete-service fakes; plug into the Harness like `FakeGame`.
class FakeAthlete {
  FakeAthlete({
    FakeTrainingRepository? training,
    FakePlansRepository? plans,
    FakeExercisesRepository? exercises,
    FakeHealthRepository? health,
    FakeFitnessRepository? fitness,
  }) : training = training ?? FakeTrainingRepository(),
       plans = plans ?? FakePlansRepository(),
       exercises = exercises ?? FakeExercisesRepository(),
       health = health ?? FakeHealthRepository(),
       fitness = fitness ?? FakeFitnessRepository() {
    this.training
      ..plans = this.plans
      ..exercises = this.exercises;
    this.plans.exercises = this.exercises;
  }

  final FakeTrainingRepository training;
  final FakePlansRepository plans;
  final FakeExercisesRepository exercises;
  final FakeHealthRepository health;
  final FakeFitnessRepository fitness;

  List<Override> get overrides => [
    trainingRepositoryProvider.overrideWithValue(training),
    plansRepositoryProvider.overrideWithValue(plans),
    exercisesRepositoryProvider.overrideWithValue(exercises),
    healthRepositoryProvider.overrideWithValue(health),
    fitnessRepositoryProvider.overrideWithValue(fitness),
  ];
}
