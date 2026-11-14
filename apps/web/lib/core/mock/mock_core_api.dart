import 'dart:convert';
import 'dart:typed_data';

import 'mock_authz.dart';
import 'mock_query.dart';

/// Which demo academy a [MockCoreApi] stands for: Academia Demo (full data) or Club Norte (one team, the user is a PARENT).
enum MockAcademy { demo, norte }

/// Result of a mocked core-service call.
class MockResult {
  const MockResult.json(this.status, Object? body)
    : bytes = null,
      contentType = 'application/json',
      json = body,
      headers = const {};
  const MockResult.bytes(
    this.status,
    this.bytes,
    this.contentType, {
    this.headers = const {},
  }) : json = null;
  const MockResult.empty(this.status)
    : json = null,
      bytes = null,
      contentType = 'application/json',
      headers = const {};

  final int status;
  final Object? json;
  final Uint8List? bytes;
  final String contentType;
  final Map<String, String> headers;
}

/// In-memory stand-in for the admin / roster half of core-service, behind the
/// real generated clients (dev mock mode only, `HOOPS_MOCK_API=true`).
/// Enough behaviour to click through every WP12 flow: eligibility with
/// play-up, approvals, rollover with orphans, cases, logo upload.
class MockCoreApi {
  MockCoreApi({
    Uint8List? initialLogo,
    this.roles = const ['ADMIN', 'COACH'],
    this.academy = MockAcademy.demo,
  }) : _logo = initialLogo {
    _seed();
  }

  /// Roles of the signed-in demo user in this academy (`/me` and the mock's own authz).
  final List<String> roles;
  final MockAcademy academy;

  // ------------------------------------------------------------------ state
  Uint8List? _logo;
  int _logoVersion = 1;
  late final Map<String, Object?> _profile = {
    'slug': academy == MockAcademy.demo ? 'demo' : 'norte',
    'name': academy == MockAcademy.demo ? 'Academia Demo' : 'Club Norte',
    'timezone': 'Europe/Madrid',
    'defaultLocale': academy == MockAcademy.demo ? 'es' : 'en',
    'contactEmail': null,
    'websiteUrl': null,
  };
  final Map<String, Object?> _settings = {
    'ageRule': 'BIRTH_YEAR',
    'maxPlayUpLevels': 1,
    'attendanceLateThresholdMinutes': 10,
  };
  final List<Map<String, Object?>> _seasons = [];
  final List<Map<String, Object?>> _categories = [];
  final List<Map<String, Object?>> _teams = [];
  final List<Map<String, Object?>> _players = [];
  final List<Map<String, Object?>> _members = [];
  final List<Map<String, Object?>> _links = [];
  final List<Map<String, Object?>> _approvals = [];
  final List<Map<String, Object?>> _cases = [];
  final Map<String, List<Map<String, Object?>>> _staff = {};
  var _seq = 100;

  /// `Accept-Language` of the call being handled (the CSV exports follow it).
  String? _language;

  static const meId = '00000000-0000-4000-8000-0000000000a1';
  static const ownTeamId = 'team-mini-a';
  static const pastTeamId = 'team-mini-a-2025';
  static const norteTeamId = 'team-norte-a';

  /// The user's own player in the demo academy when the PLAYER role is on (the player record carries the login's person).
  static const demoSelfPlayerId = 'p-leo';

  /// The same in Club Norte.
  static const norteSelfPlayerId = 'p-nico';

  String get _selfPlayerId =>
      academy == MockAcademy.demo ? demoSelfPlayerId : norteSelfPlayerId;

  /// The team the demo user coaches, whose match and sessions the game and athlete mocks seed.
  String get homeTeamId =>
      academy == MockAcademy.demo ? ownTeamId : norteTeamId;

  /// The players of the academy's first team, in roster order (jersey, name).
  List<String> get homeRoster => rosterOf(homeTeamId).toList();

  String _id(String prefix) => '$prefix-${_seq++}';
  static String _now() => DateTime.now().toUtc().toIso8601String();

  static Map<String, Object?> _person(String id, String name) => {
    'personId': id,
    'displayName': name,
  };

  /// A short demo trail (newest first) for the Activity screen (WP34).
  List<Object?> _auditEvents(String tenantId) {
    final now = DateTime.now().toUtc();
    Map<String, Object?> event(
      int minutesAgo,
      String action,
      Map<String, Object?> actor,
      Map<String, Object?> target,
    ) => {
      'id':
          '00000000-0000-4000-8000-${(900 + minutesAgo).toString().padLeft(12, '0')}',
      'at': now.subtract(Duration(minutes: minutesAgo)).toIso8601String(),
      'action': action,
      'actor': actor,
      'target': target,
      'metadata': <String, Object?>{},
    };
    final me = {
      'kind': 'PERSON',
      'subject': 'demo',
      'personId': meId,
      'displayName': 'Demo Admin',
    };
    return [
      event(5, 'member.invited', me, {
        'type': 'person',
        'id': 'm-1',
        'displayName': 'Casey Coach',
      }),
      event(90, 'tenant.profile_changed', me, {
        'type': 'tenant',
        'id': tenantId,
        'displayName': _profile['name'],
      }),
      event(
        60 * 26,
        'member.temporary_password_expired',
        {'kind': 'SYSTEM', 'subject': 'system'},
        {'type': 'person', 'id': 'm-2', 'displayName': 'Pat Parent'},
      ),
      // the super admin, masked for an academy like the server does (core 2.6.0)
      event(
        60 * 50,
        'admin.added',
        {'kind': 'PLATFORM', 'subject': null},
        {'type': 'person', 'id': meId, 'displayName': 'Demo Admin'},
      ),
    ];
  }

  static Map<String, Object?> _ref(String id, String name) => {
    'id': id,
    'displayName': name,
  };

