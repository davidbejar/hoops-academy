import 'dart:typed_data';

import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import 'mock_backend.dart';

/// A small PNG stands in for an uploaded logo.
final seededLogo = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);

String _wire<T>(T value) =>
    api.standardSerializers.serialize(value, specifiedType: FullType(T))!
        as String;

/// Seeds the academy's core data (ADR-0070) from the generated models the
/// fixtures build (`core_fixtures.dart`), keeping the mock coherent: a roster
/// is the players' team assignments, a team's staff its staff rows.
extension CoreSeed on MockBackend {
  /// The academy's profile; `hasLogo` stores a logo.
  void seedProfile(api.TenantProfile profile) {
    core.profile
      ..clear()
      ..addAll({
        'slug': profile.slug,
        'name': profile.name,
        'timezone': profile.timezone,
        'defaultLocale': _wire(profile.defaultLocale),
        'contactEmail': profile.contactEmail,
        'websiteUrl': profile.websiteUrl,
      });
    core.logo = profile.hasLogo ? seededLogo : null;
  }

  void seedSettings(api.TenantSettings settings) => core.settings
    ..clear()
    ..addAll(coreJson(settings));

  void seedSeasons(Iterable<api.Season> seasons) =>
      core.seasons.addAll(seasons.map(coreJson));

  void seedCategories(Iterable<api.AgeCategory> categories) =>
      core.categories.addAll(categories.map(coreJson));

  void seedTeams(Iterable<api.Team> teams) {
    for (final t in teams) {
      core.teams
        ..removeWhere((x) => x['id'] == t.id)
        ..add(coreJson(t));
    }
  }

  /// Players with their assignments (`teams`).
  void seedPlayers(Iterable<api.Player> players) {
    for (final p in players) {
      core.players
        ..removeWhere((x) => x['id'] == p.id)
        ..add(coreJson(p));
    }
  }

  /// The roster of [teamId]: each entry becomes an assignment of its player
  /// (a player not seeded yet is created from the entry).
  void seedRoster(String teamId, Iterable<api.TeamPlayer> roster) {
    final team = core.teams.where((t) => t['id'] == teamId).firstOrNull;
    for (final tp in roster) {
      var p = core.players.where((x) => x['id'] == tp.player.id).firstOrNull;
      if (p == null) {
        final name = tp.player.displayName;
        p = {
          'id': tp.player.id,
          'personId': 'person-${tp.player.id}',
          'givenName': name.split(' ').first,
          'familyName': name.split(' ').last,
          'displayName': name,
          'birthDate': '2015-03-04',
          'gender': 'MALE',
          'status': _wire(tp.playerStatus),
          'teams': <Object?>[],
          'createdAt': '2026-01-01T00:00:00.000Z',
        };
        core.players.add(p);
      }
      final teams = p['teams']! as List;
      teams
        ..removeWhere((a) => ((a as Map)['team'] as Map)['id'] == teamId)
        ..add({
          'team': {'id': teamId, 'name': team?['name'] ?? teamId},
          'jerseyNumber': tp.jerseyNumber,
          'playUpLevels': tp.playUpLevels,
          'valid': tp.invalidatedAt == null,
        });
    }
  }

  void seedStaff(String teamId, Iterable<api.TeamStaffMember> staff) =>
      (core.staff[teamId] ??= []).addAll(staff.map(coreJson));

  void seedMembers(Iterable<api.Member> members) =>
      core.members.addAll(members.map(coreJson));

  void seedGuardianLinks(Iterable<api.GuardianLink> links) =>
      core.guardianLinks.addAll(links.map(coreJson));

  void seedApprovals(Iterable<api.ApprovalRequest> requests) =>
      core.approvals.addAll(requests.map(coreJson));

  void seedCases(Iterable<api.EligibilityCase> cases) =>
      core.cases.addAll(cases.map(coreJson));

