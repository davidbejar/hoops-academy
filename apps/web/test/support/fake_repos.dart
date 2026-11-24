import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/export/server_file.dart';
import 'package:hoops_app/features/roster/data/players_repository.dart';
import 'package:hoops_app/features/roster/data/teams_repository.dart';

import 'core_fixtures.dart';
import 'core_seed.dart';
import 'mock_backend.dart';

/// Every fake can be told to fail (any exception) or hang, to cover the
/// error and loading states of the screens.
mixin Faulty {
  Object? failWith;
  bool hang = false;
  final List<String> calls = [];

  Future<T> run<T>(String name, T Function() body) async {
    calls.add(name);
    if (hang) await Completer<void>().future; // never completes
    if (failWith != null) throw failWith!;
    return body();
  }
}

class FakeTeamsRepository with Faulty implements TeamsRepository {
  FakeTeamsRepository({
    required this.teams,
    Map<String, List<api.TeamPlayer>>? rosters,
    Map<String, List<api.TeamStaffMember>>? staff,
    this.checks = const {},
  }) : rosters = rosters ?? {},
       staffByTeam = staff ?? {};
  final List<api.Team> teams;
  final Map<String, List<api.TeamPlayer>> rosters;
  final Map<String, List<api.TeamStaffMember>> staffByTeam;

  /// Verdict per `teamId/playerId`; default ELIGIBLE.
  final Map<String, api.EligibilityCheck> checks;
  api.UpdateTeamRequest? lastUpdate;
  api.CreateTeamRequest? lastCreate;

  @override
  Future<List<api.Team>> list({String? seasonId}) => run(
    'list',
    () => [
      for (final t in teams)
        if (seasonId == null || t.seasonId == seasonId) t,
    ],
  );
  @override
  Future<List<api.Team>> historicStaffTeams() => run(
    'historicStaffTeams',
    () => [
      for (final t in teams)
        if (t.seasonEnded && historicStaffIds.contains(t.id)) t,
    ],
  );

  /// Teams `historicStaffTeams` answers with (the caller's `historicStaffTeamIds`).
  final Set<String> historicStaffIds = {};
  @override
  Future<api.Team> get(String teamId) =>
      run('get', () => teams.firstWhere((t) => t.id == teamId));
  @override
  Future<api.Team> create(api.CreateTeamRequest request) => run('create', () {
    lastCreate = request;
    final t = team(
      't-${teams.length}',
      request.name,
      alias: request.alias,
      policy: request.genderPolicy,
    );
    teams.add(t);
    return t;
  });
  @override
  Future<api.Team> update(String teamId, api.UpdateTeamRequest request) =>
      run('update', () {
        lastUpdate = request;
        final i = teams.indexWhere((t) => t.id == teamId);
        teams[i] = teams[i].rebuild(
          (b) => b..name = request.name ?? teams[i].name,
        );
        return teams[i];
      });
  @override
  Future<List<api.TeamPlayer>> roster(String teamId) =>
      run('roster', () => [...?rosters[teamId]]);
  @override
  Future<List<api.TeamStaffMember>> staff(String teamId) =>
      run('staff', () => [...?staffByTeam[teamId]]);
  @override
  Future<api.TeamStaffMember> putStaff(
    String teamId,
    String personId,
    api.StaffRole role,
  ) => run('putStaff', () {
    final s = api.TeamStaffMember(
      (b) => b
        ..person.replace(personRef(personId, 'Staff $personId'))
        ..role = role
        ..since = api.Date(2026, 9, 1),
    );
    (staffByTeam[teamId] ??= []).add(s);
    return s;
  });
  @override
  Future<void> removeStaff(String teamId, String personId) => run(
    'removeStaff',
    () =>
        staffByTeam[teamId]?.removeWhere((s) => s.person.personId == personId),
  );
  @override
  Future<api.EligibilityCheck> checkEligibility(
    String teamId,
    String playerId,
  ) => run(
    'check',
    () =>
        checks['$teamId/$playerId'] ??
        check(teamId, playerId, api.EligibilityResult.ELIGIBLE),
  );

  /// Thrown by `setJersey` only (a clash the dialog could not see coming).
  Object? setJerseyFailure;

  /// The rule `assign` reports (core 3.5.0); the number it gives is the requested one, else [carriedNumber].
  api.JerseySource assignSource = api.JerseySource.REQUESTED;
  String? carriedNumber;
  api.AssignedTeamPlayer? lastAssigned;