  void _seed() {
    _seasons.addAll([
      {
        'id': 'season-2025',
        'name': '2025/26',
        'startsOn': '2025-09-01',
        'endsOn': '2026-06-30',
        'referenceYear': 2025,
        'current': false,
      },
      {
        'id': 'season-2026',
        'name': '2026/27',
        'startsOn': '2026-09-01',
        'endsOn': '2027-06-30',
        'referenceYear': 2026,
        'current': true,
      },
    ]);
    _categories.addAll([
      {
        'id': 'cat-u10',
        'code': 'U10',
        'name': 'Premini',
        'maxAge': 10,
        'rank': 1,
      },
      {'id': 'cat-u12', 'code': 'U12', 'name': 'Mini', 'maxAge': 12, 'rank': 2},
      {
        'id': 'cat-u14',
        'code': 'U14',
        'name': 'Infantil',
        'maxAge': 14,
        'rank': 3,
      },
      {
        'id': 'cat-u16',
        'code': 'U16',
        'name': 'Cadete',
        'maxAge': 16,
        'rank': 4,
      },
    ]);
    Map<String, Object?> team(
      String id,
      String name,
      String? alias,
      String cat,
      String policy,
    ) => {
      'id': id,
      'seasonId': 'season-2026',
      'seasonEnded': false,
      'name': name,
      'alias': alias,
      'ageCategory': _categories.firstWhere((c) => c['id'] == cat),
      'genderPolicy': policy,
      'playerCount': 0,
    };
    final demo = academy == MockAcademy.demo;
    _teams.addAll(
      demo
          ? [
              team(ownTeamId, 'Mini A', 'Leones', 'cat-u12', 'MIXED'),
              team('team-mini-b', 'Mini B', null, 'cat-u12', 'FEMALE'),
              team('team-inf-a', 'Infantil A', 'Halcones', 'cat-u14', 'MIXED'),
              // Last season's team: ended, read-only history (ADR-0042).
              {
                ...team(pastTeamId, 'Premini A', 'Tigres', 'cat-u10', 'MIXED'),
                'seasonId': 'season-2025',
                'seasonEnded': true,
              },
            ]
          : [team(norteTeamId, 'Norte A', 'Osos', 'cat-u12', 'MIXED')],
    );
    _members.addAll([
      _member('a1', 'Casey', 'Coach', roles),
      if (demo) ...[
        _member('m-ana', 'Alicia', 'Admin', ['ADMIN']),
        _member('m-tom', 'Tomás', 'Entrenador', ['COACH']),
        _member('m-ada', 'Ada', 'Asistente', ['ASSISTANT_COACH']),
        _member('m-pat', 'Pat', 'Padre', ['PARENT']),
      ] else
        _member('m-nadia', 'Nadia', 'Admin', ['ADMIN']),
    ]);
    _staff[homeTeamId] = [
      if (demo)
        {
          'person': _person('m-tom', 'Tomás Entrenador'),
          'role': 'COACH',
          'since': '2026-09-01',
        },
      // the demo user's own staff row, so the team staff list and `/me` agree (COACH wins over ASSISTANT_COACH)
      if (roles.contains('COACH') || roles.contains('ASSISTANT_COACH'))
        {
          'person': _person('a1', 'Casey Coach'),
          'role': roles.contains('COACH') ? 'COACH' : 'ASSISTANT_COACH',
          'since': '2026-09-01',
        },
    ];
    if (demo &&
        (roles.contains('COACH') || roles.contains('ASSISTANT_COACH'))) {
      _staff[pastTeamId] = [
        {
          'person': _person('a1', 'Casey Coach'),
          'role': roles.contains('COACH') ? 'COACH' : 'ASSISTANT_COACH',
          'since': '2025-09-01',
        },
      ];
    }
    final seed = demo
        ? [
            ('p-ana', 'Ana', 'Ruiz', 2015, 'FEMALE', ownTeamId, '7'),
            ('p-leo', 'Leo', 'Gil', 2014, 'MALE', ownTeamId, '10'),
            ('p-sara', 'Sara', 'Vidal', 2015, 'FEMALE', ownTeamId, '4'),
            ('p-iker', 'Iker', 'Sanz', 2014, 'MALE', ownTeamId, '5'),
            ('p-noa', 'Noa', 'Pardo', 2015, 'FEMALE', ownTeamId, '8'),
            ('p-hugo', 'Hugo', 'Rey', 2014, 'MALE', ownTeamId, '11'),
            ('p-lia', 'Lía', 'Marín', 2015, 'FEMALE', ownTeamId, '13'),
            ('p-mia', 'Mía', 'Soto', 2016, 'FEMALE', 'team-mini-b', '4'),
            ('p-dan', 'Dani', 'López', 2013, 'MALE', 'team-inf-a', '9'),
            ('p-eva', 'Eva', 'Mar', 2012, 'FEMALE', null, null),
          ]
        : [
            ('p-nora', 'Nora', 'Vega', 2015, 'FEMALE', norteTeamId, '7'),
            ('p-nico', 'Nico', 'Ibarra', 2014, 'MALE', norteTeamId, '10'),
            ('p-nuria', 'Nuria', 'Cano', 2015, 'FEMALE', norteTeamId, '4'),
            ('p-nacho', 'Nacho', 'Prieto', 2014, 'MALE', norteTeamId, '5'),
            ('p-neus', 'Neus', 'Roca', 2015, 'FEMALE', norteTeamId, '8'),
          ];
    for (final (id, given, family, year, gender, teamId, jersey) in seed) {
      final isSelf = id == _selfPlayerId && roles.contains('PLAYER');
      _players.add({
        'id': id,
        'personId': isSelf ? 'a1' : 'person-$id',
        'givenName': given,
        'familyName': family,
        'displayName': '$given $family',
        'birthDate': '$year-04-12',
        'gender': gender,
        'status': teamId == null ? 'ORPHAN' : 'ACTIVE',
        'teams': <Object?>[],
        'createdAt': _now(),
      });
      if (teamId != null) _assign(teamId, id, jersey);
    }
    if (demo) {
      _links.add({
        'id': 'link-1',
        'guardian': _person('m-pat', 'Pat Padre'),
        'player': _ref('p-ana', 'Ana Ruiz'),
        'createdAt': _now(),
      });
    }
    if (roles.contains('PARENT')) {
      final child = demo
          ? _ref('p-ana', 'Ana Ruiz')
          : _ref('p-nora', 'Nora Vega');
      _links.add({
        'id': 'link-me',
        'guardian': _person('a1', 'Casey Coach'),
        'player': child,
        'createdAt': _now(),
      });
    }
    if (!demo) {
      _recount();
      return;
    }
    _approvals.addAll([
      _approval(
        'ap-1',
        'ADD_PLAYER',
        'PENDING',
        'p-new',
        'Lucas Mora',
        'Visto en el torneo de Navidad',
      ),
      _approval(
        'ap-2',
        'WITHDRAW_PLAYER',
        'PENDING',
        'p-leo',
        'Leo Gil',
        null,
        reason: 'Se muda de ciudad',
      ),
      _approval(
        'ap-3',
        'ADD_PLAYER',
        'APPROVED',
        'p-mia',
        'Mía Soto',
        null,
        by: _person('m-tom', 'Tomás Entrenador'),
      ),
    ]);
    _cases.add({
      'id': 'case-1',
      'player': _ref('p-eva', 'Eva Mar'),
      'team': {'id': ownTeamId, 'name': 'Mini A'},
      'reason': 'CATEGORY_TOO_LOW',
      'status': 'OPEN',
      'openedAt': _now(),
    });
    _recount();
  }

