import 'dart:collection';
import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/mock/mock_athlete_api.dart';
import 'package:hoops_app/features/training/application/exercise_providers.dart';
import 'package:hoops_app/features/training/data/exercises_repository.dart';

import 'core_seed.dart' show injectInto;
import 'mock_backend.dart';

/// [value] (an athlete model) as the service sends it, for seeding the mock
/// (a fresh, growable copy the mock may change).
Map<String, Object?> athleteJson<T>(T value) => (jsonDecode(
  jsonEncode(
    ath.standardSerializers.serialize(value, specifiedType: FullType(T)),
  ),
) as Map).cast<String, Object?>();

/// A stored row or a request body of the athlete mock as a model.
T athleteModel<T>(Object? json) =>
    ath.standardSerializers.deserialize(json, specifiedType: FullType(T)) as T;

/// What the athlete data classes share (ADR-0070): seeded into the backend's
/// athlete mock once, failures and hangs injected in front of the paths of
/// their repository, the bodies the app sent read back as models.
abstract class _AthleteData {
  _AthleteData(this._paths);

  /// Every path of the repository (where [failWith] and [hang] apply).
  final Pattern _paths;

  MockBackend? _backend;
  MockBackend get _b => _backend!;
  MockAthleteApi get _mock => _b.academyApis.athlete;
  bool get _seeded => _backend != null;

  final List<Object> _pending = [];
  bool _hang = false;
  void Function()? _release;

  void seedInto(MockBackend backend) {
    _backend = backend;
    _seedRows(backend.academyApis.athlete);
    if (_hang) _release = backend.hang(_paths);
    for (final e in _pending) {
      injectInto(backend, e, _paths);
    }
  }

  void _seedRows(MockAthleteApi mock);

  /// Fails every call of the repository with [error] instead of an earlier
  /// one (null: heals).
  set failWith(Object? error) {
    _pending.clear();
    _backend?.heal(_paths);
    if (error == null) return;
    _seeded ? injectInto(_b, error, _paths) : _pending.add(error);
  }

  /// Holds every call of the repository (the loading state) until set back
  /// to false.
  set hang(bool value) {
    _hang = value;
    if (!_seeded) return;
    if (value) {
      _release = _b.hang(_paths);
    } else {
      _release?.call();
      _release = null;
    }
  }

  /// The body of the last [method] request to [path] as a [T] (null: none).
  T? _lastSent<T>(Pattern path, String method) {
    final sent = _b.requestsTo(path, method: method);
    return sent.isEmpty ? null : athleteModel<T>(MockBackend.bodyOf(sent.last));
  }

  /// [seed] before seeding, afterwards the mock's [rows] as models.
  List<T> _rows<T>(List<T> seed, List<Map<String, Object?>> Function() rows) =>
      _seeded ? [for (final r in rows()) athleteModel<T>(r)] : seed;
}

/// What [_all] returns from the backend [_source] names, read-only; [clear]
/// forgets what is there (later reads list only what came after, until the
/// data is seeded into another backend).
class _Since<T> extends ListBase<T> {
  _Since(this._source, this._all);

  final Object? Function() _source;
  final List<T> Function() _all;
  var _from = 0;
  Object? _clearedOn;

  List<T> get _now =>
      _all().skip(identical(_clearedOn, _source()) ? _from : 0).toList();

  @override
  int get length => _now.length;

  @override
  set length(int value) {
    if (value != 0) throw UnsupportedError('only clear()');
    _from = _all().length;
    _clearedOn = _source();
  }

  @override
  T operator [](int index) => _now[index];

  @override
  void operator []=(int index, T value) => throw UnsupportedError('read-only');
}

/// One read of the catalogue as the app asked for it.
typedef ExerciseQuery = ({
  String? query,
  ath.ExerciseScope? scope,
  bool includeArchived,
  int page,
  int size,
  String? language,
});

/// The exercise catalogue of a test (ADR-0070): seeded into the backend's
/// athlete mock, then what the app asked of it and what it holds. Failures
/// go to the backend.
class ExercisesData extends _AthleteData {
  ExercisesData([List<ath.Exercise> exercises = const []])
    : _seed = [...exercises],
      super(RegExp('^/api/athlete/exercises'));

