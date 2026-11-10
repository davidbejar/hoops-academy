import '../../../core/api/api.dart' as api;

/// Users shown per page of the platform's user list.
const platformUsersPageSize = 25;

/// Tenant lifecycle and usage (`/platform/**`, super_admin only).
abstract class PlatformRepository {
  Future<List<api.Tenant>> tenants({api.TenantStatus? status, String? query});
  Future<api.Tenant> tenant(String tenantId);

  /// Every login across the academies with its memberships (`GET /platform/users`); [query] is 2 to 100 characters.
  Future<api.PlatformUserPage> users({
    String? query,
    int page = 0,
    int size = platformUsersPageSize,
  });

  /// The temporary password of the first administrator's new login is in the result, returned once (ADR-0024).
  Future<api.TenantWithPassword> create(api.CreateTenantRequest request);
  Future<api.Tenant> suspend(String tenantId, String reason);
  Future<api.Tenant> withdraw(String tenantId, String reason);
  Future<api.Tenant> reactivate(String tenantId);
  Future<api.TenantUsage> usage(String tenantId);

  /// Daily usage snapshots (at most one per UTC day, ascending) for the trend chart.
  Future<api.TenantUsageHistory> usageHistory(String tenantId);

  /// Administrators of a tenant (identity only, ADR-0023). 409 `TENANT_WITHDRAWN` for withdrawn academies.
  Future<List<api.TenantAdmin>> admins(String tenantId);
  Future<api.TenantAdminWithPassword> addAdmin(
    String tenantId,
    api.AddTenantAdminRequest request,
  );
  Future<api.TenantAdmin> updateAdmin(
    String tenantId,
    String personId,
    api.UpdateTenantAdminRequest request,
  );
  Future<void> removeAdmin(String tenantId, String personId);

  /// New temporary password for a pending administrator; 409 `INVITATION_NOT_PENDING` otherwise.
  Future<api.TenantAdminWithPassword> issueAdminTemporaryPassword(
    String tenantId,
    String personId,
  );
}

class ApiPlatformRepository implements PlatformRepository {
  ApiPlatformRepository(api.HoopsCoreApi client)
    : _api = client.getPlatformApi();

  final api.PlatformApi _api;

  @override
  Future<List<api.Tenant>> tenants({
    api.TenantStatus? status,
    String? query,
  }) async => (await _api.listTenants(
    status: status,
    q: query,
    size: 100,
  )).data!.items.toList();

  @override
  Future<api.PlatformUserPage> users({
    String? query,
    int page = 0,
    int size = platformUsersPageSize,
  }) async =>
      (await _api.listPlatformUsers(q: query, page: page, size: size)).data!;

  @override
  Future<api.Tenant> tenant(String tenantId) async =>
      (await _api.getTenant(tenantId: tenantId)).data!;

  @override
  Future<api.TenantWithPassword> create(
    api.CreateTenantRequest request,
  ) async => (await _api.createTenant(createTenantRequest: request)).data!;

  @override
  Future<api.Tenant> suspend(String tenantId, String reason) async =>
      (await _api.suspendTenant(
        tenantId: tenantId,
        tenantLifecycleRequest: api.TenantLifecycleRequest(
          (b) => b.reason = reason,
        ),
      )).data!;

  @override
  Future<api.Tenant> withdraw(String tenantId, String reason) async =>
      (await _api.withdrawTenant(
        tenantId: tenantId,
        tenantLifecycleRequest: api.TenantLifecycleRequest(
          (b) => b.reason = reason,
        ),
      )).data!;

  @override
  Future<api.Tenant> reactivate(String tenantId) async =>
      (await _api.reactivateTenant(tenantId: tenantId)).data!;

  @override
  Future<api.TenantUsage> usage(String tenantId) async =>
      (await _api.getTenantUsage(tenantId: tenantId)).data!;

  @override
  Future<api.TenantUsageHistory> usageHistory(String tenantId) async =>
      (await _api.getTenantUsageHistory(tenantId: tenantId)).data!;

  @override
  Future<List<api.TenantAdmin>> admins(String tenantId) async =>
      (await _api.listTenantAdmins(
        tenantId: tenantId,
        size: 100,
      )).data!.items.toList();

  @override
  Future<api.TenantAdminWithPassword> addAdmin(
    String tenantId,
    api.AddTenantAdminRequest request,
  ) async => (await _api.addTenantAdmin(
    tenantId: tenantId,
    addTenantAdminRequest: request,
  )).data!;

  @override
  Future<api.TenantAdmin> updateAdmin(
    String tenantId,
    String personId,
    api.UpdateTenantAdminRequest request,
  ) async => (await _api.updateTenantAdmin(
    tenantId: tenantId,
    personId: personId,
    updateTenantAdminRequest: request,
  )).data!;

  @override
  Future<void> removeAdmin(String tenantId, String personId) async =>
      _api.removeTenantAdmin(tenantId: tenantId, personId: personId);

  @override
  Future<api.TenantAdminWithPassword> issueAdminTemporaryPassword(
    String tenantId,
    String personId,
  ) async => (await _api.issueTenantAdminTemporaryPassword(
    tenantId: tenantId,
    personId: personId,
  )).data!;
}
