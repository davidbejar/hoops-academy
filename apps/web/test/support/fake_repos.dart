import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:built_collection/built_collection.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/admin/data/academy_repository.dart';
import 'package:hoops_app/features/admin/data/age_categories_repository.dart';
import 'package:hoops_app/features/admin/data/members_repository.dart';
import 'package:hoops_app/features/admin/data/seasons_repository.dart';
import 'package:hoops_app/features/roster/data/approvals_repository.dart';
import 'package:hoops_app/features/roster/data/cases_repository.dart';
import 'package:hoops_app/features/roster/data/players_repository.dart';
import 'package:hoops_app/features/roster/data/teams_repository.dart';

import 'core_fixtures.dart';

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

class FakeAcademyRepository with Faulty implements AcademyRepository {
  FakeAcademyRepository({api.TenantProfile? profile0, api.TenantSettings? settings0})
    : _profile = profile0 ?? profileFixture(),
      _settings = settings0 ?? settingsFixture();
  api.TenantProfile _profile;
  api.TenantSettings _settings;
  Uint8List? uploadedBytes;
  String? uploadedMime;
  bool logoDeleted = false;

  @override
  Future<api.TenantProfile> profile() => run('profile', () => _profile);
  @override
  Future<api.TenantSettings> settings() => run('settings', () => _settings);
  @override
  Future<api.TenantProfile> save({required api.UpdateTenantProfileRequest profile, required api.TenantSettings settings}) =>
      run('save', () {
        _settings = settings;
        _profile = _profile.rebuild((b) => b
          ..name = profile.name ?? _profile.name
          ..timezone = profile.timezone ?? _profile.timezone
          ..defaultLocale = profile.defaultLocale ?? _profile.defaultLocale);
        return _profile;
      });
  @override
  Future<api.TenantLogo> uploadLogo({required Uint8List bytes, required String mimeType, required String fileName}) =>
      run('uploadLogo', () {
        uploadedBytes = bytes;
        uploadedMime = mimeType;
        _profile = _profile.rebuild((b) => b.hasLogo = true);
        return api.TenantLogo(
          (b) => b
            ..contentType = api.TenantLogoContentTypeEnum.valueOf(mimeType)
            ..sizeBytes = bytes.length
            ..etag = 'etag-${bytes.length}'
            ..updatedAt = DateTime.utc(2026, 11, 1),
        );
      });
  @override
  Future<void> deleteLogo() => run('deleteLogo', () {
    logoDeleted = true;
    _profile = _profile.rebuild((b) => b.hasLogo = false);
  });
}

class FakeMembersRepository with Faulty implements MembersRepository {
  FakeMembersRepository(this.members, {List<api.GuardianLink>? links}) : links = links ?? [];
  final List<api.Member> members;
  final List<api.GuardianLink> links;
  String? lastQuery;
  api.InviteMemberRequest? invited;

  /// What the server returns for a login it creates (null: the person already had a login).
  String? newLoginPassword = 'test-temp-password-1';
  final List<String> reissuedFor = [];

  /// Thrown by `issueTemporaryPassword` only, e.g. a 409 `LOGIN_SHARED` Problem.
  Object? issueFails;

  static api.MemberWithPassword withPassword(api.Member m, String? password) => api.MemberWithPassword(
    (b) => b
      ..personId = m.personId
      ..givenName = m.givenName
      ..familyName = m.familyName
      ..displayName = m.displayName
      ..email = m.email
      ..roles = SetBuilder<api.TenantRole>(m.roles)
      ..active = m.active
      ..invitationStatus = m.invitationStatus
      ..temporaryPasswordStatus = m.temporaryPasswordStatus
      ..createdAt = m.createdAt
      ..temporaryPassword = password,
  );

