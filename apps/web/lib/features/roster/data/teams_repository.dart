import '../../../core/api/api.dart' as api;
import '../../../core/api/clear_list.dart';

/// Teams, staff and rosters (`/api/core/teams*`).
abstract class TeamsRepository {
  Future<List<api.Team>> list({String? seasonId});

  /// The caller's own teams of ended seasons (`staffedByMe` + `includeEnded`, ADR-0042); read-only history.
  Future<List<api.Team>> historicStaffTeams();
  Future<api.Team> get(String teamId);
  Future<api.Team> create(api.CreateTeamRequest request);
  Future<api.Team> update(String teamId, api.UpdateTeamRequest request);

  Future<List<api.TeamPlayer>> roster(String teamId);
  Future<List<api.TeamStaffMember>> staff(String teamId);
  Future<api.TeamStaffMember> putStaff(
    String teamId,
    String personId,
    api.StaffRole role,
  );
  Future<void> removeStaff(String teamId, String personId);

  Future<api.EligibilityCheck> checkEligibility(String teamId, String playerId);
  Future<api.TeamPlayer> assign(
    String teamId,
    String playerId, {
    String? jerseyNumber,
  });
  Future<void> unassign(String teamId, String playerId);

  /// A null [jerseyNumber] removes the jersey (named in `clear`, ADR-0032).
  Future<api.TeamPlayer> setJersey(
    String teamId,
    String playerId,
    String? jerseyNumber,
  );
}

class ApiTeamsRepository implements TeamsRepository {
  ApiTeamsRepository(api.HoopsCoreApi client, this._t)
    : _api = client.getTeamsApi();

  final api.TeamsApi _api;
  final String _t;

  @override
  Future<List<api.Team>> list({String? seasonId}) async =>
      (await _api.listTeams(
        xTenantId: _t,
        seasonId: seasonId,
        size: 100,
      )).data!.items.toList();

  @override
  Future<List<api.Team>> historicStaffTeams() async => [
    for (final t in (await _api.listTeams(
      xTenantId: _t,
      staffedByMe: true,
      includeEnded: true,
      size: 100,
    )).data!.items)
      if (t.seasonEnded) t,
  ];

  @override
  Future<api.Team> get(String teamId) async =>
      (await _api.getTeam(xTenantId: _t, teamId: teamId)).data!;

  @override
  Future<api.Team> create(api.CreateTeamRequest request) async =>
      (await _api.createTeam(xTenantId: _t, createTeamRequest: request)).data!;

  @override
  Future<api.Team> update(String teamId, api.UpdateTeamRequest request) async =>
      (await _api.updateTeam(
        xTenantId: _t,
        teamId: teamId,
        updateTeamRequest: request,
      )).data!;

  @override
  Future<List<api.TeamPlayer>> roster(String teamId) async =>
      (await _api.listTeamPlayers(
        xTenantId: _t,
        teamId: teamId,
      )).data!.toList();

  @override
  Future<List<api.TeamStaffMember>> staff(String teamId) async =>
      (await _api.listTeamStaff(xTenantId: _t, teamId: teamId)).data!.toList();

  @override
  Future<api.TeamStaffMember> putStaff(
    String teamId,
    String personId,
    api.StaffRole role,
  ) async => (await _api.putTeamStaffMember(
    xTenantId: _t,
    teamId: teamId,
    personId: personId,
    teamStaffAssignment: api.TeamStaffAssignment((b) => b.role = role),
  )).data!;

  @override
  Future<void> removeStaff(String teamId, String personId) async {
    await _api.removeTeamStaffMember(
      xTenantId: _t,
      teamId: teamId,
      personId: personId,
    );
  }

  @override
  Future<api.EligibilityCheck> checkEligibility(
    String teamId,
    String playerId,
  ) async => (await _api.checkPlayerEligibility(
    xTenantId: _t,
    teamId: teamId,
    playerId: playerId,
  )).data!;

  @override
  Future<api.TeamPlayer> assign(
    String teamId,
    String playerId, {
    String? jerseyNumber,
  }) async => (await _api.assignPlayerToTeam(
    xTenantId: _t,
    teamId: teamId,
    assignPlayerRequest: api.AssignPlayerRequest(
      (b) => b
        ..playerId = playerId
        ..jerseyNumber = jerseyNumber,
    ),
  )).data!;

  @override
  Future<void> unassign(String teamId, String playerId) async {
    await _api.unassignPlayerFromTeam(
      xTenantId: _t,
      teamId: teamId,
      playerId: playerId,
    );
  }

  @override
  Future<api.TeamPlayer> setJersey(
    String teamId,
    String playerId,
    String? jerseyNumber,
  ) async => (await _api.updateTeamPlayer(
    xTenantId: _t,
    teamId: teamId,
    playerId: playerId,
    updateTeamPlayerRequest: api.UpdateTeamPlayerRequest(
      (b) => b
        ..jerseyNumber = jerseyNumber
        ..clear = clearList({
          api.UpdateTeamPlayerRequestClearEnum.jerseyNumber: jerseyNumber,
        }),
    ),
  )).data!;
}
