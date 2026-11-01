/// Tenant-scoped roles (mirror of the contract's `TenantRole`).
enum TenantRole { admin, coach, assistantCoach, parent, player }

/// One active membership of the caller in an ACTIVE tenant.
class TenantMembership {
  const TenantMembership({
    required this.tenantId,
    required this.tenantName,
    required this.slug,
    required this.hasLogo,
    required this.roles,
    this.personId,
    this.staffTeamIds = const {},
    this.linkedPlayerIds = const {},
  });

  final String tenantId;
  final String tenantName;
  final String slug;
  final bool hasLogo;
  final Set<TenantRole> roles;

  /// The caller's person in this academy (null when unknown).
  final String? personId;

  /// Teams the caller is staff of (coach / assistant), from `/me.authz`.
  final Set<String> staffTeamIds;

  /// Players the caller is guardian of (PARENT), from `/me.authz`.
  final Set<String> linkedPlayerIds;
}

/// The caller as returned by `GET /api/core/me`, without transport types.
class CurrentUser {
  const CurrentUser({
    required this.displayName,
    required this.localeCode,
    required this.superAdmin,
    required this.memberships,
    this.email,
  });

  final String displayName;
  final String? email;
  final String localeCode;
  final bool superAdmin;
  final List<TenantMembership> memberships;

  TenantMembership? membershipFor(String? tenantId) {
    for (final m in memberships) {
      if (m.tenantId == tenantId) return m;
    }
    return null;
  }
}
