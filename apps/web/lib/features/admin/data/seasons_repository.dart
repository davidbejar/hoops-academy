import '../../../core/api/api.dart' as api;

/// Seasons and rollover (`/api/core/seasons`).
abstract class SeasonsRepository {
  Future<List<api.Season>> list();
  Future<api.Season> create({
    required String name,
    required api.Date startsOn,
    required api.Date endsOn,
    required int referenceYear,
  });
  Future<api.Season> update(
    String id, {
    required String name,
    required api.Date startsOn,
    required api.Date endsOn,
    required int referenceYear,
  });
  Future<api.SeasonRolloverResult> rollover(
    String fromSeasonId, {
    bool cloneStaff = true,
    bool clonePlayers = true,
  });
}

class ApiSeasonsRepository implements SeasonsRepository {
  ApiSeasonsRepository(api.HoopsCoreApi client, this._t)
    : _api = client.getSeasonsApi();

  final api.SeasonsApi _api;
  final String _t;

  @override
  Future<List<api.Season>> list() async =>
      (await _api.listSeasons(xTenantId: _t)).data!.toList();

  @override
  Future<api.Season> create({
    required String name,
    required api.Date startsOn,
    required api.Date endsOn,
    required int referenceYear,
  }) async => (await _api.createSeason(
    xTenantId: _t,
    seasonInput: api.SeasonInput(
      (b) => b
        ..name = name
        ..startsOn = startsOn
        ..endsOn = endsOn
        ..referenceYear = referenceYear,
    ),
  )).data!;

  @override
  Future<api.Season> update(
    String id, {
    required String name,
    required api.Date startsOn,
    required api.Date endsOn,
    required int referenceYear,
  }) async => (await _api.updateSeason(
    xTenantId: _t,
    seasonId: id,
    updateSeasonRequest: api.UpdateSeasonRequest(
      (b) => b
        ..name = name
        ..startsOn = startsOn
        ..endsOn = endsOn
        ..referenceYear = referenceYear,
    ),
  )).data!;

  @override
  Future<api.SeasonRolloverResult> rollover(
    String fromSeasonId, {
    bool cloneStaff = true,
    bool clonePlayers = true,
  }) async => (await _api.rolloverSeason(
    xTenantId: _t,
    seasonId: fromSeasonId,
    seasonRolloverRequest: api.SeasonRolloverRequest(
      (b) => b
        ..fromSeasonId = fromSeasonId
        ..cloneStaff = cloneStaff
        ..clonePlayers = clonePlayers,
    ),
  )).data!;
}
