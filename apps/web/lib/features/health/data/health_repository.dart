import '../../../core/api/athlete_api.dart' as ath;

/// Injuries and body measurements.
abstract class HealthRepository {
  Future<List<ath.Injury>> injuries({String? playerId, String? teamId, ath.InjuryStatus? status});
  Future<ath.Injury> createInjury(ath.CreateInjuryRequest request);
  Future<ath.Injury> updateInjury(String injuryId, ath.UpdateInjuryRequest request);
  Future<void> deleteInjury(String injuryId);

  Future<List<ath.BodyMeasurement>> measurements(String playerId);
  Future<ath.BodyMeasurement> createMeasurement(ath.BodyMeasurementInput input);
  Future<ath.BodyMeasurement> updateMeasurement(String id, ath.UpdateBodyMeasurementRequest request);
  Future<void> deleteMeasurement(String id);
}

class ApiHealthRepository implements HealthRepository {
  ApiHealthRepository(ath.HoopsAthleteApi client, this._t)
    : _injuries = client.getInjuriesApi(),
      _body = client.getBodyMeasurementsApi();

  final ath.InjuriesApi _injuries;
  final ath.BodyMeasurementsApi _body;
  final String _t;

  @override
  Future<List<ath.Injury>> injuries({String? playerId, String? teamId, ath.InjuryStatus? status}) async =>
      (await _injuries.listInjuries(xTenantId: _t, playerId: playerId, teamId: teamId, status: status, size: 100)).data!.items.toList();

  @override
  Future<ath.Injury> createInjury(ath.CreateInjuryRequest request) async =>
      (await _injuries.createInjury(xTenantId: _t, createInjuryRequest: request)).data!;

  @override
  Future<ath.Injury> updateInjury(String injuryId, ath.UpdateInjuryRequest request) async =>
      (await _injuries.updateInjury(xTenantId: _t, injuryId: injuryId, updateInjuryRequest: request)).data!;

  @override
  Future<void> deleteInjury(String injuryId) async {
    await _injuries.deleteInjury(xTenantId: _t, injuryId: injuryId);
  }

  @override
  Future<List<ath.BodyMeasurement>> measurements(String playerId) async =>
      (await _body.listBodyMeasurements(xTenantId: _t, playerId: playerId)).data!.toList();

  @override
  Future<ath.BodyMeasurement> createMeasurement(ath.BodyMeasurementInput input) async =>
      (await _body.createBodyMeasurement(xTenantId: _t, bodyMeasurementInput: input)).data!;

  @override
  Future<ath.BodyMeasurement> updateMeasurement(String id, ath.UpdateBodyMeasurementRequest request) async =>
      (await _body.updateBodyMeasurement(xTenantId: _t, measurementId: id, updateBodyMeasurementRequest: request)).data!;

  @override
  Future<void> deleteMeasurement(String id) async {
    await _body.deleteBodyMeasurement(xTenantId: _t, measurementId: id);
  }
}