  final List<ath.Exercise> _seed;

  static const _list = '/api/athlete/exercises';
  static final _one = RegExp(r'^/api/athlete/exercises/[^/:]+$');

  @override
  void _seedRows(MockAthleteApi mock) =>
      mock.exercises.addAll(_seed.map(athleteJson<ath.Exercise>));

  /// The catalogue: before seeding the seed, afterwards the mock's.
  List<ath.Exercise> get exerciseList => _rows(_seed, () => _mock.exercises);

  /// Replaces the catalogue (before or after seeding).
  set exerciseList(List<ath.Exercise> exercises) {
    _seed
      ..clear()
      ..addAll(exercises);
    _backend?.academyApis.athlete.exercises
      ?..clear()
      ..addAll(exercises.map(athleteJson<ath.Exercise>));
  }

  /// Every read of the catalogue, in order.
  List<ExerciseQuery> get queries => [
    for (final r in _b.requestsTo(_list))
      (
        query: r.queryParameters['q'] as String?,
        scope: r.queryParameters['scope'] == null
            ? null
            : ath.ExerciseScope.valueOf('${r.queryParameters['scope']}'),
        includeArchived: '${r.queryParameters['includeArchived']}' == 'true',
        page: int.parse('${r.queryParameters['page'] ?? 0}'),
        size: int.parse('${r.queryParameters['size'] ?? 50}'),
        language: r.headers['Accept-Language'] as String?,
      ),
  ];

  /// The last exercise the app created (null: none).
  ath.ExerciseInput? get created => _lastSent(_list, 'POST');

  /// The id the mock gave the last exercise created.
  String get createdId =>
      (_b.lastAnswer(_list, method: 'POST')! as Map)['id']! as String;

  /// The last change the app sent (null: none).
  ath.UpdateExerciseRequest? get updated => _lastSent(_one, 'PATCH');

  /// The writes the app sent, in order: `create`, `update`, `archive`,
  /// `unarchive`.
  List<String> get writes => [
    for (final r in _b.requestsTo(_paths, method: null))
      if (r.method == 'POST' && r.path == _list)
        'create'
      else if (r.method == 'PATCH')
        'update'
      else if (r.path.endsWith(':archive'))
        'archive'
      else if (r.path.endsWith(':unarchive'))
        'unarchive',
  ];

  /// The app's exercises repository on the backend, for tests of the
  /// providers without the app.
  List<Override> get overrides => [
    exercisesRepositoryProvider.overrideWithValue(
      ApiExercisesRepository(_b.athleteApi(), _b.tenantAId),
    ),
  ];
}

/// The injuries and body measurements of a test (ADR-0070): seeded into the
/// backend's athlete mock, then what it holds and what the app sent.
class HealthData extends _AthleteData {
  HealthData({
    List<ath.Injury> injuries = const [],
    List<ath.BodyMeasurement> measurements = const [],
  }) : _injuries = [...injuries],
       _measurements = [...measurements],
       super(RegExp('^/api/athlete/(injuries|body-measurements)'));

  final List<ath.Injury> _injuries;
  final List<ath.BodyMeasurement> _measurements;

  static const _injuryList = '/api/athlete/injuries';
  static final _injury = RegExp(r'^/api/athlete/injuries/[^/]+$');
  static const _measurementList = '/api/athlete/body-measurements';
  static final _measurement = RegExp(r'^/api/athlete/body-measurements/[^/]+$');

  @override
  void _seedRows(MockAthleteApi mock) {
    mock.injuries.addAll(_injuries.map(athleteJson<ath.Injury>));
    mock.measurements.addAll(
      _measurements.map(athleteJson<ath.BodyMeasurement>),
    );
  }

  /// The injuries: before seeding the seed (to change), afterwards the
  /// mock's.
  List<ath.Injury> get injuryList => _rows(_injuries, () => _mock.injuries);

  /// The measurements: before seeding the seed, afterwards the mock's.
  List<ath.BodyMeasurement> get measurementList =>
      _rows(_measurements, () => _mock.measurements);