  /// Makes what the mock lets the test user do match [m] (`/me`'s authz):
  /// staff rows on the seeded teams of `staffTeamIds` and
  /// `historicStaffTeamIds`, guardian links to `linkedPlayerIds`, the own
  /// player's person. Rows that already exist are kept.
  void seedMembership(TenantMembership m) {
    final self = selfId;
    final name = [m.givenName, m.familyName].whereType<String>().join(' ');
    final staffRole = m.roles.contains(TenantRole.coach)
        ? 'COACH'
        : 'ASSISTANT_COACH';
    for (final teamId in {...m.staffTeamIds, ...m.historicStaffTeamIds}) {
      final rows = core.staff[teamId] ??= [];
      if (rows.any((s) => (s['person']! as Map)['personId'] == self)) continue;
      rows.add({
        'person': {'personId': self, 'displayName': name},
        'role': staffRole,
        'since': '2026-09-01',
      });
    }
    for (final playerId in m.linkedPlayerIds) {
      final exists = core.guardianLinks.any(
        (l) =>
            (l['guardian']! as Map)['personId'] == self &&
            (l['player']! as Map)['id'] == playerId,
      );
      if (exists) continue;
      final p = core.players.where((p) => p['id'] == playerId).firstOrNull;
      core.guardianLinks.add({
        'id': 'link-me-$playerId',
        'guardian': {'personId': self, 'displayName': name},
        'player': {
          'id': playerId,
          'displayName': p?['displayName'] ?? playerId,
        },
        'createdAt': '2026-01-01T00:00:00.000Z',
      });
    }
    final own = m.ownPlayerId;
    if (own != null) {
      for (final p in core.players.where((p) => p['id'] == own)) {
        p['personId'] = self;
      }
    }
  }
}

/// What `/api/core/members` and the guardian links hold for a test, and
/// afterwards what the app did with them (ADR-0070). Before the backend is
/// seeded the lists are the seed; once seeded they are read back from the
/// mock, and the other getters from the requests the app sent. Failures go to
/// the backend.
class MembersData {
  MembersData(this._members, {List<api.GuardianLink>? links})
    : _links = links ?? [];

  final List<api.Member> _members;
  final List<api.GuardianLink> _links;
  MockBackend? _backend;

  /// E-mails that already sign in to another academy (linked, no password).
  final Set<String> loginsElsewhere = {};

  static final _api = RegExp('^/api/core/(members|guardian-links)');
  static const _list = '/api/core/members';

  void seedInto(MockBackend backend) {
    _backend = backend;
    backend
      ..seedMembers(_members)
      ..seedGuardianLinks(_links);
    backend.core.loginsElsewhere.addAll(loginsElsewhere);
    if (_hang) backend.hang(_api);
    if (_failWith != null) _inject(_failWith!, _api);
    if (_issueFails != null) _inject(_issueFails!, _issuePath);
  }

  MockBackend get _b => _backend!;

  static T _from<T>(Object? json) =>
      api.standardSerializers.deserialize(json, specifiedType: FullType(T))
          as T;

  List<api.Member> get members => _backend == null
      ? _members
      : [for (final m in _b.core.members) _from<api.Member>(m)];

  List<api.GuardianLink> get links => _backend == null
      ? _links
      : [for (final l in _b.core.guardianLinks) _from<api.GuardianLink>(l)];

  bool _hang = false;
  set hang(bool value) {
    _hang = value;
    if (_backend != null && value) _b.hang(_api);
  }

  Object? _failWith;

  /// Fails every members and guardian-link call (null: heals).
  set failWith(Object? error) {
    _failWith = error;
    if (_backend == null) return;
    error == null ? _b.heal() : _inject(error, _api);
  }

  static final _issuePath = RegExp(r'/temporary-password$');
  Object? _issueFails;

  /// Fails only the issue of a temporary password.
  set issueFails(Object? error) {
    _issueFails = error;
    if (_backend != null && error != null) _inject(error, _issuePath);
  }

  void _inject(Object error, Pattern path) {
    final b = _backend!;
    if (error is AppError) {
      if (error.kind == AppErrorKind.network) return b.networkDown(path);
      final status =
          error.status ??
          switch (error.kind) {
            AppErrorKind.conflict => 409,
            AppErrorKind.timeout => 504,
            AppErrorKind.validation => 422,
            _ => 500,
          };
      return b.fail(path, status: status, code: error.code);
    }
    if (error is DioException) {
      final data = error.response?.data as Map?;
      return b.fail(
        path,
        status: error.response?.statusCode ?? 500,
        code: data?['code'] as String?,
      );
    }
    b.fail(path);
  }

