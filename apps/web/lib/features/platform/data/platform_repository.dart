import '../../../core/api/api.dart' as api;

/// Tenant lifecycle and usage (`/platform/**`, super_admin only).
abstract class PlatformRepository {
  Future<List<api.Tenant>> tenants({api.TenantStatus? status, String? query});
  Future<api.Tenant> tenant(String tenantId);
  Future<api.Tenant> create(api.CreateTenantRequest request);
  Future<api.Tenant> suspend(String tenantId, String reason);
  Future<api.Tenant> withdraw(String tenantId, String reason);
  Future<api.Tenant> reactivate(String tenantId);
  Future<api.TenantUsage> usage(String tenantId);

  /// Administrators of a tenant (identity only, ADR-0023). 409 `TENANT_WITHDRAWN` for withdrawn academies.
  Future<List<api.TenantAdmin>> admins(String tenantId);
  Future<api.TenantAdmin> addAdmin(String tenantId, api.AddTenantAdminRequest request);
  Future<api.TenantAdmin> updateAdmin(String tenantId, String personId, api.UpdateTenantAdminRequest request);
  Future<void> removeAdmin(String tenantId, String personId);
  Future<api.TenantAdmin> resendAdminInvitation(String tenantId, String personId);
}

class ApiPlatformRepository implements PlatformRepository {
  ApiPlatformRepository(api.HoopsCoreApi client) : _api = client.getPlatformApi();

  final api.PlatformApi _api;

  @override
  Future<List<api.Tenant>> tenants({api.TenantStatus? status, String? query}) async =>
      (await _api.listTenants(status: status, q: query, size: 100)).data!.items.toList();

  @override
  Future<api.Tenant> tenant(String tenantId) async => (await _api.getTenant(tenantId: tenantId)).data!;

  @override
  Future<api.Tenant> create(api.CreateTenantRequest request) async =>
      (await _api.createTenant(createTenantRequest: request)).data!;

  @override
  Future<api.Tenant> suspend(String tenantId, String reason) async => (await _api.suspendTenant(
    tenantId: tenantId,
    tenantLifecycleRequest: api.TenantLifecycleRequest((b) => b.reason = reason),
  )).data!;

  @override
  Future<api.Tenant> withdraw(String tenantId, String reason) async => (await _api.withdrawTenant(
    tenantId: tenantId,
    tenantLifecycleRequest: api.TenantLifecycleRequest((b) => b.reason = reason),
  )).data!;

  @override
  Future<api.Tenant> reactivate(String tenantId) async => (await _api.reactivateTenant(tenantId: tenantId)).data!;

  @override
  Future<api.TenantUsage> usage(String tenantId) async => (await _api.getTenantUsage(tenantId: tenantId)).data!;

  @override
  Future<List<api.TenantAdmin>> admins(String tenantId) async =>
      (await _api.listTenantAdmins(tenantId: tenantId, size: 100)).data!.items.toList();

  @override
  Future<api.TenantAdmin> addAdmin(String tenantId, api.AddTenantAdminRequest request) async =>
      (await _api.addTenantAdmin(tenantId: tenantId, addTenantAdminRequest: request)).data!;

  @override
  Future<api.TenantAdmin> updateAdmin(String tenantId, String personId, api.UpdateTenantAdminRequest request) async =>
      (await _api.updateTenantAdmin(tenantId: tenantId, personId: personId, updateTenantAdminRequest: request)).data!;

  @override
  Future<void> removeAdmin(String tenantId, String personId) async =>
      _api.removeTenantAdmin(tenantId: tenantId, personId: personId);

  @override
  Future<api.TenantAdmin> resendAdminInvitation(String tenantId, String personId) async =>
      (await _api.resendTenantAdminInvitation(tenantId: tenantId, personId: personId)).data!;
}
