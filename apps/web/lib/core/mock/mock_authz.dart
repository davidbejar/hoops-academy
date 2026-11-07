/// What the signed-in demo user may see in one academy, derived from the membership roles and the live roster /
/// guardian links of the core mock (`docs/domain/authz-matrix.md`). The athlete and game mocks ask this instead of
/// keeping a role list of their own, so a player moved or a link added in the demo changes what every role sees.
class MockAuthz {
  const MockAuthz({
    required this.roles,
    required this.staffTeamIds,
    this.historicStaffTeamIds = const {},
    required this.linkedPlayerIds,
    required this.selfPlayerIds,
    required this.teamsOf,
    required this.rosterOf,
    required this.allTeamIds,
  });

  final Set<String> roles;

  /// Teams the user is staff of (COACH / ASSISTANT_COACH only).
  final Set<String> staffTeamIds;

  /// Teams of ended seasons the user was staff of: readable history (ADR-0042), never in [staffTeamIds].
  final Set<String> historicStaffTeamIds;

  /// Players the user is a guardian of (PARENT only).
  final Set<String> linkedPlayerIds;

  /// The user's own player records (PLAYER only).
  final Set<String> selfPlayerIds;

  final Set<String> Function(String playerId) teamsOf;
  final Set<String> Function(String teamId) rosterOf;
  final Set<String> allTeamIds;

  bool get admin => roles.contains('ADMIN');
  bool get coachRole =>
      roles.contains('COACH') || roles.contains('ASSISTANT_COACH');

  /// Staff in the matrix sense: may write training, health and match data (for their teams unless admin).
  bool get staff => admin || coachRole;

  /// Teams of the players the user is linked to or is.
  Set<String> get playerTeamIds => {
    for (final p in {...linkedPlayerIds, ...selfPlayerIds}) ...teamsOf(p),
  };

  /// Teams whose schedule, sessions and matches the user reads.
  bool canSeeTeam(String teamId) =>
      admin ||
      staffTeamIds.contains(teamId) ||
      historicStaffTeamIds.contains(teamId) ||
      playerTeamIds.contains(teamId);

  /// Staff of the team (or an admin): may mark attendance and write for the team's players.
  bool canManageTeam(String teamId) => admin || staffTeamIds.contains(teamId);

  bool _staffOf(String playerId) =>
      teamsOf(playerId).any(staffTeamIds.contains);

  /// Whether the player's data is visible: staff of the player's team, a linked guardian, the player.
  bool canSeePlayer(String playerId) =>
      admin ||
      linkedPlayerIds.contains(playerId) ||
      selfPlayerIds.contains(playerId) ||
      _staffOf(playerId);

  /// Write rights on a player's health data: staff of the team and guardians; a player only reads himself.
  bool canWritePlayer(String playerId) =>
      admin || linkedPlayerIds.contains(playerId) || _staffOf(playerId);

  /// Planned absences and plan completions: also the player himself.
  bool canRecordFor(String playerId) =>
      canWritePlayer(playerId) || selfPlayerIds.contains(playerId);

  /// All players a guardian or a player is limited to, null for staff (limited by team instead).
  Set<String>? get ownPlayerIds =>
      staff ? null : {...linkedPlayerIds, ...selfPlayerIds};
}