  @override
  Future<api.AssignedTeamPlayer> assign(
    String teamId,
    String playerId, {
    String? jerseyNumber,
  }) => run('assign', () {
    final number = jerseyNumber ?? carriedNumber;
    final tp = teamPlayer(teamId, playerId, 'Player $playerId', jersey: number);
    (rosters[teamId] ??= []).add(tp);
    return lastAssigned = api.AssignedTeamPlayer(
      (b) => b
        ..player.replace(tp.player)
        ..teamId = tp.teamId
        ..jerseyNumber = tp.jerseyNumber
        ..joinedOn = tp.joinedOn
        ..playUpLevels = tp.playUpLevels
        ..playerStatus = tp.playerStatus
        ..jerseySource = jerseyNumber != null
            ? api.JerseySource.REQUESTED
            : assignSource,
    );
  });
  @override
  Future<void> unassign(String teamId, String playerId) => run(
    'unassign',
    () => rosters[teamId]?.removeWhere((p) => p.player.id == playerId),
  );
  @override
  Future<api.TeamPlayer> setJersey(
    String teamId,
    String playerId,
    String? jerseyNumber,
  ) => run('setJersey', () {
    final failure = setJerseyFailure;
    if (failure != null) throw failure;
    final list = rosters[teamId]!;
    final i = list.indexWhere((p) => p.player.id == playerId);
    list[i] = list[i].rebuild((b) => b.jerseyNumber = jerseyNumber);
    return list[i];
  });

  @override
  Future<List<api.TakenJerseyNumber>> jerseyNumbers(String teamId) => run(
    'jerseyNumbers',
    () => [
      for (final tp in rosters[teamId] ?? const <api.TeamPlayer>[])
        if (tp.jerseyNumber != null)
          api.TakenJerseyNumber(
            (b) => b
              ..jerseyNumber = tp.jerseyNumber
              ..player.replace(tp.player),
          ),
    ],
  );

  /// Thrown by `exportRoster` only (a Problem of the server).
  Object? exportFailure;

  /// The team and language of every roster export asked for.
  final List<(String, String)> rosterExports = [];

  /// What `exportRoster` answers (a UTF-8 CSV).
  Uint8List rosterCsv = Uint8List.fromList(
    utf8.encode('Role,Name\r\nPLAYER,Ana\r\n'),
  );

  @override
  Future<Uint8List> exportRoster(String teamId, {required String language}) =>
      run('exportRoster', () {
        final failure = exportFailure;
        if (failure != null) throw failure;
        rosterExports.add((teamId, language));
        return rosterCsv;
      });

  /// The team and language of every roster PDF asked for.
  final List<(String, String)> rosterPdfs = [];

  /// What `exportRosterPdf` answers; its file name is the server's.
  ServerFile rosterPdf = ServerFile(
    Uint8List.fromList(utf8.encode('%PDF-1.7 roster')),
    fileName: 'hoops-role-test-roster-mini-a-20261116.pdf',
  );

  @override
  Future<ServerFile> exportRosterPdf(
    String teamId, {
    required String language,
  }) => run('exportRosterPdf', () {
    final failure = exportFailure;
    if (failure != null) throw failure;
    rosterPdfs.add((teamId, language));
    return rosterPdf;
  });
}

class FakePlayersRepository with Faulty implements PlayersRepository {
  FakePlayersRepository(
    this.players, {
    this.eligible = const {},
    this.createdPending = false,
  });
  final List<api.Player> players;

  /// Eligible teams by player id.
  final Map<String, List<api.EligibleTeam>> eligible;
  final bool createdPending;

  /// Returned by `create` when the request carries an e-mail (null: the person already had a login).
  String? newLoginPassword = 'test-temp-password-1';
  api.CreatePlayerRequest? lastCreate;
  String? withdrawn;

  /// The player and number of the last `setPreferredJersey` (null number: removed).
  (String, String?)? lastPreferred;
  api.PlayerStatus? lastStatus;
  String? lastTeamId;

