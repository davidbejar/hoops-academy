import '../../../core/api/api.dart' as api;

/// Eligibility cases (`/api/core/eligibility-cases`).
abstract class CasesRepository {
  Future<List<api.EligibilityCase>> list({api.EligibilityCaseStatus? status});
  Future<api.EligibilityCase> resolve(
    String id, {
    required api.EligibilityCaseResolution resolution,
    String? targetTeamId,
    String? note,
  });
}

class ApiCasesRepository implements CasesRepository {
  ApiCasesRepository(api.HoopsCoreApi client, this._t)
    : _api = client.getEligibilityCasesApi();

  final api.EligibilityCasesApi _api;
  final String _t;

  @override
  Future<List<api.EligibilityCase>> list({
    api.EligibilityCaseStatus? status,
  }) async => (await _api.listEligibilityCases(
    xTenantId: _t,
    status: status,
    size: 100,
  )).data!.items.toList();

  @override
  Future<api.EligibilityCase> resolve(
    String id, {
    required api.EligibilityCaseResolution resolution,
    String? targetTeamId,
    String? note,
  }) async => (await _api.resolveEligibilityCase(
    xTenantId: _t,
    eligibilityCaseId: id,
    resolveEligibilityCaseRequest: api.ResolveEligibilityCaseRequest(
      (b) => b
        ..resolution = resolution
        ..targetTeamId = targetTeamId
        ..note = note,
    ),
  )).data!;
}
