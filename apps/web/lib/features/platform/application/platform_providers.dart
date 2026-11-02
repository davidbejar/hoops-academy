import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../../core/errors/app_error.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_providers.dart';
import '../data/platform_repository.dart';

final platformRepositoryProvider = Provider<PlatformRepository>(
  (ref) => ApiPlatformRepository(ref.watch(api.coreApiProvider)),
);

class TenantFilter {
  const TenantFilter({this.status, this.query = ''});
  final api.TenantStatus? status;
  final String query;
}

class TenantFilterNotifier extends Notifier<TenantFilter> {
  @override
  TenantFilter build() => const TenantFilter();
  void set(TenantFilter f) => state = f;
}

final tenantFilterProvider = NotifierProvider<TenantFilterNotifier, TenantFilter>(TenantFilterNotifier.new);

class TenantsNotifier extends AsyncNotifier<List<api.Tenant>> {
  @override
  Future<List<api.Tenant>> build() {
    final f = ref.watch(tenantFilterProvider);
    return ref.watch(platformRepositoryProvider).tenants(status: f.status, query: f.query.trim().isEmpty ? null : f.query.trim());
  }

  /// The result carries the first administrator's temporary password: the caller shows it once and drops it; it is
  /// never put into this notifier's state.
  Future<api.TenantWithPassword> create({
    required String name,
    required String slug,
    required String timezone,
    required api.ApiLocale locale,
    required String adminEmail,
    required String adminGivenName,
    required String adminFamilyName,
  }) async {
    final t = await ref.read(platformRepositoryProvider).create(
      api.CreateTenantRequest((b) => b
        ..name = name
        ..slug = slug
        ..timezone = timezone
        ..defaultLocale = locale
        ..firstAdmin.replace(api.FirstAdmin((a) => a
          ..email = adminEmail
          ..givenName = adminGivenName
          ..familyName = adminFamilyName
          ..locale = locale))),
    );
    ref.invalidateSelf();
    await future;
    return t;
  }
}

final tenantsProvider = AsyncNotifierProvider<TenantsNotifier, List<api.Tenant>>(TenantsNotifier.new);

class TenantDetail {
  const TenantDetail({required this.tenant, this.usage, this.usageError});
  final api.Tenant tenant;
  final api.TenantUsage? usage;
  final Object? usageError;
}

class TenantDetailNotifier extends AsyncNotifier<TenantDetail> {
  TenantDetailNotifier(this.tenantId);
  final String tenantId;

  @override
  Future<TenantDetail> build() async {
    final repo = ref.watch(platformRepositoryProvider);
    final tenant = await repo.tenant(tenantId);
    // Usage is secondary: a failure there must not hide the tenant.
    try {
      return TenantDetail(tenant: tenant, usage: await repo.usage(tenantId));
    } on Object catch (e) {
      return TenantDetail(tenant: tenant, usageError: e);
    }
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
    ref.invalidate(tenantsProvider);
  }

  Future<void> suspend(String reason) async {
    await ref.read(platformRepositoryProvider).suspend(tenantId, reason);
    await _reload();
  }

  Future<void> withdraw(String reason) async {
    await ref.read(platformRepositoryProvider).withdraw(tenantId, reason);
    await _reload();
  }

  Future<void> reactivate() async {
    await ref.read(platformRepositoryProvider).reactivate(tenantId);
    await _reload();
  }
}

final tenantDetailProvider = AsyncNotifierProvider.family<TenantDetailNotifier, TenantDetail, String>(
  TenantDetailNotifier.new,
);

/// Administrators of one academy (ADR-0023). Every mutation reloads the list from the server.
class TenantAdminsNotifier extends AsyncNotifier<List<api.TenantAdmin>> {
  TenantAdminsNotifier(this.tenantId);
  final String tenantId;

  PlatformRepository get _repo => ref.read(platformRepositoryProvider);

  @override
  Future<List<api.TenantAdmin>> build() => ref.watch(platformRepositoryProvider).admins(tenantId);

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }

  /// Returns the administrator with the temporary password of a login this call created (null: existing login). The
  /// caller shows it once and drops it; the state only ever holds the password-free list.
  Future<api.TenantAdminWithPassword> add({
    required String email,
    required String givenName,
    required String familyName,
    required api.ApiLocale locale,
  }) async {
    final admin = await _repo.addAdmin(
      tenantId,
      api.AddTenantAdminRequest((b) => b
        ..email = email
        ..givenName = givenName
        ..familyName = familyName
        ..locale = locale),
    );
    await _reload();
    return admin;
  }

  /// Merge patch: only the given fields are sent.
  Future<void> edit(String personId, {String? givenName, String? familyName, String? email}) async {
    await _repo.updateAdmin(
      tenantId,
      personId,
      api.UpdateTenantAdminRequest((b) => b
        ..givenName = givenName
        ..familyName = familyName
        ..email = email),
    );
    await _reload();
  }

  Future<void> remove(String personId) async {
    await _repo.removeAdmin(tenantId, personId);
    await _reload();
  }

  /// New temporary password for a pending administrator (returned once, see [add]).
  Future<api.TenantAdminWithPassword> issueTemporaryPassword(
    String personId,
  ) async {
    final admin = await _repo.issueAdminTemporaryPassword(tenantId, personId);
    await _reload();
    return admin;
  }
}

final tenantAdminsProvider = AsyncNotifierProvider.family<TenantAdminsNotifier, List<api.TenantAdmin>, String>(
  TenantAdminsNotifier.new,
);

/// The server answers 409 `TENANT_WITHDRAWN` for a withdrawn academy (also for the list).
bool isTenantWithdrawn(Object error) => AppError.of(error).code == 'TENANT_WITHDRAWN';

/// Platform console is for the realm role `super_admin` only.
final isSuperAdminProvider = Provider<bool>((ref) {
  final s = ref.watch(sessionProvider);
  return s is Ready && s.user.superAdmin;
});
