import 'package:dio/dio.dart';
import 'package:hoops_core_api/hoops_core_api.dart' as api;

import '../domain/current_user.dart';

abstract class MeRepository {
  Future<CurrentUser> fetch();

  /// Persists the language preference server-side (best effort for callers).
  Future<void> updateLocale(String localeCode);
}

/// `/api/core/me` through the generated client.
class ApiMeRepository implements MeRepository {
  ApiMeRepository(Dio dio)
    : _api = api.HoopsCoreApi(dio: dio, interceptors: const []).getMeApi();

  final api.MeApi _api;

  @override
  Future<CurrentUser> fetch() async =>
      _toDomain((await _api.getMe()).data!);

  @override
  Future<void> updateLocale(String localeCode) async {
    await _api.updateMe(
      updateMeRequest: api.UpdateMeRequest(
        (b) => b.locale = api.Locale.valueOf(localeCode),
      ),
    );
  }

  CurrentUser _toDomain(api.Me me) => CurrentUser(
    displayName: me.displayName,
    email: me.email,
    localeCode: me.locale.name,
    superAdmin: me.superAdmin,
    memberships: [
      for (final m in me.memberships)
        TenantMembership(
          tenantId: m.tenant.id,
          tenantName: m.tenant.name,
          slug: m.tenant.slug,
          hasLogo: m.tenant.hasLogo,
          roles: {
            for (final r in m.roles) ?_role(r),
          },
        ),
    ],
  );

  static TenantRole? _role(api.TenantRole r) {
    if (r == api.TenantRole.ADMIN) return TenantRole.admin;
    if (r == api.TenantRole.COACH) return TenantRole.coach;
    if (r == api.TenantRole.ASSISTANT_COACH) return TenantRole.assistantCoach;
    if (r == api.TenantRole.PARENT) return TenantRole.parent;
    if (r == api.TenantRole.PLAYER) return TenantRole.player;
    return null; // unknown_default_open_api: ignore roles this build can't render
  }
}
