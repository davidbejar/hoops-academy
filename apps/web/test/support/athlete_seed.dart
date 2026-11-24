import 'package:built_value/serializer.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/core/mock/mock_athlete_api.dart';
import 'package:hoops_app/features/training/application/exercise_providers.dart';
import 'package:hoops_app/features/training/data/exercises_repository.dart';

import 'core_seed.dart' show injectInto;
import 'mock_backend.dart';

/// [value] (an athlete model) as the service sends it, for seeding the mock.
Map<String, Object?> athleteJson<T>(T value) =>
    (ath.standardSerializers.serialize(value, specifiedType: FullType(T))!
            as Map)
        .cast<String, Object?>();

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
    _backend?.heal();
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
