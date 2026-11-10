import '../../../core/api/athlete_api.dart' as ath;

/// The exercise catalogue (athlete 3.0.0, ADR-0047): global exercises,
/// read-only and in the caller's language, and the academy's own.
abstract class ExercisesRepository {
  /// One page ordered by the shown title. [query] is a part of the title;
  /// [scope] null = both; global texts come in [language] (`Accept-Language`).
  Future<ath.ExercisePage> exercises({
    String? query,
    ath.ExerciseScope? scope,
    bool includeArchived = false,
    int page = 0,
    int size = 50,
    String? language,
  });
  Future<ath.Exercise> create(ath.ExerciseInput input);
  Future<ath.Exercise> update(
    String exerciseId,
    ath.UpdateExerciseRequest request,
  );

  /// Hidden from the catalogue; items copied from it keep their text.
  Future<ath.Exercise> archive(String exerciseId);
  Future<ath.Exercise> unarchive(String exerciseId);
}

class ApiExercisesRepository implements ExercisesRepository {
  ApiExercisesRepository(ath.HoopsAthleteApi client, this._t)
    : _api = client.getExercisesApi();

  final ath.ExercisesApi _api;
  final String _t;

  @override
  Future<ath.ExercisePage> exercises({
    String? query,
    ath.ExerciseScope? scope,
    bool includeArchived = false,
    int page = 0,
    int size = 50,
    String? language,
  }) async => (await _api.listExercises(
    xTenantId: _t,
    q: query,
    scope: scope,
    includeArchived: includeArchived,
    page: page,
    size: size,
    acceptLanguage: language,
  )).data!;

  @override
  Future<ath.Exercise> create(ath.ExerciseInput input) async =>
      (await _api.createExercise(xTenantId: _t, exerciseInput: input)).data!;

  @override
  Future<ath.Exercise> update(
    String exerciseId,
    ath.UpdateExerciseRequest request,
  ) async => (await _api.updateExercise(
    xTenantId: _t,
    exerciseId: exerciseId,
    updateExerciseRequest: request,
  )).data!;

  @override
  Future<ath.Exercise> archive(String exerciseId) async =>
      (await _api.archiveExercise(xTenantId: _t, exerciseId: exerciseId)).data!;

  @override
  Future<ath.Exercise> unarchive(String exerciseId) async =>
      (await _api.unarchiveExercise(
        xTenantId: _t,
        exerciseId: exerciseId,
      )).data!;
}