  Map<String, Object?> _member(
    String id,
    String given,
    String family,
    List<String> r,
  ) => {
    'personId': id,
    'givenName': given,
    'familyName': family,
    'displayName': '$given $family',
    'email': '${given.toLowerCase()}@demo.hoops-academy.com',
    'roles': r,
    'active': true,
    'userId': 'u-$id',
    'invitationStatus': 'ACCEPTED',
    'temporaryPasswordStatus': 'NONE',
    'createdAt': _now(),
  };

  Map<String, Object?> _approval(
    String id,
    String action,
    String status,
    String pid,
    String pname,
    String? note, {
    String? reason,
    Map<String, Object?>? by,
  }) => {
    'id': id,
    'action': action,
    'status': status,
    'player': _ref(pid, pname),
    'payload': {'note': ?note, 'reason': ?reason},
    'requestedBy': by ?? _person('a1', 'Casey Coach'),
    'requestedAt': _now(),
  };

  // ------------------------------------------------------------ roster, shared with the athlete and game mocks
  /// Ids of the players assigned to [teamId] (jersey order is the list order of the team's players).
  Set<String> rosterOf(String teamId) => {
    for (final p in _players)
      if ((p['teams']! as List).any(
        (a) => ((a as Map)['team'] as Map)['id'] == teamId,
      ))
        p['id']! as String,
  };

  Set<String> _teamsOf(String playerId) => {
    for (final p in _players.where((p) => p['id'] == playerId))
      for (final a in p['teams']! as List)
        ((a as Map)['team'] as Map)['id']! as String,
  };

  /// A player as the other mocks need it: name, birth year (the norm bands use it), gender and jersey on [teamId].
  ({String id, String name, int birthYear, String gender, String? jersey})?
  playerFacts(String id, {String? teamId}) {
    final p = _players.where((p) => p['id'] == id).firstOrNull;
    if (p == null) return null;
    final team = teamId ?? _teamsOf(id).firstOrNull;
    final jersey = team == null
        ? null
        : (p['teams']! as List)
              .cast<Map<String, Object?>>()
              .where((a) => (a['team'] as Map)['id'] == team)
              .firstOrNull?['jerseyNumber'];
    return (
      id: id,
      name: p['displayName']! as String,
      birthYear: int.parse((p['birthDate']! as String).substring(0, 4)),
      gender: p['gender']! as String,
      jersey: jersey as String?,
    );
  }

  /// Teams the demo user is staff of, of seasons that have not ended (or, with [ended], of ended ones: history).
  Set<String> _ownStaffTeams({required bool ended}) =>
      roles.contains('COACH') || roles.contains('ASSISTANT_COACH')
      ? {
          for (final e in _staff.entries)
            if (e.value.any((s) => (s['person']! as Map)['personId'] == 'a1') &&
                _teams.any(
                  (t) => t['id'] == e.key && t['seasonEnded'] == ended,
                ))
              e.key,
        }
      : <String>{};

  /// What the demo user may see here, from the roles and the live roster and links (authz matrix).
  MockAuthz get authz => MockAuthz(
    roles: roles.toSet(),
    staffTeamIds: _ownStaffTeams(ended: false),
    historicStaffTeamIds: _ownStaffTeams(ended: true),
    linkedPlayerIds: {
      for (final l in _links)
        if (roles.contains('PARENT') &&
            (l['guardian']! as Map)['personId'] == 'a1')
          (l['player']! as Map)['id']! as String,
    },
    selfPlayerIds: {
      for (final p in _players)
        if (roles.contains('PLAYER') && p['personId'] == 'a1')
          p['id']! as String,
    },
    teamsOf: _teamsOf,
    rosterOf: rosterOf,
    allTeamIds: {for (final t in _teams) t['id']! as String},
  );

  // ------------------------------------------------------------ domain logic
  Map<String, Object?> _playerById(String id) =>
      _players.firstWhere((p) => p['id'] == id);
  Map<String, Object?> _teamById(String id) =>
      _teams.firstWhere((t) => t['id'] == id);

  Map<String, Object?>? _naturalCategory(Map<String, Object?> p) {
    final age = 2026 - int.parse((p['birthDate']! as String).substring(0, 4));
    for (final c in _categories) {
      final max = c['maxAge'] as int?;
      if (max == null || age <= max) return c;
    }
    return null;
  }

  Map<String, Object?> _check(String teamId, String playerId) {
    final p = _playerById(playerId);
    final t = _teamById(teamId);
    final natural = _naturalCategory(p);
    final teamRank = (t['ageCategory']! as Map)['rank'] as int;
    final levels = natural == null ? 0 : teamRank - (natural['rank']! as int);
    final reasons = <String>[];
    var result = 'ELIGIBLE';
    if (p['status'] == 'WITHDRAWN' || p['status'] == 'PENDING_APPROVAL') {
      reasons.add('PLAYER_NOT_ACTIVE');
    }
    if (natural == null || levels < 0) reasons.add('CATEGORY_TOO_LOW');
    if (levels > (_settings['maxPlayUpLevels']! as int))
      reasons.add('PLAY_UP_LIMIT_EXCEEDED');
    final policy = t['genderPolicy'];
    if (policy != 'MIXED' && policy != p['gender'])
      reasons.add('GENDER_POLICY');
    if (reasons.isNotEmpty) {
      result = 'INELIGIBLE';
    } else if (levels > 0) {
      result = 'PLAY_UP';
    }
    return {
      'playerId': playerId,
      'teamId': teamId,
      'asOf': DateTime.now().toIso8601String().substring(0, 10),
      'result': result,
      'playUpLevels': levels < 0 ? 0 : levels,
      'reasons': reasons,
      'age': 2026 - int.parse((p['birthDate']! as String).substring(0, 4)),
      'naturalCategory': ?natural,
    };
  }

  /// The numbers taken in [teamId] (open assignments), by value then length, with their players.
  List<Map<String, Object?>> _takenNumbers(String teamId) {
    final taken = <Map<String, Object?>>[
      for (final p in _players)
        for (final a in (p['teams']! as List).cast<Map<String, Object?>>())
          if ((a['team'] as Map)['id'] == teamId && a['jerseyNumber'] != null)
            {
              'jerseyNumber': a['jerseyNumber'],
              'player': _ref(p['id']! as String, p['displayName']! as String),
            },
    ];
    taken.sort((a, b) {
      final x = a['jerseyNumber']! as String;
      final y = b['jerseyNumber']! as String;
      final byValue = int.parse(x).compareTo(int.parse(y));
      return byValue != 0 ? byValue : x.length.compareTo(y.length);
    });
    return taken;
  }

