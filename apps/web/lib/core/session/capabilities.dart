import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/me/domain/current_user.dart';
import '../../features/roster/application/season_view.dart';
import 'session.dart';
import 'session_providers.dart';

/// What the caller may do in the admin / roster module, mirroring
/// `docs/domain/authz-matrix.md`. UI affordances only: the server authorises
/// every call again.
class Capabilities {
  const Capabilities({
    required this.roles,
    this.staffTeamIds = const {},
    this.historicStaffTeamIds = const {},
    this.endedTeamIds = const {},
    this.viewingPastSeason = false,
    this.linkedPlayerIds = const {},
    this.personId,
    this.ownPlayerId,
  });

  static const none = Capabilities(roles: {});

  final Set<TenantRole> roles;
  final Set<String> staffTeamIds;

  /// Teams of ended seasons the caller was staff of: readable, never writable (ADR-0042).
  final Set<String> historicStaffTeamIds;

  /// Every team of the academy whose season has ended (core's `Team.seasonEnded`): nobody writes on them, the admin
  /// included (409 `SEASON_ENDED`).
  final Set<String> endedTeamIds;

  /// A past season is on screen (the season selector): every write affordance is off.
  final bool viewingPastSeason;

  /// Players linked to the caller as guardian (PARENT), from `/me.authz`.
  final Set<String> linkedPlayerIds;
  final String? personId;

  /// The caller's own player id (PLAYER role).
  final String? ownPlayerId;

  bool get _admin => roles.contains(TenantRole.admin);

  bool get isAdmin => _admin;

  bool _open(String teamId) => !endedTeamIds.contains(teamId);

  /// The season selector: an admin, or a coach / assistant with history (`historicStaffTeamIds`).
  bool get canBrowseSeasons =>
      _admin || ((_coach || _assistant) && historicStaffTeamIds.isNotEmpty);
  bool get _coach => roles.contains(TenantRole.coach);
  bool get _assistant => roles.contains(TenantRole.assistantCoach);

  /// ADMIN / COACH / ASSISTANT_COACH; PARENT and PLAYER never.
  bool get canSeeModule => _admin || _coach || _assistant;

  /// Profile, logo, members, seasons, age categories.
  bool get canManageAcademy => _admin;

  /// Team create / edit / staff.
  bool get canManageTeams => _admin;

  /// Edit the team and its staff: ADMIN, on a team of a season that has not ended.
  bool canManageTeam(String teamId) => _admin && _open(teamId);

  bool isStaffOf(String teamId) => staffTeamIds.contains(teamId);

  /// Assign / unassign players and jersey numbers.
  bool canEditRoster(String teamId) =>
      (_admin || (_coach && isStaffOf(teamId))) && _open(teamId);

  /// Resolving an eligibility case stays possible after the season (ADR-0042).
  bool canResolveCase(String teamId) => _admin || (_coach && isStaffOf(teamId));

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
  bool canRunMatch(String teamId) =>
      (_admin || ((_coach || _assistant) && isStaffOf(teamId))) &&
      _open(teamId);

  /// PARENT may enter stat events of linked players only.
  bool isLinkedTo(String playerId) =>
      roles.contains(TenantRole.parent) && linkedPlayerIds.contains(playerId);

  // ------------------------------------------------- training & health (WP14)

  bool get _staff => _admin || _coach || _assistant;

  /// Schedules, sessions, attendance of [teamId]: ADMIN or team staff.
  bool canManageTraining(String teamId) =>
      (_admin || (_staff && isStaffOf(teamId))) && _open(teamId);

  /// Read the whole attendance sheet of [teamId]: ADMIN, staff and former staff (ADR-0042).
  bool canReadTraining(String teamId) =>
      _admin ||
      (_staff && (isStaffOf(teamId) || historicStaffTeamIds.contains(teamId)));

  /// Any team the caller can schedule for (create buttons on the calendar).
  bool get canManageAnyTraining =>
      !viewingPastSeason && (_admin || (_staff && staffTeamIds.isNotEmpty));

  /// Plan library write access (ADMIN, COACH, ASSISTANT_COACH).
  bool get canEditPlans => _staff;

  /// Assign plans: ADMIN or team staff.
  bool get canAssignPlans =>
      !viewingPastSeason && (_admin || (_staff && staffTeamIds.isNotEmpty));

  /// Planned absence: staff for anyone, PARENT for linked, PLAYER for self.
  bool canFileAbsenceFor(String playerId) =>
      _staff || isLinkedTo(playerId) || isSelf(playerId);

  bool get canFileAbsences =>
      _staff || linkedPlayerIds.isNotEmpty || ownPlayerId != null;

  bool isSelf(String playerId) =>
      roles.contains(TenantRole.player) && ownPlayerId == playerId;

  /// Mark a plan completion: staff, linked parent, the player themself.
  bool canMarkCompletion(String playerId) =>
      _staff || isLinkedTo(playerId) || isSelf(playerId);

  /// Injuries and body measurements: staff and linked parents write; the
  /// player only reads.
  bool canWriteHealth(String playerId) =>
      !viewingPastSeason && (_staff || isLinkedTo(playerId));

  /// Test results entry (staff only; parents / players read).
  bool get canEnterTestResults => !viewingPastSeason && _staff;

  /// Custom test types and tenant norm overrides (ADMIN).
  bool get canAdminFitness => _admin;

  /// Any team the caller runs matches for (create button on the list).
  bool get canCreateMatches =>
      !viewingPastSeason &&
      (_admin || ((_coach || _assistant) && staffTeamIds.isNotEmpty));

  @override
  bool operator ==(Object other) =>
      other is Capabilities &&
      setEquals(roles, other.roles) &&
      setEquals(staffTeamIds, other.staffTeamIds) &&
      setEquals(historicStaffTeamIds, other.historicStaffTeamIds) &&
      setEquals(endedTeamIds, other.endedTeamIds) &&
      viewingPastSeason == other.viewingPastSeason &&
      setEquals(linkedPlayerIds, other.linkedPlayerIds) &&
      personId == other.personId &&
      ownPlayerId == other.ownPlayerId;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(roles),
    Object.hashAllUnordered(staffTeamIds),
    Object.hashAllUnordered(historicStaffTeamIds),
    Object.hashAllUnordered(endedTeamIds),
    viewingPastSeason,
    Object.hashAllUnordered(linkedPlayerIds),
    personId,
    ownPlayerId,
  );
}

final capabilitiesProvider = Provider<Capabilities>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is! Ready) return Capabilities.none;
  final m = session.membership;
  return Capabilities(
    roles: session.roles,
    staffTeamIds: m?.staffTeamIds ?? const {},
    historicStaffTeamIds: m?.historicStaffTeamIds ?? const {},
    endedTeamIds: ref.watch(endedTeamIdsProvider),
    viewingPastSeason: ref.watch(viewingPastSeasonProvider),
    linkedPlayerIds: m?.linkedPlayerIds ?? const {},
    personId: m?.personId,
    ownPlayerId: m?.ownPlayerId,
  );
});