  /// The last injury the app recorded (null: none).
  ath.CreateInjuryRequest? get createdInjury => _lastSent(_injuryList, 'POST');

  /// The last change of an injury the app sent (null: none).
  ath.UpdateInjuryRequest? get lastInjuryUpdate => _lastSent(_injury, 'PATCH');

  /// The last measurement the app recorded (null: none).
  ath.BodyMeasurementInput? get createdMeasurement =>
      _lastSent(_measurementList, 'POST');

  /// The last change of a measurement the app sent (null: none).
  ath.UpdateBodyMeasurementRequest? get updatedMeasurement =>
      _lastSent(_measurement, 'PATCH');
}

/// The physical tests of a test (ADR-0070): types, norms and results seeded
/// into the backend's athlete mock, which computes each result's age, band and
/// reference flag from the norms (seed norms that put a result in the band
/// the test expects); then what it holds and what the app sent.
class FitnessData extends _AthleteData {
  FitnessData({
    List<ath.PhysicalTestType> types = const [],
    List<ath.PhysicalTestNorm> norms = const [],
    List<ath.PhysicalTestResult> results = const [],
  }) : _types = [...types],
       _norms = [...norms],
       _results = [...results],
       super(RegExp('^/api/athlete/physical-test-(types|norms|results)'));

  final List<ath.PhysicalTestType> _types;
  final List<ath.PhysicalTestNorm> _norms;
  final List<ath.PhysicalTestResult> _results;

  static const _typeList = '/api/athlete/physical-test-types';
  static final _type = RegExp(r'^/api/athlete/physical-test-types/[^/]+$');
  static final _normPaths = RegExp('^/api/athlete/physical-test-norms');
  static const _normList = '/api/athlete/physical-test-norms';
  static final _result = RegExp(r'^/api/athlete/physical-test-results/[^/]+$');

  @override
  void _seedRows(MockAthleteApi mock) {
    mock.testTypes.addAll(_types.map(athleteJson<ath.PhysicalTestType>));
    mock.norms.addAll(_norms.map(athleteJson<ath.PhysicalTestNorm>));
    mock.results.addAll(_results.map(athleteJson<ath.PhysicalTestResult>));
  }

  /// The test types: before seeding the seed (to change), afterwards the
  /// mock's.
  List<ath.PhysicalTestType> get typeList =>
      _rows(_types, () => _mock.testTypes);

  /// The norms: before seeding the seed, afterwards the mock's.
  List<ath.PhysicalTestNorm> get normList => _rows(_norms, () => _mock.norms);

  /// The results: before seeding the seed (to change), afterwards the mock's
  /// as it answers them.
  List<ath.PhysicalTestResult> get resultList => _rows(
    _results,
    () => [for (final r in _mock.results) _mock.resultView(r)],
  );

  /// The `scope` of every read of the norms, in order.
  List<String> get normScopes => [
    for (final r in _b.requestsTo(_normList))
      '${r.queryParameters['scope'] ?? 'EFFECTIVE'}',
  ];

  /// The last norm the app created or replaced (null: none).
  ath.PhysicalTestNormInput? get savedNorm {
    final sent = [
      for (final r in _b.requestsTo(_normPaths, method: null))
        if (r.method == 'POST' || r.method == 'PUT') r,
    ];
    return sent.isEmpty
        ? null
        : athleteModel<ath.PhysicalTestNormInput>(
            MockBackend.bodyOf(sent.last),
          );
  }

  /// The last test type the app created (null: none).
  ath.PhysicalTestTypeInput? get createdType => _lastSent(_typeList, 'POST');

  /// The last change of a test type the app sent (null: none).
  ath.UpdatePhysicalTestTypeRequest? get updatedType =>
      _lastSent(_type, 'PATCH');

  /// The last correction of a result the app sent (null: none).
  ath.UpdatePhysicalTestResultRequest? get updatedResult =>
      _lastSent(_result, 'PATCH');
}

