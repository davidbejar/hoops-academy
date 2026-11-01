import 'package:hoops_app/features/me/domain/current_user.dart';

const tenantNorth = TenantMembership(
  tenantId: '11111111-1111-4111-8111-111111111111',
  tenantName: 'Club Norte',
  slug: 'norte',
  hasLogo: false,
  roles: {TenantRole.admin},
);

const tenantSouth = TenantMembership(
  tenantId: '22222222-2222-4222-8222-222222222222',
  tenantName: 'Academia Sur',
  slug: 'sur',
  hasLogo: false,
  roles: {TenantRole.parent},
);

CurrentUser userWith(
  List<TenantMembership> memberships, {
  bool superAdmin = false,
  String locale = 'es',
}) => CurrentUser(
  displayName: 'Casey Coach',
  email: 'coach1@hoops.local',
  localeCode: locale,
  superAdmin: superAdmin,
  memberships: memberships,
);

TenantMembership membershipWithRoles(
  Set<TenantRole> roles, {
  Set<String> staffTeamIds = const {},
  Set<String> linkedPlayerIds = const {},
  String personId = 'person-me',
  String? ownPlayerId,
}) =>
    TenantMembership(
      personId: personId,
      staffTeamIds: staffTeamIds,
      linkedPlayerIds: linkedPlayerIds,
      ownPlayerId: ownPlayerId,
      tenantId: '33333333-3333-4333-8333-333333333333',
      tenantName: 'Role Test',
      slug: 'role-test',
      hasLogo: false,
      roles: roles,
    );