  @override
  Future<List<api.Member>> list({String? query, api.TenantRole? role, bool? active}) => run('list', () {
    lastQuery = query;
    return [
      for (final m in members)
        if ((query == null || m.displayName.toLowerCase().contains(query.toLowerCase())) &&
            (active == null || m.active == active))
          m,
    ];
  });
  @override
  Future<api.MemberWithPassword> invite(api.InviteMemberRequest request) => run('invite', () {
    invited = request;
    final m = member('new-${members.length}', '${request.givenName} ${request.familyName}',
        roles: request.roles.toSet(),
        email: request.email,
        invitation: newLoginPassword == null ? api.InvitationStatus.ACCEPTED : api.InvitationStatus.PENDING);
    members.add(m);
    return withPassword(m, newLoginPassword);
  });
  @override
  Future<api.MemberWithPassword> issueTemporaryPassword(String personId) => run('issueTemporaryPassword', () {
    if (issueFails != null) throw issueFails!;
    final m = members.firstWhere((m) => m.personId == personId);
    if (m.invitationStatus != api.InvitationStatus.PENDING) {
      throw DioException(
        requestOptions: RequestOptions(path: '/members'),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/members'),
          statusCode: 409,
          data: {'status': 409, 'code': 'INVITATION_NOT_PENDING', 'detail': 'English server detail that must never be shown'},
        ),
      );
    }
    reissuedFor.add(personId);
    final renewed = m.rebuild((b) => b.temporaryPasswordStatus = api.TemporaryPasswordStatus.ACTIVE);
    members[members.indexOf(m)] = renewed;
    return withPassword(renewed, 'Reissued-${reissuedFor.length}');
  });
  @override
  Future<api.Member> replaceRoles(String personId, Set<api.TenantRole> roles) => run('replaceRoles', () {
    final i = members.indexWhere((m) => m.personId == personId);
    members[i] = members[i].rebuild((b) => b.roles.replace(roles));
    return members[i];
  });
  @override
  Future<api.Member> deactivate(String personId) => run('deactivate', () {
    final i = members.indexWhere((m) => m.personId == personId);
    members[i] = members[i].rebuild((b) => b.active = false);
    return members[i];
  });
  @override
  Future<List<api.GuardianLink>> guardianLinks({String? playerId, String? guardianPersonId}) => run('links', () => [
    for (final l in links)
      if ((playerId == null || l.player.id == playerId) &&
          (guardianPersonId == null || l.guardian.personId == guardianPersonId))
        l,
  ]);
  @override
  Future<api.GuardianLink> addGuardianLink({required String guardianPersonId, required String playerId}) =>
      run('addLink', () {
        final l = api.GuardianLink(
          (b) => b
            ..id = 'link-${links.length}'
            ..guardian.replace(personRef(guardianPersonId, 'Parent'))
            ..player.replace(playerRef(playerId, 'Player $playerId'))
            ..createdAt = DateTime.utc(2026, 1, 1),
        );
        links.add(l);
        return l;
      });
  @override
  Future<void> removeGuardianLink(String linkId) => run('removeLink', () => links.removeWhere((l) => l.id == linkId));
}

class FakeSeasonsRepository with Faulty implements SeasonsRepository {
  FakeSeasonsRepository(this.seasons, {this.rolloverResult});
  final List<api.Season> seasons;
  api.SeasonRolloverResult? rolloverResult;
  String? rolledFrom;
  bool? lastCloneStaff;
  bool? lastClonePlayers;

  @override
  Future<List<api.Season>> list() => run('list', () => [...seasons]);
  @override
  Future<api.Season> create({required String name, required api.Date startsOn, required api.Date endsOn, required int referenceYear}) =>
      run('create', () {
        final s = season('s-${seasons.length}', name);
        seasons.add(s);
        return s;
      });
  @override
  Future<api.Season> update(String id, {required String name, required api.Date startsOn, required api.Date endsOn, required int referenceYear}) =>
      run('update', () {
        final i = seasons.indexWhere((s) => s.id == id);
        seasons[i] = seasons[i].rebuild((b) => b.name = name);
        return seasons[i];
      });
  @override
  Future<api.SeasonRolloverResult> rollover(String fromSeasonId, {bool cloneStaff = true, bool clonePlayers = true}) =>
      run('rollover', () {
        rolledFrom = fromSeasonId;
        lastCloneStaff = cloneStaff;
        lastClonePlayers = clonePlayers;
        return rolloverResult ??
            api.SeasonRolloverResult((b) => b
              ..fromSeasonId = fromSeasonId
              ..toSeasonId = 'next');
      });
}

class FakeAgeCategoriesRepository with Faulty implements AgeCategoriesRepository {
  FakeAgeCategoriesRepository(this.categories);
  final List<api.AgeCategory> categories;

