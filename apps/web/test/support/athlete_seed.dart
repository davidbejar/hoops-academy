import 'package:built_value/serializer.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/training/application/exercise_providers.dart';
import 'package:hoops_app/features/training/data/exercises_repository.dart';

import 'core_seed.dart' show injectInto;
import 'mock_backend.dart';

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
class ExercisesData {
  ExercisesData([List<ath.Exercise> exercises = const []])
    : _seed = [...exercises];

  final List<ath.Exercise> _seed;
  MockBackend? _backend;
  MockBackend get _b => _backend!;

  static final _api = RegExp('^/api/athlete/exercises');
  static const _list = '/api/athlete/exercises';
  static final _one = RegExp(r'^/api/athlete/exercises/[^/:]+$');

  final List<Object> _pending = [];
  bool _hang = false;
  void Function()? _release;

  void seedInto(MockBackend backend) {
    _backend = backend;
    backend.academyApis.athlete.exercises.addAll(_seed.map(_json));
    if (_hang) _release = backend.hang(_api);
    for (final e in _pending) {
      injectInto(backend, e, _api);
    }
  }

  /// The catalogue: before seeding the seed, afterwards the mock's.
  List<ath.Exercise> get exerciseList => _backend == null
      ? _seed
      : [
          for (final e in _b.academyApis.athlete.exercises)
            _model<ath.Exercise>(e),
        ];

  /// Replaces the catalogue (before or after seeding).
  set exerciseList(List<ath.Exercise> exercises) {
    _seed
      ..clear()
      ..addAll(exercises);
    _backend?.academyApis.athlete.exercises
      ?..clear()
      ..addAll(exercises.map(_json));
  }

  /// Fails every catalogue call with [error] instead of an earlier one
  /// (null: heals).
  set failWith(Object? error) {
    _pending.clear();
    _backend?.heal();
    if (error == null) return;
    _backend == null ? _pending.add(error) : injectInto(_b, error, _api);
  }

  /// Holds every catalogue call (the loading state) until set back to false.
  set hang(bool value) {
    _hang = value;
    if (_backend == null) return;
    if (value) {
      _release = _b.hang(_api);
    } else {
      _release?.call();
      _release = null;
    }
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
  ath.ExerciseInput? get created {
    final sent = _b.requestsTo(_list, method: 'POST');
    return sent.isEmpty
        ? null
        : _model<ath.ExerciseInput>(MockBackend.bodyOf(sent.last));
  }

  /// The id the mock gave the last exercise created.
  String get createdId =>
      (_b.lastAnswer(_list, method: 'POST')! as Map)['id']! as String;

  /// The last change the app sent (null: none).
  ath.UpdateExerciseRequest? get updated {
    final sent = _b.requestsTo(_one, method: 'PATCH');
    return sent.isEmpty
        ? null
        : _model<ath.UpdateExerciseRequest>(MockBackend.bodyOf(sent.last));
  }

  /// The writes the app sent, in order: `create`, `update`, `archive`,
  /// `unarchive`.
  List<String> get writes => [
    for (final r in _b.requestsTo(_api, method: null))
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
      ApiExercisesRepository(
        ath.HoopsAthleteApi(dio: _b.dio(), interceptors: const []),
        _b.tenantAId,
      ),
    ),
  ];

  static Map<String, Object?> _json(ath.Exercise e) =>
      (ath.standardSerializers.serialize(
                e,
                specifiedType: const FullType(ath.Exercise),
              )!
              as Map)
          .cast<String, Object?>();

  static T _model<T>(Object? json) =>
      ath.standardSerializers.deserialize(json, specifiedType: FullType(T))
          as T;
}