  @override
  Future<List<api.Player>> list({
    api.PlayerStatus? status,
    String? teamId,
    String? query,
  }) => run('list', () {
    lastStatus = status;
    lastTeamId = teamId;
    return [
      for (final p in players)
        if ((status == null || p.status == status) &&
            (teamId == null || p.teams.any((t) => t.team.id == teamId)) &&
            (query == null ||
                query.isEmpty ||
                p.displayName.toLowerCase().contains(query.toLowerCase())))
          p,
    ];
  });
  @override
  Future<api.Player> get(String playerId) =>
      run('get', () => players.firstWhere((p) => p.id == playerId));
  @override
  Future<api.Player> setPreferredJersey(String playerId, String? number) => run(
    'setPreferredJersey',
    () {
      lastPreferred = (playerId, number);
      final i = players.indexWhere((p) => p.id == playerId);
      players[i] = players[i].rebuild((b) => b.preferredJerseyNumber = number);
      return players[i];
    },
  );
  @override
  Future<api.PlayerCommandResult> create(api.CreatePlayerRequest request) =>
      run('create', () {
        lastCreate = request;
        final p = player(
          'new-${players.length}',
          '${request.givenName} ${request.familyName}',
          status: createdPending
              ? api.PlayerStatus.PENDING_APPROVAL
              : api.PlayerStatus.ACTIVE,
        );
        players.add(p);
        return api.PlayerCommandResult(
          (b) => b
            ..player.replace(p)
            ..approvalRequest.replace(
              approval(
                'a-new',
                status: createdPending
                    ? api.ApprovalStatus.PENDING
                    : api.ApprovalStatus.APPROVED,
              ),
            )
            ..temporaryPassword = request.email == null || createdPending
                ? null
                : newLoginPassword,
        );
      });
  @override
  Future<api.PlayerCommandResult> withdraw(String playerId, {String? reason}) =>
      run('withdraw', () {
        withdrawn = playerId;
        final i = players.indexWhere((p) => p.id == playerId);
        players[i] = players[i].rebuild(
          (b) => b.status = api.PlayerStatus.WITHDRAWN,
        );
        return api.PlayerCommandResult(
          (b) => b
            ..player.replace(players[i])
            ..approvalRequest.replace(
              approval(
                'a-w',
                action: api.ApprovalAction.WITHDRAW_PLAYER,
                status: createdPending
                    ? api.ApprovalStatus.PENDING
                    : api.ApprovalStatus.APPROVED,
              ),
            ),
        );
      });
  @override
  Future<List<api.EligibleTeam>> eligibleTeams(
    String playerId,
    String seasonId,
  ) => run('eligibleTeams', () => eligible[playerId] ?? const []);
}

/// The academy's core data of a test: seeded into the backend (ADR-0070) for
/// what is migrated, in-memory fakes for the rest.
class FakeCore {
  FakeCore({
    api.TenantProfile? profile,
    api.TenantSettings? settings,
    MembersData? members,
    List<api.Season>? seasons,
    List<api.AgeCategory>? categories,
    FakeTeamsRepository? teams,
    FakePlayersRepository? players,
    this.approvals = const [],
    this.cases = const [],
  }) : profile = profile ?? profileFixture(),
       settings = settings ?? settingsFixture(),
       members = members ?? MembersData([]),
       seasons = seasons ?? [season(seasonId, '2026/27', current: true)],
       categories = categories ?? [u12, u14],
       teams = teams ?? FakeTeamsRepository(teams: []),
       players = players ?? FakePlayersRepository([]);

  /// The academy's profile and settings (`/api/core/tenant`).
  final api.TenantProfile profile;
  final api.TenantSettings settings;

  /// The members and guardian links, then what the app did with them.
  final MembersData members;

  /// The seasons and age categories (`/api/core/seasons`, `/age-categories`).
  final List<api.Season> seasons;
  final List<api.AgeCategory> categories;
  final FakeTeamsRepository teams;
  final FakePlayersRepository players;

  /// Approval requests and eligibility cases (`/approval-requests`, `/eligibility-cases`).
  final List<api.ApprovalRequest> approvals;
  final List<api.EligibilityCase> cases;

  /// Seeds the migrated data into [backend]; the teams and players of the
  /// fakes too, so what the mock lets the user do (staff of a team) and the
  /// decisions on cases (a reassignment) work on the same roster.
  void seed(MockBackend backend) {
    backend
      ..seedProfile(profile)
      ..seedSettings(settings)
      ..seedSeasons(seasons)
      ..seedCategories(categories)
      ..seedApprovals(approvals)
      ..seedCases(cases)
      ..seedTeams(teams.teams)
      ..seedPlayers(players.players);
    members.seedInto(backend);
  }
}
