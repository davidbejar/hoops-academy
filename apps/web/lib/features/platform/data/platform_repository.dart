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
}