  /// `POST /teams/{id}/players`: requested number (taken: 409), else the preferred one, else the number the player
  /// had in another team, each only when free; otherwise none (core 3.5.0 `jerseySource`).
  MockResult _assignWithRule(
    String teamId,
    String playerId,
    String? requested,
  ) {
    final p = _playerById(playerId);
    final taken = {
      for (final t in _takenNumbers(teamId))
        if ((t['player']! as Map)['id'] != playerId) t['jerseyNumber'],
    };
    if (requested != null && taken.contains(requested)) {
      return const MockResult.json(409, {
        'type': 'urn:hoops:problem:mock',
        'title': 'Jersey number taken',
        'status': 409,
        'code': 'TEAM_PLAYER_CONFLICT',
      });
    }
    final preferred = p['preferredJerseyNumber'] as String?;
    final previous = [
      for (final a in (p['teams']! as List).cast<Map<String, Object?>>())
        if ((a['team'] as Map)['id'] != teamId && a['jerseyNumber'] != null)
          a['jerseyNumber']! as String,
    ].lastOrNull;
    final (number, source) = switch ((requested, preferred, previous)) {
      (final String r, _, _) => (r, 'REQUESTED'),
      (_, final String f, _) when !taken.contains(f) => (f, 'PREFERRED'),
      (_, _, final String v) when !taken.contains(v) => (v, 'PREVIOUS'),
      _ => (null, 'NONE'),
    };
    return MockResult.json(201, {
      ..._assign(teamId, playerId, number),
      'jerseySource': source,
    });
  }

  /// `PATCH /players/{id}`: the preferred number (`^[0-9]{1,2}$`), by an admin, a coach, a linked parent or the
  /// player; an assistant coach is refused.
  MockResult _updatePlayer(Map<String, Object?> p, Map<String, Object?> b) {
    final id = p['id']! as String;
    final may =
        authz.admin ||
        roles.contains('COACH') ||
        authz.linkedPlayerIds.contains(id) ||
        authz.selfPlayerIds.contains(id);
    if (!may) return _forbidden;
    final number = b['preferredJerseyNumber'];
    if (number != null && !RegExp(r'^[0-9]{1,2}$').hasMatch('$number')) {
      return mockProblem(400, 'Bad Request');
    }
    final error = mockApplyUpdate(
      p,
      b,
      clearable: const {'preferredJerseyNumber'},
    );
    if (error != null) return error;
    if (p['preferredJerseyNumber'] == null) p.remove('preferredJerseyNumber');
    return MockResult.json(200, _playerJson(p));
  }

  // ------------------------------------------------------------ CSV exports (core 3.5.0)
  static const _bom = '\u{feff}';