/// The training side of a test (ADR-0070): sessions, schedules, planned
/// absences and recorded attendance seeded into the backend's athlete mock,
/// then what it holds and what the app sent. The mock builds each attendance
/// sheet from the team's roster, the planned absences and the open injuries;
/// [attendanceBySession] seeds only the recorded marks.
class TrainingData extends _AthleteData {
  TrainingData({
    List<ath.TrainingSession> sessions = const [],
    List<ath.TrainingSchedule> schedules = const [],
    List<ath.PlannedAbsence> absences = const [],
    Map<String, List<ath.AttendanceEntry>> attendance = const {},
  }) : _sessions = [...sessions],
       _schedules = [...schedules],
       _absences = [...absences],
       _attendance = {...attendance},
       super(
         RegExp(
           '^/api/athlete/(training-sessions|training-schedules|'
           'planned-absences)',
         ),
       );

  final List<ath.TrainingSession> _sessions;
  final List<ath.TrainingSchedule> _schedules;
  final List<ath.PlannedAbsence> _absences;
  final Map<String, List<ath.AttendanceEntry>> _attendance;

  static const _sessionList = '/api/athlete/training-sessions';
  static final _session = RegExp(r'^/api/athlete/training-sessions/[^/]+$');
  static final _quickAdd = RegExp(
    r'^/api/athlete/training-sessions/[^/]+/items$',
  );
  static final _attendancePath = RegExp(
    r'^/api/athlete/training-sessions/[^/]+/attendance$',
  );
  static final _cancel = RegExp(
    r'^/api/athlete/training-sessions/[^/]+/cancel$',
  );
  static const _scheduleList = '/api/athlete/training-schedules';
  static final _schedule = RegExp(r'^/api/athlete/training-schedules/[^/]+$');
  static const _absenceList = '/api/athlete/planned-absences';
  static final _absence = RegExp(r'^/api/athlete/planned-absences/[^/]+$');

  @override
  void _seedRows(MockAthleteApi mock) {
    mock.sessions.addAll(_sessions.map(athleteJson<ath.TrainingSession>));
    mock.schedules.addAll(_schedules.map(athleteJson<ath.TrainingSchedule>));
    mock.absences.addAll(_absences.map(athleteJson<ath.PlannedAbsence>));
    for (final e in _attendance.entries) {
      final sheet = mock.attendance[e.key] = {};
      for (final entry in e.value.where((x) => x.status != null)) {
        sheet[entry.playerId] = {
          'status': entry.status!.name,
          'minutesLate': entry.minutesLate,
          'note': entry.note,
          'recordedBy': {'personId': 'person-coach', 'displayName': 'Coach'},
          'recordedAt': '2026-11-01T00:00:00.000Z',
        };
      }
    }
  }

  /// The sessions: before seeding the seed (to change), afterwards the
  /// mock's.
  List<ath.TrainingSession> get sessionList =>
      _rows(_sessions, () => _mock.sessions);

  /// The weekly schedules: before seeding the seed, afterwards the mock's.
  List<ath.TrainingSchedule> get scheduleList =>
      _rows(_schedules, () => _mock.schedules);

  /// The planned absences: before seeding the seed, afterwards the mock's.
  List<ath.PlannedAbsence> get absenceList =>
      _rows(_absences, () => _mock.absences);

  /// The recorded marks per session: before seeding the seed (to change).
  Map<String, List<ath.AttendanceEntry>> get attendanceBySession => _seeded
      ? {
          for (final s in _mock.attendance.entries)
            s.key: [
              for (final m in s.value.entries)
                athleteModel<ath.AttendanceEntry>({
                  ...m.value,
                  'playerId': m.key,
                  'expectedAbsent': false,
                }),
            ],
        }
      : _attendance;

  /// Every read of the sessions as `team:from..to` (`*`: no team), in order.
  List<String> get sessionQueries => [
    for (final r in _b.requestsTo(_sessionList))
      '${r.queryParameters['teamId'] ?? '*'}:'
          '${r.queryParameters['from']}..${r.queryParameters['to']}',
  ];