  /// The search text of the last list request.
  String? get lastQuery => _b.lastQuery(_list).text('q');

  /// The last invitation sent, null when none.
  api.InviteMemberRequest? get invited {
    final sent = _b.requestsTo(_list, method: 'POST');
    return sent.isEmpty
        ? null
        : _from<api.InviteMemberRequest>(MockBackend.bodyOf(sent.last));
  }

  /// The password of the last login the mock created for a member.
  String? get newLoginPassword {
    final sent = _b.requests.where(
      (r) =>
          r.method.toUpperCase() == 'POST' &&
          (r.path == _list || _issuePath.hasMatch(r.path)),
    );
    if (sent.isEmpty) return null;
    final a = _b.lastAnswer(sent.last.path, method: 'POST');
    return a is Map ? a['temporaryPassword'] as String? : null;
  }

  /// The people a temporary password was issued for, in order.
  List<String> get reissuedFor => [
    for (final r in _b.requestsTo(_issuePath, method: 'POST'))
      r.path.split('/')[4],
  ];

  /// Every member update as the dialog sent it (a cleared value is null).
  List<
    ({
      String personId,
      String givenName,
      String familyName,
      String? email,
      String? phone,
      api.Date? birthDate,
      api.Gender? gender,
    })
  >
  get updates => [
    for (final r in _b.requestsTo(
      RegExp(r'^/api/core/members/[^/]+$'),
      method: 'PATCH',
    ))
      () {
        final b = MockBackend.bodyOf(r);
        final day = b['birthDate'] as String?;
        return (
          personId: r.path.split('/').last,
          givenName: b['givenName']! as String,
          familyName: b['familyName']! as String,
          email: b['email'] as String?,
          phone: b['phone'] as String?,
          birthDate: day == null ? null : _from<api.Date>(day),
          gender: b['gender'] == null ? null : _from<api.Gender>(b['gender']),
        );
      }(),
  ];

  /// The repository operations the app called, by the fakes' names.
  List<String> get calls => [
    for (final r in _b.requests)
      if (_api.hasMatch(r.path))
        switch ((r.method.toUpperCase(), r.path)) {
          ('GET', '/api/core/guardian-links') => 'links',
          ('POST', '/api/core/guardian-links') => 'addLink',
          ('DELETE', _) when r.path.startsWith('/api/core/guardian-links/') =>
            'removeLink',
          ('GET', _list) => 'list',
          ('POST', _list) => 'invite',
          _ => '${r.method} ${r.path}',
        },
  ];
}

/// Turns a fake's `failWith` / `hang` into a fault of [backend] on [path].
void _injectInto(MockBackend backend, Object error, Pattern path) {
  if (error is AppError) {
    if (error.kind == AppErrorKind.network) {
      return backend.networkDown(path);
    }
    final status =
        error.status ??
        switch (error.kind) {
          AppErrorKind.conflict => 409,
          AppErrorKind.timeout => 504,
          AppErrorKind.validation => 422,
          AppErrorKind.notFound => 404,
          _ => 500,
        };
    return backend.fail(path, status: status, code: error.code);
  }
  if (error is DioException) {
    final data = error.response?.data as Map?;
    return backend.fail(
      path,
      status: error.response?.statusCode ?? 500,
      code: data?['code'] as String?,
    );
  }
  backend.fail(path);
}

T _fromJson<T>(Object? json) =>
    api.standardSerializers.deserialize(json, specifiedType: FullType(T)) as T;

/// The teams of a test (`/api/core/teams`, rosters as the players'
/// assignments, staff), then what the app did with them (ADR-0070).
class TeamsData {
  TeamsData({
    required List<api.Team> teams,
    Map<String, List<api.TeamPlayer>>? rosters,
    Map<String, List<api.TeamStaffMember>>? staff,
  }) : _teams = teams, // ignore: prefer_initializing_formals
       _rosters = rosters ?? {},
       _staff = staff ?? {};

  final List<api.Team> _teams;
  final Map<String, List<api.TeamPlayer>> _rosters;
  final Map<String, List<api.TeamStaffMember>> _staff;
  MockBackend? _backend;
  MockBackend get _b => _backend!;

