import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/me/domain/current_user.dart';
import 'session.dart';
import 'session_providers.dart';

/// What the caller may do in the admin / roster module, mirroring
/// `docs/domain/authz-matrix.md`. UI affordances only: the server authorises
/// every call again.
class Capabilities {
  const Capabilities({
    required this.roles,
    this.staffTeamIds = const {},
    this.linkedPlayerIds = const {},
    this.personId,
  });

  static const none = Capabilities(roles: {});

  final Set<TenantRole> roles;
  final Set<String> staffTeamIds;

  /// Players linked to the caller as guardian (PARENT), from `/me.authz`.
  final Set<String> linkedPlayerIds;
  final String? personId;

  bool get _admin => roles.contains(TenantRole.admin);
  bool get _coach => roles.contains(TenantRole.coach);
  bool get _assistant => roles.contains(TenantRole.assistantCoach);

  /// ADMIN / COACH / ASSISTANT_COACH; PARENT and PLAYER never.
  bool get canSeeModule => _admin || _coach || _assistant;

  /// Profile, logo, members, seasons, age categories.
  bool get canManageAcademy => _admin;

  /// Team create / edit / staff.
  bool get canManageTeams => _admin;

  bool isStaffOf(String teamId) => staffTeamIds.contains(teamId);

  /// Assign / unassign players and jersey numbers.
  bool canEditRoster(String teamId) => _admin || (_coach && isStaffOf(teamId));

  bool canResolveCase(String teamId) => canEditRoster(teamId);

  bool get canCreatePlayerDirectly => _admin;

  /// Coach without ADMIN: creating a player files an approval request.
  bool get canRequestPlayer => _coach && !_admin;

  bool get canDecideApprovals => _admin;

  /// Inbox (admin) or "my requests" (coach).
  bool get canSeeApprovals => _admin || _coach;

  bool get canWithdrawPlayer => _admin || _coach;

  // ------------------------------------------------------------ matches (WP13)

  /// Create / start / finish, roster, clock, periods, opponent score:
  /// ADMIN or staff (coach / assistant) of the match's team.
  bool canRunMatch(String teamId) => _admin || ((_coach || _assistant) && isStaffOf(teamId));

  /// PARENT may enter stat events of linked players only.
  bool isLinkedTo(String playerId) => roles.contains(TenantRole.parent) && linkedPlayerIds.contains(playerId);

  /// Any team the caller runs matches for (create button on the list).
  bool get canCreateMatches => _admin || ((_coach || _assistant) && staffTeamIds.isNotEmpty);
}

final capabilitiesProvider = Provider<Capabilities>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is! Ready) return Capabilities.none;
  final m = session.membership;
  return Capabilities(
    roles: session.roles,
    staffTeamIds: m?.staffTeamIds ?? const {},
    linkedPlayerIds: m?.linkedPlayerIds ?? const {},
    personId: m?.personId,
  );
});
