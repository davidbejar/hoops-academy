import '../../../core/api/api.dart' as api;
import '../../../core/api/fetch_all.dart';

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
  Future<List<api.EligibilityCase>> list({api.EligibilityCaseStatus? status}) =>
      fetchAll((page, size) async {
        final p = (await _api.listEligibilityCases(
          xTenantId: _t,
          status: status,
          page: page,
          size: size,
        )).data!;
        return (items: p.items, totalPages: p.page.totalPages);
      });

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