  static final _api = RegExp('^/api/core/teams');
  static const _list = '/api/core/teams';

  final List<(Object, Pattern)> _pending = [];
  bool _hang = false;

  void seedInto(MockBackend backend) {
    _backend = backend;
    backend.seedTeams(_teams);
    _rosters.forEach(backend.seedRoster);
    _staff.forEach(backend.seedStaff);
    if (noServerFileName) {
      backend.dropHeaders(RegExp(r'/roster:export$'), {'content-disposition'});
    }
    if (_hang) backend.hang(_api);
    for (final (error, path) in _pending) {
      _injectInto(backend, error, path);
    }
  }

  void _fault(Object? error, Pattern path) {
    if (error == null) {
      _pending.clear();
      _backend?.heal();
      return;
    }
    _backend == null
        ? _pending.add((error, path))
        : _injectInto(_b, error, path);
  }

  List<api.Team> get teams => _backend == null
      ? _teams
      : [for (final t in _b.core.teams) _fromJson<api.Team>(t)];

  /// The rosters: before seeding the seed (mutable), afterwards the mock's,
  /// read from the players' assignments.
  Map<String, List<api.TeamPlayer>> get rosters {
    if (_backend == null) return _rosters;
    final out = <String, List<api.TeamPlayer>>{};
    for (final p in _b.core.players) {
      for (final a in (p['teams']! as List).cast<Map<String, Object?>>()) {
        final teamId = (a['team']! as Map)['id']! as String;
        (out[teamId] ??= []).add(
          api.TeamPlayer(
            (b) => b
              ..player.replace(
                api.PlayerRef(
                  (r) => r
                    ..id = p['id']! as String
                    ..displayName = p['displayName']! as String,
                ),
              )
              ..teamId = teamId
              ..jerseyNumber = a['jerseyNumber'] as String?
              ..joinedOn = api.Date(2026, 9, 1)
              ..playUpLevels = (a['playUpLevels'] as int?) ?? 0
              ..playerStatus = _fromJson<api.PlayerStatus>(p['status']),
          ),
        );
      }
    }
    return out;
  }

  Map<String, List<api.TeamStaffMember>> get staffByTeam => _backend == null
      ? _staff
      : {
          for (final e in _b.core.staff.entries)
            e.key: [for (final s in e.value) _fromJson<api.TeamStaffMember>(s)],
        };

  set hang(bool value) {
    _hang = value;
    if (value && _backend != null) _b.hang(_api);
  }

  /// Fails every team call (null: heals).
  set failWith(Object? error) => _fault(error, _api);

  /// Fails only the change of a jersey number.
  set setJerseyFailure(Object? error) =>
      _fault(error, RegExp(r'^/api/core/teams/[^/]+/players/[^/]+$'));

  /// Fails only the roster exports.
  set exportFailure(Object? error) => _fault(error, RegExp(r'/roster:export$'));

  api.CreateTeamRequest? get lastCreate {
    final sent = _b.requestsTo(_list, method: 'POST');
    return sent.isEmpty
        ? null
        : _fromJson<api.CreateTeamRequest>(MockBackend.bodyOf(sent.last));
  }

  api.UpdateTeamRequest? get lastUpdate {
    final sent = _b.requestsTo(
      RegExp(r'^/api/core/teams/[^/]+$'),
      method: 'PATCH',
    );
    return sent.isEmpty
        ? null
        : _fromJson<api.UpdateTeamRequest>(MockBackend.bodyOf(sent.last));
  }

  /// The roster exports asked for, CSV and PDF: team id and language.
  List<(String, String)> _exports(bool pdf) => [
    for (final r in _b.requestsTo(RegExp(r'/roster:export$')))
      if ('${r.headers['Accept'] ?? ''}'.contains('application/pdf') == pdf)
        (r.path.split('/')[4], '${r.headers['Accept-Language']}'),
  ];

  List<(String, String)> get rosterExports => _exports(false);

  /// The server leaves the file name out of its roster exports.
  bool noServerFileName = false;

  /// The file the mock answered the last roster export with.
  ({Uint8List bytes, Map<String, List<String>> headers}) get lastExport =>
      _b.lastFile(RegExp(r'/roster:export$'));