  /// The training repository's operations the app called, in order (failed
  /// and held ones too); [clear] forgets the earlier ones.
  late final List<String> calls = _Since(
    () => _backend,
    () => [for (final r in _b.requestsTo(_paths, method: null)) ?_operation(r)],
  );

  static String? _operation(RequestOptions r) {
    final m = r.method.toUpperCase();
    final p = r.path;
    if (_quickAdd.hasMatch(p)) return 'copyItemsToSession';
    if (_attendancePath.hasMatch(p)) {
      return m == 'GET' ? 'attendance' : 'recordAttendance';
    }
    if (_cancel.hasMatch(p)) return 'cancelSession';
    if (p == _sessionList) return m == 'GET' ? 'sessions' : 'createSession';
    if (_session.hasMatch(p)) return m == 'GET' ? 'session' : 'updateSession';
    if (p == _scheduleList) return m == 'GET' ? 'schedules' : 'createSchedule';
    if (_schedule.hasMatch(p)) {
      return m == 'DELETE' ? 'deleteSchedule' : 'updateSchedule';
    }
    if (p == _absenceList) return m == 'GET' ? 'absences' : 'createAbsence';
    if (_absence.hasMatch(p)) {
      return m == 'DELETE' ? 'deleteAbsence' : 'updateAbsence';
    }
    return null;
  }

  /// Fails the quick-adds into a session only (a session is still created).
  set failCopyWith(Object error) =>
      _seeded ? injectInto(_b, error, _quickAdd) : _copyFaults.add(error);
  final List<Object> _copyFaults = [];

  @override
  void seedInto(MockBackend backend) {
    super.seedInto(backend);
    for (final e in _copyFaults) {
      injectInto(backend, e, _quickAdd);
    }
  }

  /// The sources of every quick-add into a session, per call.
  List<List<ath.PlanItemSource>> get quickAdded => [
    for (final r in _b.requestsTo(_quickAdd, method: 'POST'))
      athleteModel<ath.CopyPlanItemsRequest>(MockBackend.bodyOf(r)).items
          .toList(),
  ];

  ath.CreateTrainingSessionRequest? get createdSession =>
      _lastSent(_sessionList, 'POST');
  ath.UpdateTrainingSessionRequest? get updatedSession =>
      _lastSent(_session, 'PATCH');

  /// The entries of the last attendance the app recorded (null: none).
  List<ath.AttendanceInput>? get recorded =>
      _lastSent<ath.RecordAttendanceRequest>(
        _attendancePath,
        'PUT',
      )?.entries.toList();

  /// The reason of the last cancellation (null: none).
  String? get cancelledReason =>
      _lastSent<ath.CancelTrainingSessionRequest>(_cancel, 'POST')?.reason;

  ath.TrainingScheduleInput? get createdSchedule =>
      _lastSent(_scheduleList, 'POST');
  ath.UpdateTrainingScheduleRequest? get updatedSchedule =>
      _lastSent(_schedule, 'PATCH');
  ath.PlannedAbsenceInput? get createdAbsence =>
      _lastSent(_absenceList, 'POST');
  ath.UpdatePlannedAbsenceRequest? get updatedAbsence =>
      _lastSent(_absence, 'PATCH');
}

/// The plans of a test (ADR-0070): plans with their items, assignments and
/// completions seeded into the backend's athlete mock, then what it holds and
/// what the app sent.
class PlansData extends _AthleteData {
  PlansData({
    List<ath.TrainingPlan> plans = const [],
    List<ath.PlanAssignment> assignments = const [],
    List<ath.PlanCompletion> completions = const [],
  }) : _plans = [...plans],
       _assignments = [...assignments],
       _completions = [...completions],
       super(
         RegExp(
           '^/api/athlete/(training-plans|plan-assignments|'
           'plan-completions)',
         ),
       );

  final List<ath.TrainingPlan> _plans;
  final List<ath.PlanAssignment> _assignments;
  final List<ath.PlanCompletion> _completions;