  @override
  Future<List<api.AgeCategory>> list() => run('list', () => [...categories]);
  @override
  Future<api.AgeCategory> create({required String code, required String name, int? maxAge, required int rank}) =>
      run('create', () {
        final c = category('c-${categories.length}', code, rank, maxAge: maxAge);
        categories.add(c);
        return c;
      });
  @override
  Future<api.AgeCategory> update(String id, {required String code, required String name, int? maxAge, required int rank}) =>
      run('update', () {
        final i = categories.indexWhere((c) => c.id == id);
        categories[i] = categories[i].rebuild((b) => b
          ..code = code
          ..name = name
          ..maxAge = maxAge
          ..rank = rank);
        return categories[i];
      });
  @override
  Future<void> delete(String id) => run('delete', () => categories.removeWhere((c) => c.id == id));
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
  Future<List<api.Team>> list({String? seasonId}) =>
      run('list', () => [for (final t in teams) if (seasonId == null || t.seasonId == seasonId) t]);
  @override
  Future<api.Team> get(String teamId) => run('get', () => teams.firstWhere((t) => t.id == teamId));
  @override
  Future<api.Team> create(api.CreateTeamRequest request) => run('create', () {
    lastCreate = request;
    final t = team('t-${teams.length}', request.name, alias: request.alias, policy: request.genderPolicy);
    teams.add(t);
    return t;
  });
  @override
  Future<api.Team> update(String teamId, api.UpdateTeamRequest request) => run('update', () {
    lastUpdate = request;
    final i = teams.indexWhere((t) => t.id == teamId);
    teams[i] = teams[i].rebuild((b) => b..name = request.name ?? teams[i].name);
    return teams[i];
  });
  @override
  Future<List<api.TeamPlayer>> roster(String teamId) => run('roster', () => [...?rosters[teamId]]);
  @override
  Future<List<api.TeamStaffMember>> staff(String teamId) => run('staff', () => [...?staffByTeam[teamId]]);
  @override
  Future<api.TeamStaffMember> putStaff(String teamId, String personId, api.StaffRole role) => run('putStaff', () {
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
  Future<void> removeStaff(String teamId, String personId) =>
      run('removeStaff', () => staffByTeam[teamId]?.removeWhere((s) => s.person.personId == personId));
  @override
  Future<api.EligibilityCheck> checkEligibility(String teamId, String playerId) => run(
    'check',
    () => checks['$teamId/$playerId'] ?? check(teamId, playerId, api.EligibilityResult.ELIGIBLE),
  );
  @override
  Future<api.TeamPlayer> assign(String teamId, String playerId, {String? jerseyNumber}) => run('assign', () {
    final tp = teamPlayer(teamId, playerId, 'Player $playerId', jersey: jerseyNumber);
    (rosters[teamId] ??= []).add(tp);
    return tp;
  });
  @override
  Future<void> unassign(String teamId, String playerId) =>
      run('unassign', () => rosters[teamId]?.removeWhere((p) => p.player.id == playerId));
  @override
  Future<api.TeamPlayer> setJersey(String teamId, String playerId, String? jerseyNumber) => run('setJersey', () {
    final list = rosters[teamId]!;
    final i = list.indexWhere((p) => p.player.id == playerId);
    list[i] = list[i].rebuild((b) => b.jerseyNumber = jerseyNumber);
    return list[i];
  });
}

class FakePlayersRepository with Faulty implements PlayersRepository {
  FakePlayersRepository(this.players, {this.eligible = const {}, this.createdPending = false});
  final List<api.Player> players;

  /// Eligible teams by player id.
  final Map<String, List<api.EligibleTeam>> eligible;
  final bool createdPending;

  /// Returned by `create` when the request carries an e-mail (null: the person already had a login).
  String? newLoginPassword = 'test-temp-password-1';
  api.CreatePlayerRequest? lastCreate;
  String? withdrawn;
  api.PlayerStatus? lastStatus;
  String? lastTeamId;

  @override
  Future<List<api.Player>> list({api.PlayerStatus? status, String? teamId, String? query}) => run('list', () {
    lastStatus = status;
    lastTeamId = teamId;
    return [
      for (final p in players)
        if ((status == null || p.status == status) &&
            (teamId == null || p.teams.any((t) => t.team.id == teamId)) &&
            (query == null || query.isEmpty || p.displayName.toLowerCase().contains(query.toLowerCase())))
          p,
    ];
  });
  @override
  Future<api.Player> get(String playerId) => run('get', () => players.firstWhere((p) => p.id == playerId));
  @override
  Future<api.PlayerCommandResult> create(api.CreatePlayerRequest request) => run('create', () {
    lastCreate = request;
    final p = player('new-${players.length}', '${request.givenName} ${request.familyName}',
        status: createdPending ? api.PlayerStatus.PENDING_APPROVAL : api.PlayerStatus.ACTIVE);
    players.add(p);
    return api.PlayerCommandResult(
      (b) => b
        ..player.replace(p)
        ..approvalRequest.replace(approval('a-new',
            status: createdPending ? api.ApprovalStatus.PENDING : api.ApprovalStatus.APPROVED))
        ..temporaryPassword = request.email == null || createdPending ? null : newLoginPassword,
    );
  });
  @override
  Future<api.PlayerCommandResult> withdraw(String playerId, {String? reason}) => run('withdraw', () {
    withdrawn = playerId;
    final i = players.indexWhere((p) => p.id == playerId);
    players[i] = players[i].rebuild((b) => b.status = api.PlayerStatus.WITHDRAWN);
    return api.PlayerCommandResult(
      (b) => b
        ..player.replace(players[i])
        ..approvalRequest.replace(approval('a-w', action: api.ApprovalAction.WITHDRAW_PLAYER,
            status: createdPending ? api.ApprovalStatus.PENDING : api.ApprovalStatus.APPROVED)),
    );
  });
  @override
  Future<List<api.EligibleTeam>> eligibleTeams(String playerId, String seasonId) =>
      run('eligibleTeams', () => eligible[playerId] ?? const []);
}

class FakeApprovalsRepository with Faulty implements ApprovalsRepository {
  FakeApprovalsRepository(this.requests);
  final List<api.ApprovalRequest> requests;
  String? lastNote;

  /// Temporary password per request id that the server creates a login for on approval.
  final Map<String, String> temporaryPasswords = {};

  void _set(String id, api.ApprovalStatus s, String? note) {
    final i = requests.indexWhere((r) => r.id == id);
    requests[i] = requests[i].rebuild((b) => b
      ..status = s
      ..decisionNote = note);
  }

  @override
  Future<List<api.ApprovalRequest>> list({api.ApprovalStatus? status}) =>
      run('list', () => [for (final r in requests) if (status == null || r.status == status) r]);
  @override
  Future<api.ApprovalRequestWithPassword> approve(String id, {String? note}) => run('approve', () {
    lastNote = note;
    _set(id, api.ApprovalStatus.APPROVED, note);
    final r = requests.firstWhere((r) => r.id == id);
    return api.ApprovalRequestWithPassword(
      (b) => b
        ..id = r.id
        ..action = r.action
        ..status = r.status
        ..player.replace(r.player)
        ..payload.replace(r.payload)
        ..requestedBy.replace(r.requestedBy)
        ..requestedAt = r.requestedAt
        ..decisionNote = r.decisionNote
        ..temporaryPassword = temporaryPasswords[id],
    );
  });
  @override
  Future<api.ApprovalRequest> reject(String id, {required String note}) => run('reject', () {
    lastNote = note;
    _set(id, api.ApprovalStatus.REJECTED, note);
    return requests.firstWhere((r) => r.id == id);
  });
  @override
  Future<api.ApprovalRequest> cancel(String id) => run('cancel', () {
    _set(id, api.ApprovalStatus.CANCELLED, null);
    return requests.firstWhere((r) => r.id == id);
  });
}

class FakeCasesRepository with Faulty implements CasesRepository {
  FakeCasesRepository(this.cases);
  final List<api.EligibilityCase> cases;
  String? resolvedId;
  api.EligibilityCaseResolution? resolution;
  String? target;

  @override
  Future<List<api.EligibilityCase>> list({api.EligibilityCaseStatus? status}) =>
      run('list', () => [for (final c in cases) if (status == null || c.status == status) c]);
  @override
  Future<api.EligibilityCase> resolve(String id,
      {required api.EligibilityCaseResolution resolution, String? targetTeamId, String? note}) =>
      run('resolve', () {
        resolvedId = id;
        this.resolution = resolution;
        target = targetTeamId;
        final i = cases.indexWhere((c) => c.id == id);
        cases[i] = cases[i].rebuild((b) => b
          ..status = api.EligibilityCaseStatus.RESOLVED
          ..resolution = resolution);
        return cases[i];
      });
}

/// One bundle of fakes with sensible demo data.
class FakeCore {
  FakeCore({
    FakeAcademyRepository? academy,
    FakeMembersRepository? members,
    FakeSeasonsRepository? seasons,
    FakeAgeCategoriesRepository? categories,
    FakeTeamsRepository? teams,
    FakePlayersRepository? players,
    FakeApprovalsRepository? approvals,
    FakeCasesRepository? cases,
  }) : academy = academy ?? FakeAcademyRepository(),
       members = members ?? FakeMembersRepository([]),
       seasons = seasons ?? FakeSeasonsRepository([season(seasonId, '2026/27', current: true)]),
       categories = categories ?? FakeAgeCategoriesRepository([u12, u14]),
       teams = teams ?? FakeTeamsRepository(teams: []),
       players = players ?? FakePlayersRepository([]),
       approvals = approvals ?? FakeApprovalsRepository([]),
       cases = cases ?? FakeCasesRepository([]);

  final FakeAcademyRepository academy;
  final FakeMembersRepository members;
  final FakeSeasonsRepository seasons;
  final FakeAgeCategoriesRepository categories;
  final FakeTeamsRepository teams;
  final FakePlayersRepository players;
  final FakeApprovalsRepository approvals;
  final FakeCasesRepository cases;
}
