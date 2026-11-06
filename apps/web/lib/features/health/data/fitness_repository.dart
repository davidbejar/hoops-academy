import '../../../core/api/athlete_api.dart' as ath;

/// Physical test types, results and norms.
abstract class FitnessRepository {
  Future<List<ath.PhysicalTestType>> types();
  Future<ath.PhysicalTestType> createType(ath.PhysicalTestTypeInput input);
  Future<ath.PhysicalTestType> updateType(String id, ath.UpdatePhysicalTestTypeRequest request);
  Future<void> deleteType(String id);

  Future<List<ath.PhysicalTestResult>> results({String? playerId, String? teamId, String? testTypeId});
  Future<ath.PhysicalTestResult> createResult(ath.PhysicalTestResultInput input);
  Future<ath.PhysicalTestResult> updateResult(String id, ath.UpdatePhysicalTestResultRequest request);
  Future<void> deleteResult(String id);

  /// [scope]: `EFFECTIVE` (default), `GLOBAL` or `TENANT`.
  Future<List<ath.PhysicalTestNorm>> norms({String? testTypeId, ath.Gender? gender, String scope = 'EFFECTIVE'});
  Future<ath.PhysicalTestNorm> createNorm(ath.PhysicalTestNormInput input);
  Future<ath.PhysicalTestNorm> replaceNorm(String id, ath.PhysicalTestNormInput input);
  Future<void> deleteNorm(String id);
}

class ApiFitnessRepository implements FitnessRepository {
  ApiFitnessRepository(ath.HoopsAthleteApi client, this._t) : _api = client.getPhysicalTestsApi();

  final ath.PhysicalTestsApi _api;
  final String _t;

  @override
  Future<List<ath.PhysicalTestType>> types() async => (await _api.listPhysicalTestTypes(xTenantId: _t)).data!.toList();

  @override
  Future<ath.PhysicalTestType> createType(ath.PhysicalTestTypeInput input) async =>
      (await _api.createPhysicalTestType(xTenantId: _t, physicalTestTypeInput: input)).data!;

  @override
  Future<ath.PhysicalTestType> updateType(String id, ath.UpdatePhysicalTestTypeRequest request) async =>
      (await _api.updatePhysicalTestType(xTenantId: _t, testTypeId: id, updatePhysicalTestTypeRequest: request)).data!;

  @override
  Future<void> deleteType(String id) async {
    await _api.deletePhysicalTestType(xTenantId: _t, testTypeId: id);
  }

  @override
  Future<List<ath.PhysicalTestResult>> results({String? playerId, String? teamId, String? testTypeId}) async =>
      (await _api.listPhysicalTestResults(xTenantId: _t, playerId: playerId, teamId: teamId, testTypeId: testTypeId, size: 200))
          .data!
          .items
          .toList();

  @override
  Future<ath.PhysicalTestResult> createResult(ath.PhysicalTestResultInput input) async =>
      (await _api.createPhysicalTestResult(xTenantId: _t, physicalTestResultInput: input)).data!;

  @override
  Future<ath.PhysicalTestResult> updateResult(String id, ath.UpdatePhysicalTestResultRequest request) async =>
      (await _api.updatePhysicalTestResult(xTenantId: _t, resultId: id, updatePhysicalTestResultRequest: request)).data!;

  @override
  Future<void> deleteResult(String id) async {
    await _api.deletePhysicalTestResult(xTenantId: _t, resultId: id);
  }

  @override
  Future<List<ath.PhysicalTestNorm>> norms({String? testTypeId, ath.Gender? gender, String scope = 'EFFECTIVE'}) async =>
      (await _api.listPhysicalTestNorms(xTenantId: _t, testTypeId: testTypeId, gender: gender, scope: scope)).data!.toList();

  @override
  Future<ath.PhysicalTestNorm> createNorm(ath.PhysicalTestNormInput input) async =>
      (await _api.createPhysicalTestNorm(xTenantId: _t, physicalTestNormInput: input)).data!;

  @override
  Future<ath.PhysicalTestNorm> replaceNorm(String id, ath.PhysicalTestNormInput input) async =>
      (await _api.replacePhysicalTestNorm(xTenantId: _t, normId: id, physicalTestNormInput: input)).data!;

  @override
  Future<void> deleteNorm(String id) async {
    await _api.deletePhysicalTestNorm(xTenantId: _t, normId: id);
  }
}