  static const _planList = '/api/athlete/training-plans';
  static final _planReads = RegExp(r'^/api/athlete/training-plans(/[^/:]+)?$');
  static final _copy = RegExp(r'^/api/athlete/training-plans/[^/]+:copy$');
  static final _itemsCopy = RegExp(
    r'^/api/athlete/training-plans/[^/]+/items:copy$',
  );
  static final _items = RegExp(r'^/api/athlete/training-plans/[^/]+/items$');
  static final _item = RegExp(
    r'^/api/athlete/training-plans/[^/]+/items/[^/]+$',
  );
  static const _assignmentList = '/api/athlete/plan-assignments';
  static final _completion = RegExp(
    r'^/api/athlete/plan-assignments/([^/]+)/completions/([^/]+)$',
  );

  @override
  void _seedRows(MockAthleteApi mock) {
    mock.plans.addAll(_plans.map(athleteJson<ath.TrainingPlan>));
    mock.assignments.addAll([
      for (final a in _assignments)
        {
          ...athleteJson<ath.PlanAssignment>(a)..remove('plan'),
          'planId': a.plan.id,
        },
    ]);
    mock.completions.addAll(_completions.map(athleteJson<ath.PlanCompletion>));
  }

  /// The plans (a session's own ones too): before seeding the seed (to
  /// change), afterwards the mock's.
  List<ath.TrainingPlan> get planList =>
      _rows(_plans, () => [for (final p in _mock.plans) _mock.planView(p)]);

  /// The assignments: before seeding the seed (to change), afterwards the
  /// mock's.
  List<ath.PlanAssignment> get assignmentList => _rows(
    _assignments,
    () => [for (final a in _mock.assignments) _mock.assignmentView(a)],
  );

  /// The completions: before seeding the seed (to change), afterwards the
  /// mock's.
  List<ath.PlanCompletion> get completionList =>
      _rows(_completions, () => _mock.completions);

  /// The search text of the last read of the library (null: none).
  String? get lastQuery =>
      _b.requestsTo(_planList).last.queryParameters['q'] as String?;

  /// The `Accept-Language` of every plan read and copy, in call order;
  /// [clear] forgets the earlier ones.
  late final List<String?> languages = _Since(
    () => _backend,
    () => [
      for (final r in _b.requestsTo(_paths, method: null))
        if ((r.method == 'GET' && _planReads.hasMatch(r.path)) ||
            _copy.hasMatch(r.path) ||
            _itemsCopy.hasMatch(r.path))
          r.headers['Accept-Language'] as String?,
    ],
  );

  /// The last assignment the app created (null: none).
  ath.CreatePlanAssignmentRequest? get assigned =>
      _lastSent(_assignmentList, 'POST');

  /// The plan the app last copied (null: none).
  String? get copiedFrom {
    final sent = _b.requestsTo(_copy, method: 'POST');
    if (sent.isEmpty) return null;
    final path = sent.last.path;
    return path.substring(path.lastIndexOf('/') + 1, path.indexOf(':copy'));
  }

  /// The sources of every quick-add into a plan, per call.
  List<List<ath.PlanItemSource>> get quickAdded => [
    for (final r in _b.requestsTo(_itemsCopy, method: 'POST'))
      athleteModel<ath.CopyPlanItemsRequest>(MockBackend.bodyOf(r)).items
          .toList(),
  ];

  /// The item order the app last sent (null: none).
  List<String>? get lastOrder =>
      _lastSent<ath.ReorderPlanItemsRequest>(_items, 'PUT')?.itemIds.toList();

  /// The last change of an item the app sent (null: none).
  ath.UpdatePlanItemRequest? get updatedItem => _lastSent(_item, 'PATCH');

  /// The last completion the app recorded (null: none).
  ({
    String assignmentId,
    String playerId,
    ath.CompletionStatus status,
    String? comment,
  })?
  get lastRecord {
    final sent = _b.requestsTo(_completion, method: 'PUT');
    if (sent.isEmpty) return null;
    final ids = _completion.firstMatch(sent.last.path)!;
    final body = athleteModel<ath.RecordPlanCompletionRequest>(
      MockBackend.bodyOf(sent.last),
    );
    return (
      assignmentId: ids[1]!,
      playerId: ids[2]!,
      status: body.status,
      comment: body.comment,
    );
  }
}
