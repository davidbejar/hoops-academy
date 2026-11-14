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
    this.givenName,
    this.familyName,
    this.staffTeamIds = const {},
    this.historicStaffTeamIds = const {},
    this.linkedPlayerIds = const {},
    this.ownPlayerId,
    this.timezone,
  });

  final String tenantId;
  final String tenantName;
  final String slug;
  final bool hasLogo;
  final Set<TenantRole> roles;

  /// The caller's person in this academy (null when unknown).
  final String? personId;

  /// The caller's given and family name as this academy stores them (core 3.6.0); null from an older server.
  final String? givenName;
  final String? familyName;

  /// Teams the caller is staff of (coach / assistant), from `/me.authz`.
  final Set<String> staffTeamIds;

  /// Teams of seasons that have ended where the caller was staff: read-only history (ADR-0042), never part of
  /// [staffTeamIds]. From `/me.authz.historicStaffTeamIds`.
  final Set<String> historicStaffTeamIds;

  /// Players the caller is guardian of (PARENT), from `/me.authz`.
  final Set<String> linkedPlayerIds;

  /// The caller's own player (PLAYER role), from `/me.authz.ownPlayerId`.
  final String? ownPlayerId;

  /// IANA zone of the academy, from `/me.authz.timezone` (null: device zone).
  final String? timezone;

  /// The same membership with the caller's name changed.
  TenantMembership withName({
    required String givenName,
    required String familyName,
  }) => TenantMembership(
    tenantId: tenantId,
    tenantName: tenantName,
    slug: slug,
    hasLogo: hasLogo,
    roles: roles,
    personId: personId,
    givenName: givenName,
    familyName: familyName,
    staffTeamIds: staffTeamIds,
    historicStaffTeamIds: historicStaffTeamIds,
    linkedPlayerIds: linkedPlayerIds,
    ownPlayerId: ownPlayerId,
    timezone: timezone,
  );
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
