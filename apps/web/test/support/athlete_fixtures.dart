import 'package:hoops_app/core/api/athlete_api.dart' as ath;

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

/// A planned absence, by default from 10 to 12 November 2026.
ath.PlannedAbsence absence(
  String id,
  String playerId, {
  String? reason,
  ath.Date? from,
  ath.Date? to,
}) => ath.PlannedAbsence(
  (b) => b
    ..id = id
    ..playerId = playerId
    ..fromDate = from ?? ath.Date(2026, 11, 10)
    ..toDate = to ?? ath.Date(2026, 11, 12)
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

/// A norm row; without a [source] its reference is pending.
ath.PhysicalTestNorm norm(
  String id,
  String typeId, {
  ath.NormBand band = ath.NormBand.AVERAGE,
  double? min,
  double? max,
  bool global = true,
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
    ..referencePending = source == null,
);

/// A stored result; the backend computes its age, band and reference flag
/// from the seeded norms and the player's birth date and gender.
ath.PhysicalTestResult testResult(
  String id,
  String playerId,
  ath.PhysicalTestType type,
  double value,
  ath.Date on,
) => ath.PhysicalTestResult(
  (b) => b
    ..id = id
    ..playerId = playerId
    ..testTypeId = type.id
    ..testCode = type.code
    ..unit = type.unit
    ..measuredOn = on
    ..value = value
    ..ageAtMeasurement = 11
    ..bandStatus = ath.BandStatus.NO_NORM
    ..referencePending = false
    ..recordedBy = _who.toBuilder()
    ..recordedAt = DateTime.utc(2026, 10, 1),
);