  MockResult _csv(String name, List<List<String>> rows) {
    String cell(String v) =>
        v.contains(RegExp('[",\r\n]')) ? '"${v.replaceAll('"', '""')}"' : v;
    final text = _bom + rows.map((r) => r.map(cell).join(',')).join('\r\n');
    final day = DateTime.now()
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '');
    return MockResult.bytes(
      200,
      Uint8List.fromList(utf8.encode('$text\r\n')),
      'text/csv; charset=utf-8',
      headers: {
        'content-disposition':
            'attachment; filename="hoops-demo-$name-$day.csv"',
        'cache-control': 'no-store',
      },
    );
  }

  String get _lang {
    final l = (_language ?? 'en').toLowerCase();
    return l.startsWith('es') ? 'es' : (l.startsWith('id') ? 'id' : 'en');
  }

  MockResult _exportRoster(String teamId) {
    final team = _teams.where((t) => t['id'] == teamId).firstOrNull;
    if (team == null) return _notFound;
    // Current staff only: a former coach of an ended season gets 403 (core 3.6.0).
    final coachOfTeam =
        roles.contains('COACH') && authz.staffTeamIds.contains(teamId);
    if (!authz.admin && !coachOfTeam) return _forbidden;
    final header = switch (_lang) {
      'es' => ['Rol', 'Nombre', 'Apellidos', 'Dorsal'],
      'id' => ['Peran', 'Nama depan', 'Nama belakang', 'Nomor'],
      _ => ['Role', 'Given name', 'Family name', 'Jersey'],
    };
    final rows = [
      for (final p in _players)
        for (final a in (p['teams']! as List).cast<Map<String, Object?>>())
          if ((a['team'] as Map)['id'] == teamId)
            [
              'PLAYER',
              p['givenName']! as String,
              p['familyName']! as String,
              '${a['jerseyNumber'] ?? ''}',
            ],
    ];
    final slug = (team['name']! as String).toLowerCase().replaceAll(' ', '-');
    return _csv('roster-$slug', [header, ...rows]);
  }

  MockResult _exportAudit(String tenantId) {
    final header = switch (_lang) {
      'es' => ['Fecha', 'Acción', 'Autor', 'Objetivo'],
      'id' => ['Waktu', 'Tindakan', 'Pelaku', 'Sasaran'],
      _ => ['When', 'Action', 'Actor', 'Target'],
    };
    final rows = [
      for (final e in _auditEvents(tenantId).cast<Map<String, Object?>>())
        [
          e['at']! as String,
          e['action']! as String,
          '${(e['actor']! as Map)['displayName'] ?? ''}',
          '${(e['target']! as Map)['displayName'] ?? ''}',
        ],
    ];
    return _csv('audit', [header, ...rows]);
  }

  Map<String, Object?> _assign(String teamId, String playerId, String? jersey) {
    final p = _playerById(playerId);
    final t = _teamById(teamId);
    final check = _check(teamId, playerId);
    (p['teams']! as List).removeWhere(
      (a) => ((a as Map)['team'] as Map)['id'] == teamId,
    );
    (p['teams']! as List).add({
      'team': {'id': teamId, 'name': t['name']},
      'jerseyNumber': jersey,
      'playUpLevels': check['playUpLevels'],
      'valid': true,
    });
    if (p['status'] == 'ORPHAN') p['status'] = 'ACTIVE';
    _recount();
    return _teamPlayer(teamId, playerId);
  }

  Map<String, Object?> _teamPlayer(String teamId, String playerId) {
    final p = _playerById(playerId);
    final a = (p['teams']! as List).cast<Map<String, Object?>>().firstWhere(
      (a) => (a['team'] as Map)['id'] == teamId,
    );
    return {
      'player': _ref(playerId, p['displayName']! as String),
      'teamId': teamId,
      'jerseyNumber': a['jerseyNumber'],
      'joinedOn': '2026-09-01',
      'playUpLevels': a['playUpLevels'],
      'playerStatus': p['status'],
      if (a['valid'] == false) 'invalidatedAt': _now(),
    };
  }

  void _recount() {
    for (final t in _teams) {
      t['playerCount'] = _players
          .where(
            (p) => (p['teams']! as List).any(
              (a) => ((a as Map)['team'] as Map)['id'] == t['id'],
            ),
          )
          .length;
    }
  }

  Map<String, Object?> _playerJson(Map<String, Object?> p) => {
    ...p,
    'naturalCategory': ?_naturalCategory(p),
  };

  static Map<String, Object?> _page(List<Object?> items) => {
    'items': items,
    'page': {
      'page': 0,
      'size': 100,
      'totalElements': items.length,
      'totalPages': 1,
    },
  };

  Map<String, Object?> _profileJson(String tenantId) => {
    'id': tenantId,
    ..._profile,
    'hasLogo': _logo != null,
    if (_logo != null) 'logoEtag': '"v$_logoVersion"',
  };

  // ----------------------------------------------------------------- routing
  /// Returns null when [path] is not a core-service path this mock serves.
  MockResult? handle({
    required String tenantId,
    required String method,
    required String path,
    required Map<String, dynamic> query,
    Object? body,
    Uint8List? bytes,
    String? language,
  }) {
    _language = language;
    final seg = path
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList(); // api, core, ...
    if (seg.length < 3 || seg[0] != 'api' || seg[1] != 'core') return null;
    final res = seg[2];
    final id = seg.length > 3 ? seg[3] : null;
    final sub = seg.length > 4 ? seg[4] : null;
    final b = body is Map ? body.cast<String, Object?>() : <String, Object?>{};
    bool is_(String m) => method == m;

    final denied = _guard(res, method, id, sub);
    if (denied != null) return denied;

    switch (res) {
      case 'me':
        if (id == null && is_('PATCH')) return _renameSelf(b);
      case 'tenant':
        if (id == null) {
          if (is_('GET')) return MockResult.json(200, _profileJson(tenantId));
          if (is_('PATCH')) {
            return mockApplyUpdate(
                  _profile,
                  b,
                  clearable: const {'contactEmail', 'websiteUrl'},
                ) ??
                MockResult.json(200, _profileJson(tenantId));
          }
        }
        if (id == 'settings') {
          if (is_('PUT')) _settings.addAll(b);
          return MockResult.json(200, _settings);
        }
        if (id == 'logo') {
          if (is_('GET')) {
            return _logo == null
                ? const MockResult.json(404, {
                    'title': 'No logo',
                    'status': 404,
                  })
                : MockResult.bytes(
                    200,
                    _logo,
                    'image/png',
                    headers: {
                      'etag': '"v$_logoVersion"',
                      'cache-control': 'private, max-age=0, must-revalidate',
                    },
                  );
          }
          if (is_('PUT')) {
            _logo = bytes;
            _logoVersion++;
            return MockResult.json(200, {
              'contentType': 'image/png',
              'sizeBytes': bytes?.length ?? 1,
              'etag': '"v$_logoVersion"',
              'updatedAt': _now(),
            });
          }
          if (is_('DELETE')) {
            if (_logo == null)
              return const MockResult.json(404, {
                'title': 'No logo',
                'status': 404,
              });
            _logo = null;
            _logoVersion++;
            return const MockResult.empty(204);
          }
        }
      case 'seasons':
        if (id == null && is_('GET')) return MockResult.json(200, _seasons);
        if (id == null && is_('POST')) {
          final s = {'id': _id('season'), 'current': false, ...b};
          _seasons.add(s);
          return MockResult.json(201, s);
        }
        if (id != null && sub == null && is_('PATCH')) {
          final s = _seasons.firstWhere((s) => s['id'] == id);
          s.addAll(b);
          return MockResult.json(200, s);
        }
        if (id != null && sub == 'rollover' && is_('POST'))
          return MockResult.json(200, _rollover(id));
      case 'age-categories':
        if (id == null && is_('GET')) return MockResult.json(200, _categories);
        if (id == null && is_('POST')) {
          final c = {'id': _id('cat'), ...b};
          _categories.add(c);
          return MockResult.json(201, c);
        }
        if (id != null && is_('PATCH')) {
          final c = _categories.firstWhere((c) => c['id'] == id);
          return mockApplyUpdate(c, b, clearable: const {'maxAge'}) ??
              MockResult.json(200, c);
        }
        if (id != null && is_('DELETE')) {
          if (_teams.any((t) => (t['ageCategory']! as Map)['id'] == id)) {
            return const MockResult.json(409, {
              'title': 'Category in use',
              'status': 409,
            });
          }
          _categories.removeWhere((c) => c['id'] == id);
          return const MockResult.empty(204);
        }
      case 'members':
        return _members_(method, id, sub, query, b);
      case 'guardian-links':
        if (id == null && is_('GET')) {
          return MockResult.json(
            200,
            _page([
              for (final l in _links)
                if ((query['playerId'] == null ||
                        (l['player']! as Map)['id'] == query['playerId']) &&
                    (query['guardianPersonId'] == null ||
                        (l['guardian']! as Map)['personId'] ==
                            query['guardianPersonId']) &&
                    (authz.admin ||
                        (l['guardian']! as Map)['personId'] == 'a1'))
                  l,
            ]),
          );
        }
        if (id == null && is_('POST')) {
          final m = _members.firstWhere(
            (m) => m['personId'] == b['guardianPersonId'],
          );
          final p = _playerById(b['playerId']! as String);
          final l = {
            'id': _id('link'),
            'guardian': _person(
              m['personId']! as String,
              m['displayName']! as String,
            ),
            'player': _ref(p['id']! as String, p['displayName']! as String),
            'createdAt': _now(),
          };
          _links.add(l);
          return MockResult.json(201, l);
        }
        if (id != null && is_('DELETE')) {
          _links.removeWhere((l) => l['id'] == id);
          return const MockResult.empty(204);
        }
      case 'guardians':
        if (id == null && is_('POST')) return _addGuardian(b);
      case 'teams':
        return _teams_(method, id, sub, seg, query, b);
      case 'players':
        return _players_(method, id, sub, query, b);
      case 'approval-requests':
        return _approvals_(method, id, sub, query, b);
      case 'audit-events:export':
        if (id == null && is_('GET')) return _exportAudit(tenantId);
      case 'audit-events':
        if (id == null && is_('GET'))
          return MockResult.json(200, _page(_auditEvents(tenantId)));
      case 'eligibility-cases':
        if (id == null && is_('GET')) {
          return MockResult.json(
            200,
            _page([
              for (final c in _cases)
                if (_mayReadCase(c) &&
                    (query['status'] == null || c['status'] == query['status']))
                  c,
            ]),
          );
        }
        if (id != null && sub == 'resolve' && is_('POST')) {
          final c = _cases.where((c) => c['id'] == id).firstOrNull;
          if (c == null || !_mayReadCase(c)) return _notFound;
          if (b['resolution'] == 'REASSIGNED') {
            _assignWithRule(
              b['targetTeamId']! as String,
              (c['player']! as Map)['id']! as String,
              null,
            );
          }
          if (b['resolution'] == 'REMOVED_FROM_TEAM') {
            final p = _playerById((c['player']! as Map)['id']! as String);
            (p['teams']! as List).clear();
            p['status'] = 'ORPHAN';
            _recount();
          }
          c['status'] = 'RESOLVED';
          c['resolution'] = b['resolution'];
          c['resolvedAt'] = _now();
          return MockResult.json(200, c);
        }
    }
    return const MockResult.json(404, {'title': 'Not found', 'status': 404});
  }

  static const _notFound = MockResult.json(404, {
    'title': 'Not found',
    'status': 404,
  });

  /// A coach reads the approval requests he asked for; the admin all of them.
  bool _mayReadApproval(Map<String, Object?> a) =>
      authz.admin || (a['requestedBy']! as Map)['personId'] == 'a1';

  /// A coach reads the eligibility cases of his teams; the admin all of them.
  bool _mayReadCase(Map<String, Object?> c) =>
      authz.admin || authz.staffTeamIds.contains((c['team']! as Map)['id']);

  static const _forbidden = MockResult.json(403, {
    'title': 'Forbidden',
    'status': 403,
    'type': 'urn:hoops:problem:mock',
  });

  /// The role rules of `docs/domain/authz-matrix.md` for the admin / roster half: 403 for a member who may not.
  MockResult? _guard(String res, String method, String? id, String? sub) {
    final a = authz;
    if (a.admin) return null;
    final write = method != 'GET';
    final allowed = switch (res) {
      'tenant' || 'seasons' || 'age-categories' => !write,
      'guardian-links' => !write && a.roles.contains('PARENT'),
      'members' ||
      'guardians' ||
      'audit-events' ||
      'audit-events:export' => false,
      'approval-requests' => a.staff && !write,
      'eligibility-cases' => a.coachRole,
      'teams' =>
        !write || (sub == 'players' && id != null && a.canManageTeam(id)),
      // the preferred number is also written by a linked parent and the player himself (checked in `_players_`)
      'players' => !write || a.coachRole || (method == 'PATCH' && sub == null),
      _ => true,
    };
    return allowed ? null : _forbidden;
  }

  /// The demo user's own name in this academy (what `/me` reports as `displayName`).
  String get selfName =>
      _members.firstWhere((m) => m['personId'] == 'a1')['displayName']!
          as String;

  /// The demo user's own given and family name in this academy (`/me` memberships, core 3.6.0).
  ({String given, String family}) get selfNames {
    final me = _members.firstWhere((m) => m['personId'] == 'a1');
    return (
      given: me['givenName']! as String,
      family: me['familyName']! as String,
    );
  }

  /// `PATCH /api/core/me` with a name (core 3.4.0): the caller's own person gets the new first / last name; the
  /// member list shows it afterwards.
  MockResult _renameSelf(Map<String, Object?> b) {
    final me = _members.firstWhere((m) => m['personId'] == 'a1');
    for (final key in const ['givenName', 'familyName']) {
      final value = b[key];
      if (value is String) me[key] = value;
    }
    me['displayName'] = '${me['givenName']} ${me['familyName']}';
    for (final staff in _staff.values) {
      for (final row in staff) {
        final person = row['person']! as Map<String, Object?>;
        if (person['personId'] == 'a1')
          person['displayName'] = me['displayName'];
      }
    }
    return const MockResult.empty(204);
  }

  Map<String, Object?> _rollover(String fromId) {
    final next = {
      'id': _id('season'),
      'name': 'Temporada siguiente',
      'startsOn': '2027-09-01',
      'endsOn': '2028-06-30',
      'referenceYear': 2027,
      'current': false,
    };
    _seasons.add(next);
    final cloned = <Object?>[];
    final orphans = <Object?>[];
    final opened = <Object?>[];
    for (final t in _teams.where((t) => t['seasonId'] == fromId).toList()) {
      final copy = {
        ...t,
        'id': _id('team'),
        'seasonId': next['id'],
        'seasonEnded': false,
        'playerCount': 0,
      };
      _teams.add(copy);
      cloned.add({'id': copy['id'], 'name': copy['name']});
    }
    // With the 2027 reference year the oldest players of a team outgrow it.
    for (final p in _players.where((p) => p['status'] == 'ACTIVE')) {
      final age = 2027 - int.parse((p['birthDate']! as String).substring(0, 4));
      for (final a in (p['teams']! as List).cast<Map<String, Object?>>()) {
        final t = _teamById((a['team'] as Map)['id'] as String);
        if (age > ((t['ageCategory']! as Map)['maxAge'] as int)) {
          orphans.add({
            'player': _ref(p['id']! as String, p['displayName']! as String),
            'previousTeam': {'id': t['id'], 'name': t['name']},
            'reasons': ['CATEGORY_TOO_LOW'],
          });
          final caseId = _id('case');
          opened.add(caseId);
          _cases.add({
            'id': caseId,
            'player': _ref(p['id']! as String, p['displayName']! as String),
            'team': {'id': t['id'], 'name': t['name']},
            'reason': 'CATEGORY_TOO_LOW',
            'status': 'OPEN',
            'openedAt': _now(),
          });
        }
      }
    }
    return {
      'fromSeasonId': fromId,
      'toSeasonId': next['id'],
      'clonedTeams': cloned,
      'orphans': orphans,
      'openedCaseIds': opened,
    };
  }

  MockResult? _members_(
    String method,
    String? id,
    String? sub,
    Map<String, dynamic> q,
    Map<String, Object?> b,
  ) {
    if (id == null && method == 'GET') {
      final text = (q['q'] as String?)?.toLowerCase();
      return MockResult.json(
        200,
        _page([
          for (final m in _members)
            if ((text == null ||
                    (m['displayName']! as String).toLowerCase().contains(
                      text,
                    ) ||
                    ((m['email'] as String?) ?? '').toLowerCase().contains(
                      text,
                    )) &&
                (q['active'] == null || '${m['active']}' == '${q['active']}') &&
                (q['role'] == null ||
                    (m['roles']! as List).contains(q['role'])))
              m,
        ]),
      );
    }
    if (id == null && method == 'POST') {
      final m =
          _member(
              _id('m'),
              b['givenName']! as String,
              b['familyName']! as String,
              (b['roles']! as List).cast<String>(),
            )
            ..['email'] = b['email']
            ..['invitationStatus'] = 'PENDING'
            ..['temporaryPasswordStatus'] = 'ACTIVE';
      _members.add(m);
      return MockResult.json(201, {...m, 'temporaryPassword': _mockPassword()});
    }
    final m = _members.where((m) => m['personId'] == id).firstOrNull;
    if (m == null)
      return const MockResult.json(404, {'title': 'Not found', 'status': 404});
    if (sub == null && method == 'GET') return MockResult.json(200, m);
    if (sub == null && method == 'PATCH') {
      // A member with a login (userId) cannot lose the e-mail (ADR-0023).
      if (m['userId'] != null && mockClear(b).contains('email')) {
        return mockProblem(422, 'Unprocessable', code: 'LOGIN_REQUIRES_EMAIL');
      }
      final error = mockApplyUpdate(
        m,
        b,
        clearable: const {'email', 'phone', 'birthDate', 'gender'},
      );
      if (error != null) return error;
      m['displayName'] = '${m['givenName']} ${m['familyName']}';
      return MockResult.json(200, m);
    }
    if (sub == 'roles' && method == 'PUT') {
      m['roles'] = b['roles'];
      return MockResult.json(200, m);
    }
    if (sub == 'deactivate' && method == 'POST') {
      m['active'] = false;
      return MockResult.json(200, m);
    }
    if (sub == 'temporary-password' && method == 'POST') {
      final firstGuardianLogin =
          m['userId'] == null &&
          m['email'] != null &&
          (m['roles']! as List).contains('PARENT');
      if (firstGuardianLogin) {
        m
          ..['userId'] = 'u-${m['personId']}'
          ..['invitationStatus'] = 'PENDING';
      }
      if (m['invitationStatus'] != 'PENDING') {
        return const MockResult.json(409, {
          'title': 'Conflict',
          'status': 409,
          'code': 'INVITATION_NOT_PENDING',
        });
      }
      m['temporaryPasswordStatus'] = 'ACTIVE';
      return MockResult.json(200, {...m, 'temporaryPassword': _mockPassword()});
    }
    return null;
  }

  /// `POST /api/core/guardians`: a PARENT member linked to the player; a login (shown once) with an e-mail.
  MockResult _addGuardian(Map<String, Object?> b) {
    final email = b['email'] as String?;
    final m =
        _member(
            _id('m'),
            b['givenName']! as String,
            b['familyName']! as String,
            const ['PARENT'],
          )
          ..['email'] = email
          ..['userId'] = email == null ? null : 'u-${_id('login')}'
          ..['invitationStatus'] = email == null ? 'NONE' : 'PENDING'
          ..['temporaryPasswordStatus'] = email == null ? 'NONE' : 'ACTIVE';
    _members.add(m);
    final p = _playerById(b['playerId']! as String);
    final l = {
      'id': _id('link'),
      'guardian': _person(
        m['personId']! as String,
        m['displayName']! as String,
      ),
      'player': _ref(p['id']! as String, p['displayName']! as String),
      'createdAt': _now(),
    };
    _links.add(l);
    return MockResult.json(201, {
      ...l,
      if (email != null) 'temporaryPassword': _mockPassword(),
    });
  }

  int _passwordCount = 0;

  /// Demo stand-in for the server-generated temporary password (12+ characters, different every time).
  String _mockPassword() => 'demo-temp-pass-${++_passwordCount}';

  MockResult? _teams_(
    String method,
    String? id,
    String? sub,
    List<String> seg,
    Map<String, dynamic> q,
    Map<String, Object?> b,
  ) {
    if (id == null && method == 'GET') {
      return MockResult.json(
        200,
        _page([
          for (final t in _teams)
            if (authz.canSeeTeam(t['id']! as String) &&
                (q['staffedByMe'] != true ||
                    authz.staffTeamIds.contains(t['id']) ||
                    (q['includeEnded'] == true &&
                        authz.historicStaffTeamIds.contains(t['id']))) &&
                (q['seasonId'] == null || t['seasonId'] == q['seasonId']) &&
                (q['ageCategoryId'] == null ||
                    (t['ageCategory']! as Map)['id'] == q['ageCategoryId']))
              t,
        ]),
      );
    }
    if (id == null && method == 'POST') {
      final cat = _categories.firstWhere((c) => c['id'] == b['ageCategoryId']);
      final t = {
        'id': _id('team'),
        'seasonId': b['seasonId'],
        'seasonEnded': false,
        'name': b['name'],
        'alias': b['alias'],
        'ageCategory': cat,
        'genderPolicy': b['genderPolicy'],
        'playerCount': 0,
      };
      _teams.add(t);
      return MockResult.json(201, t);
    }
    final t = _teams.where((t) => t['id'] == id).firstOrNull;
    // the roster export answers 403, not 404, to a member who may not export this team
    if (t == null ||
        (method == 'GET' && sub != 'roster:export' && !authz.canSeeTeam(id!)))
      return _notFound;
    if (sub == null && method == 'GET') return MockResult.json(200, t);
    if (sub == null && method == 'PATCH') {
      final error = mockApplyUpdate(
        t,
        {...b}..remove('ageCategoryId'),
        clearable: const {'alias'},
      );
      if (error != null) return error;
      if (b['ageCategoryId'] != null)
        t['ageCategory'] = _categories.firstWhere(
          (c) => c['id'] == b['ageCategoryId'],
        );
      return MockResult.json(200, t);
    }
    if (sub == 'staff') {
      final list = _staff.putIfAbsent(id!, () => []);
      final personId = seg.length > 5 ? seg[5] : null;
      if (personId == null && method == 'GET')
        return MockResult.json(200, list);
      if (personId != null && method == 'PUT') {
        final m = _members.firstWhere((m) => m['personId'] == personId);
        list.removeWhere((s) => (s['person']! as Map)['personId'] == personId);
        final s = {
          'person': _person(personId, m['displayName']! as String),
          'role': b['role'],
          'since': '2026-09-01',
        };
        list.add(s);
        return MockResult.json(200, s);
      }
      if (personId != null && method == 'DELETE') {
        list.removeWhere((s) => (s['person']! as Map)['personId'] == personId);
        return const MockResult.empty(204);
      }
    }
    if (sub == 'jersey-numbers' && method == 'GET') {
      return MockResult.json(200, _takenNumbers(id!));
    }
    if (sub == 'roster:export' && method == 'GET') return _exportRoster(id!);
    if (sub == 'players') {
      final playerId = seg.length > 5 ? seg[5] : null;
      final tail = seg.length > 6 ? seg[6] : null;
      if (playerId == null && method == 'GET') {
        return MockResult.json(200, [
          for (final p in _players)
            if ((p['teams']! as List).any(
                  (a) => ((a as Map)['team'] as Map)['id'] == id,
                ) &&
                (authz.canManageTeam(id!) ||
                    authz.coachRole ||
                    authz.canSeePlayer(p['id']! as String)))
              _teamPlayer(id, p['id']! as String),
        ]);
      }
      if (playerId == null && method == 'POST') {
        final pid = b['playerId']! as String;
        if (_check(id!, pid)['result'] == 'INELIGIBLE') {
          return const MockResult.json(422, {
            'title': 'Player is not eligible',
            'status': 422,
            'code': 'PLAYER_INELIGIBLE',
          });
        }
        return _assignWithRule(id, pid, b['jerseyNumber'] as String?);
      }
      if (playerId != null && tail == 'eligibility' && method == 'GET') {
        if (!authz.canSeePlayer(playerId)) return _notFound;
        return MockResult.json(200, _check(id!, playerId));
      }
      if (playerId != null && method == 'DELETE') {
        final p = _playerById(playerId);
        (p['teams']! as List).removeWhere(
          (a) => ((a as Map)['team'] as Map)['id'] == id,
        );
        if ((p['teams']! as List).isEmpty && p['status'] == 'ACTIVE')
          p['status'] = 'ORPHAN';
        _recount();
        return const MockResult.empty(204);
      }
      if (playerId != null && method == 'PATCH') {
        final p = _playerById(playerId);
        for (final a in (p['teams']! as List).cast<Map<String, Object?>>()) {
          if ((a['team'] as Map)['id'] != id) continue;
          final error = mockApplyUpdate(
            a,
            b,
            clearable: const {'jerseyNumber'},
          );
          if (error != null) return error;
        }
        return MockResult.json(200, _teamPlayer(id!, playerId));
      }
    }
    return null;
  }

  MockResult? _players_(
    String method,
    String? id,
    String? sub,
    Map<String, dynamic> q,
    Map<String, Object?> b,
  ) {
    if (id == null && method == 'GET') {
      final text = (q['q'] as String?)?.toLowerCase();
      return MockResult.json(
        200,
        _page([
          for (final p in _players)
            if (authz.canSeePlayer(p['id']! as String) &&
                (q['status'] == null || p['status'] == q['status']) &&
                (q['teamId'] == null ||
                    (p['teams']! as List).any(
                      (a) => ((a as Map)['team'] as Map)['id'] == q['teamId'],
                    )) &&
                (text == null ||
                    (p['displayName']! as String).toLowerCase().contains(text)))
              _playerJson(p),
        ]),
      );
    }
    if (id == null && method == 'POST') {
      final admin = roles.contains('ADMIN');
      final pid = _id('p');
      final p = {
        'id': pid,
        'personId': 'person-$pid',
        'givenName': b['givenName'],
        'familyName': b['familyName'],
        'displayName': '${b['givenName']} ${b['familyName']}',
        'birthDate': b['birthDate'],
        'gender': b['gender'],
        'status': admin ? 'ORPHAN' : 'PENDING_APPROVAL',
        'teams': <Object?>[],
        'createdAt': _now(),
      };
      _players.add(p);
      if (admin && b['teamId'] != null)
        _assign(b['teamId']! as String, pid, b['jerseyNumber'] as String?);
      final a = _approval(
        _id('ap'),
        'ADD_PLAYER',
        admin ? 'APPROVED' : 'PENDING',
        pid,
        p['displayName']! as String,
        b['note'] as String?,
      );
      _approvals.add(a);
      return MockResult.json(admin ? 201 : 202, {
        'player': _playerJson(p),
        'approvalRequest': a,
      });
    }
    final p = _players.where((p) => p['id'] == id).firstOrNull;
    if (p == null || !authz.canSeePlayer(id!)) return _notFound;
    if (sub == null && method == 'GET')
      return MockResult.json(200, _playerJson(p));
    if (sub == null && method == 'PATCH') return _updatePlayer(p, b);
    if (sub == 'eligible-teams' && method == 'GET') {
      return MockResult.json(200, [
        for (final t in _teams)
          if (t['seasonId'] == (q['seasonId'] ?? 'season-2026'))
            {'team': t, 'eligibility': _check(t['id']! as String, id)},
      ]);
    }
    if (sub == 'withdraw' && method == 'POST') {
      final admin = roles.contains('ADMIN');
      if (admin) {
        p['status'] = 'WITHDRAWN';
        (p['teams']! as List).clear();
        _recount();
      }
      final a = _approval(
        _id('ap'),
        'WITHDRAW_PLAYER',
        admin ? 'APPROVED' : 'PENDING',
        id,
        p['displayName']! as String,
        null,
        reason: b['reason'] as String?,
      );
      _approvals.add(a);
      return MockResult.json(admin ? 200 : 202, {
        'player': _playerJson(p),
        'approvalRequest': a,
      });
    }
    return null;
  }

  MockResult? _approvals_(
    String method,
    String? id,
    String? sub,
    Map<String, dynamic> q,
    Map<String, Object?> b,
  ) {
    if (id == null && method == 'GET') {
      return MockResult.json(
        200,
        _page([
          for (final a in _approvals)
            if (_mayReadApproval(a) &&
                (q['status'] == null || a['status'] == q['status']))
              a,
        ]),
      );
    }
    final a = _approvals.where((a) => a['id'] == id).firstOrNull;
    if (a == null || !_mayReadApproval(a)) return _notFound;
    if (sub == null && method == 'GET') return MockResult.json(200, a);
    if (a['status'] != 'PENDING')
      return const MockResult.json(409, {
        'title': 'Already decided',
        'status': 409,
      });
    final pid = (a['player']! as Map)['id'] as String;
    switch (sub) {
      case 'approve':
        a['status'] = 'APPROVED';
        a['decisionNote'] = b['note'];
        final p = _players.where((p) => p['id'] == pid).firstOrNull;
        if (p != null &&
            a['action'] == 'ADD_PLAYER' &&
            p['status'] == 'PENDING_APPROVAL')
          p['status'] = 'ORPHAN';
        if (p != null && a['action'] == 'WITHDRAW_PLAYER') {
          p['status'] = 'WITHDRAWN';
          (p['teams']! as List).clear();
          _recount();
        }
      case 'reject':
        a['status'] = 'REJECTED';
        a['decisionNote'] = b['note'];
      case 'cancel':
        a['status'] = 'CANCELLED';
      default:
        return null;
    }
    a['decidedBy'] = _person('a1', 'Casey Coach');
    a['decidedAt'] = _now();
    return MockResult.json(200, a);
  }

  /// Convenience for the adapter: JSON bytes of [r].
  static Uint8List encode(MockResult r) =>
      r.bytes ?? Uint8List.fromList(utf8.encode(jsonEncode(r.json ?? {})));
}