  /// The file name the server gave the last roster export.
  String? get lastExportName {
    final d = lastExport.headers['content-disposition']?.firstOrNull;
    return d == null ? null : RegExp('filename="([^"]+)"').firstMatch(d)?[1];
  }

  List<(String, String)> get rosterPdfs => _exports(true);

  /// The team operations the app called, by the fakes' names.
  List<String> get calls => [
    for (final r in _b.requests)
      if (_api.hasMatch(r.path)) _name(r.method.toUpperCase(), r.path),
  ];

  static String _name(String method, String path) {
    final seg = path.split('/'); // '', api, core, teams, {id}, sub, ...
    final sub = seg.length > 5 ? seg[5] : null;
    final deep = seg.length > 6;
    return switch ((method, sub, deep)) {
      ('GET', null, _) => seg.length > 4 ? 'get' : 'list',
      ('POST', null, _) => 'create',
      ('PATCH', null, _) => 'update',
      ('GET', 'players', false) => 'roster',
      ('POST', 'players', false) => 'assign',
      ('DELETE', 'players', true) => 'unassign',
      ('PATCH', 'players', true) => 'setJersey',
      ('GET', 'players', true) => 'check',
      ('GET', 'staff', _) => 'staff',
      ('PUT', 'staff', _) => 'putStaff',
      ('DELETE', 'staff', _) => 'removeStaff',
      ('GET', 'jersey-numbers', _) => 'jerseyNumbers',
      ('GET', 'roster:export', _) => 'exportRoster',
      _ => '$method $path',
    };
  }
}

/// The players of a test (`/api/core/players`), then what the app did with
/// them (ADR-0070).
class PlayersData {
  PlayersData(this._players);

  final List<api.Player> _players;
  MockBackend? _backend;
  MockBackend get _b => _backend!;

  static final _api = RegExp('^/api/core/players');
  static const _list = '/api/core/players';
  final List<Object> _pending = [];
  bool _hang = false;

  void seedInto(MockBackend backend) {
    _backend = backend;
    backend.seedPlayers(_players);
    if (_hang) backend.hang(_api);
    for (final e in _pending) {
      _injectInto(backend, e, _api);
    }
  }

  List<api.Player> get players => _backend == null
      ? _players
      : [for (final p in _b.core.players) _fromJson<api.Player>(p)];

  set hang(bool value) {
    _hang = value;
    if (value && _backend != null) _b.hang(_api);
  }

  /// Fails every player call (null: heals).
  set failWith(Object? error) {
    if (error == null) {
      _pending.clear();
      _backend?.heal();
    } else {
      _backend == null ? _pending.add(error) : _injectInto(_b, error, _api);
    }
  }

  api.CreatePlayerRequest? get lastCreate {
    final sent = _b.requestsTo(_list, method: 'POST');
    return sent.isEmpty
        ? null
        : _fromJson<api.CreatePlayerRequest>(MockBackend.bodyOf(sent.last));
  }

  /// The password of the last login the mock created with a player.
  String? get newLoginPassword {
    if (_b.requestsTo(_list, method: 'POST').isEmpty) return null;
    final a = _b.lastAnswer(_list, method: 'POST');
    return a is Map ? a['temporaryPassword'] as String? : null;
  }

  /// The player of the last withdrawal.
  String? get withdrawn {
    final sent = _b.requestsTo(RegExp(r'/withdraw$'), method: 'POST');
    return sent.isEmpty ? null : sent.last.path.split('/')[4];
  }

  /// The player and number of the last preferred-number change (null: none
  /// sent; a null number: removed).
  (String, String?)? get lastPreferred {
    final sent = _b.requestsTo(
      RegExp(r'^/api/core/players/[^/]+$'),
      method: 'PATCH',
    );
    if (sent.isEmpty) return null;
    final body = MockBackend.bodyOf(sent.last);
    return (
      sent.last.path.split('/')[4],
      body['preferredJerseyNumber'] as String?,
    );
  }

  api.PlayerStatus? get lastStatus {
    final s = _b.lastQuery(_list).text('status');
    return s == null ? null : _fromJson<api.PlayerStatus>(s);
  }

  String? get lastTeamId => _b.lastQuery(_list).text('teamId');
}
