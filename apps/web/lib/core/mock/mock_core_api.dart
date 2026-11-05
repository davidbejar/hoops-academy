import 'dart:convert';
import 'dart:typed_data';

/// Result of a mocked core-service call.
class MockResult {
  const MockResult.json(this.status, Object? body)
    : bytes = null,
      contentType = 'application/json',
      json = body,
      headers = const {};
  const MockResult.bytes(this.status, this.bytes, this.contentType, {this.headers = const {}}) : json = null;
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
  MockCoreApi({required Uint8List initialLogo, this.roles = const ['ADMIN', 'COACH']}) : _logo = initialLogo {
    _seed();
  }

  /// Roles of the signed-in demo user (`/me` and the mock's own authz).
  final List<String> roles;

  // ------------------------------------------------------------------ state
  Uint8List? _logo;
  int _logoVersion = 1;
  final Map<String, Object?> _profile = {
    'slug': 'demo',
    'name': 'Academia Demo',
    'timezone': 'Europe/Madrid',
    'defaultLocale': 'es',
    'contactEmail': null,
    'websiteUrl': null,
  };
  final Map<String, Object?> _settings = {'ageRule': 'BIRTH_YEAR', 'maxPlayUpLevels': 1, 'attendanceLateThresholdMinutes': 10};
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

  static const meId = '00000000-0000-4000-8000-0000000000a1';
  static const ownTeamId = 'team-mini-a';

  String _id(String prefix) => '$prefix-${_seq++}';
  static String _now() => DateTime.now().toUtc().toIso8601String();

  static Map<String, Object?> _person(String id, String name) => {'personId': id, 'displayName': name};
  static Map<String, Object?> _ref(String id, String name) => {'id': id, 'displayName': name};

  void _seed() {
    _seasons.addAll([
      {'id': 'season-2025', 'name': '2025/26', 'startsOn': '2025-09-01', 'endsOn': '2026-06-30', 'referenceYear': 2025, 'current': false},
      {'id': 'season-2026', 'name': '2026/27', 'startsOn': '2026-09-01', 'endsOn': '2027-06-30', 'referenceYear': 2026, 'current': true},
    ]);
    _categories.addAll([
      {'id': 'cat-u10', 'code': 'U10', 'name': 'Premini', 'maxAge': 10, 'rank': 1},
      {'id': 'cat-u12', 'code': 'U12', 'name': 'Mini', 'maxAge': 12, 'rank': 2},
      {'id': 'cat-u14', 'code': 'U14', 'name': 'Infantil', 'maxAge': 14, 'rank': 3},
      {'id': 'cat-u16', 'code': 'U16', 'name': 'Cadete', 'maxAge': 16, 'rank': 4},
    ]);
    Map<String, Object?> team(String id, String name, String? alias, String cat, String policy) => {
      'id': id, 'seasonId': 'season-2026', 'name': name, 'alias': alias,
      'ageCategory': _categories.firstWhere((c) => c['id'] == cat), 'genderPolicy': policy, 'playerCount': 0,
    };
    _teams.addAll([
      team(ownTeamId, 'Mini A', 'Leones', 'cat-u12', 'MIXED'),
      team('team-mini-b', 'Mini B', null, 'cat-u12', 'FEMALE'),
      team('team-inf-a', 'Infantil A', 'Halcones', 'cat-u14', 'MIXED'),
    ]);
    _members.addAll([
      _member('a1', 'Casey', 'Coach', roles),
      _member('m-ana', 'Alicia', 'Admin', ['ADMIN']),
      _member('m-tom', 'Tomás', 'Entrenador', ['COACH']),
      _member('m-ada', 'Ada', 'Asistente', ['ASSISTANT_COACH']),
      _member('m-pat', 'Pat', 'Padre', ['PARENT']),
    ]);
    _staff[ownTeamId] = [
      {'person': _person('m-tom', 'Tomás Entrenador'), 'role': 'COACH', 'since': '2026-09-01'},
    ];
    final seed = [
      ('p-ana', 'Ana', 'Ruiz', 2015, 'FEMALE', ownTeamId, '7'),
      ('p-leo', 'Leo', 'Gil', 2014, 'MALE', ownTeamId, '10'),
      ('p-mia', 'Mía', 'Soto', 2016, 'FEMALE', 'team-mini-b', '4'),
      ('p-dan', 'Dani', 'López', 2013, 'MALE', 'team-inf-a', '9'),
      ('p-eva', 'Eva', 'Mar', 2012, 'FEMALE', null, null),
    ];
    for (final (id, given, family, year, gender, teamId, jersey) in seed) {
      _players.add({
        'id': id, 'personId': 'person-$id', 'givenName': given, 'familyName': family,
        'displayName': '$given $family', 'birthDate': '$year-04-12', 'gender': gender,
        'status': teamId == null ? 'ORPHAN' : 'ACTIVE', 'teams': <Object?>[], 'createdAt': _now(),
      });
      if (teamId != null) _assign(teamId, id, jersey);
    }
    _links.add({
      'id': 'link-1', 'guardian': _person('m-pat', 'Pat Padre'), 'player': _ref('p-ana', 'Ana Ruiz'), 'createdAt': _now(),
    });
    _approvals.addAll([
      _approval('ap-1', 'ADD_PLAYER', 'PENDING', 'p-new', 'Lucas Mora', 'Visto en el torneo de Navidad'),
      _approval('ap-2', 'WITHDRAW_PLAYER', 'PENDING', 'p-leo', 'Leo Gil', null, reason: 'Se muda de ciudad'),
      _approval('ap-3', 'ADD_PLAYER', 'APPROVED', 'p-mia', 'Mía Soto', null),
    ]);
    _cases.add({
      'id': 'case-1', 'player': _ref('p-eva', 'Eva Mar'), 'team': {'id': ownTeamId, 'name': 'Mini A'},
      'reason': 'CATEGORY_TOO_LOW', 'status': 'OPEN', 'openedAt': _now(),
    });
    _recount();
  }

  Map<String, Object?> _member(String id, String given, String family, List<String> r) => {
    'personId': id, 'givenName': given, 'familyName': family, 'displayName': '$given $family',
    'email': '${given.toLowerCase()}@demo.hoops-academy.com', 'roles': r, 'active': true,
    'invitationStatus': 'ACCEPTED', 'temporaryPasswordStatus': 'NONE', 'createdAt': _now(),
  };

  Map<String, Object?> _approval(String id, String action, String status, String pid, String pname, String? note, {String? reason}) => {
    'id': id, 'action': action, 'status': status, 'player': _ref(pid, pname),
    'payload': {'note': ?note, 'reason': ?reason},
    'requestedBy': _person('a1', 'Casey Coach'), 'requestedAt': _now(),
  };

  // ------------------------------------------------------------ domain logic
  Map<String, Object?> _playerById(String id) => _players.firstWhere((p) => p['id'] == id);
  Map<String, Object?> _teamById(String id) => _teams.firstWhere((t) => t['id'] == id);

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
    if (levels > (_settings['maxPlayUpLevels']! as int)) reasons.add('PLAY_UP_LIMIT_EXCEEDED');
    final policy = t['genderPolicy'];
    if (policy != 'MIXED' && policy != p['gender']) reasons.add('GENDER_POLICY');
    if (reasons.isNotEmpty) {
      result = 'INELIGIBLE';
    } else if (levels > 0) {
      result = 'PLAY_UP';
    }
    return {
      'playerId': playerId, 'teamId': teamId, 'asOf': DateTime.now().toIso8601String().substring(0, 10),
      'result': result, 'playUpLevels': levels < 0 ? 0 : levels, 'reasons': reasons,
      'age': 2026 - int.parse((p['birthDate']! as String).substring(0, 4)),
      'naturalCategory': ?natural,
    };
  }

  Map<String, Object?> _assign(String teamId, String playerId, String? jersey) {
    final p = _playerById(playerId);
    final t = _teamById(teamId);
    final check = _check(teamId, playerId);
    (p['teams']! as List).removeWhere((a) => ((a as Map)['team'] as Map)['id'] == teamId);
    (p['teams']! as List).add({
      'team': {'id': teamId, 'name': t['name']}, 'jerseyNumber': jersey,
      'playUpLevels': check['playUpLevels'], 'valid': true,
    });
    if (p['status'] == 'ORPHAN') p['status'] = 'ACTIVE';
    _recount();
    return _teamPlayer(teamId, playerId);
  }

  Map<String, Object?> _teamPlayer(String teamId, String playerId) {
    final p = _playerById(playerId);
    final a = (p['teams']! as List).cast<Map<String, Object?>>().firstWhere((a) => (a['team'] as Map)['id'] == teamId);
    return {
      'player': _ref(playerId, p['displayName']! as String), 'teamId': teamId, 'jerseyNumber': a['jerseyNumber'],
      'joinedOn': '2026-09-01', 'playUpLevels': a['playUpLevels'], 'playerStatus': p['status'],
      if (a['valid'] == false) 'invalidatedAt': _now(),
    };
  }

  void _recount() {
    for (final t in _teams) {
      t['playerCount'] = _players.where((p) => (p['teams']! as List).any((a) => ((a as Map)['team'] as Map)['id'] == t['id'])).length;
    }
  }

  Map<String, Object?> _playerJson(Map<String, Object?> p) => {...p, 'naturalCategory': ?_naturalCategory(p)};

  static Map<String, Object?> _page(List<Object?> items) => {
    'items': items, 'page': {'page': 0, 'size': 100, 'totalElements': items.length, 'totalPages': 1},
  };

  Map<String, Object?> _profileJson(String tenantId) => {
    'id': tenantId, ..._profile, 'hasLogo': _logo != null, if (_logo != null) 'logoEtag': '"v$_logoVersion"',
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
  }) {
    final seg = path.split('/').where((s) => s.isNotEmpty).toList(); // api, core, ...
    if (seg.length < 3 || seg[0] != 'api' || seg[1] != 'core') return null;
    final res = seg[2];
    final id = seg.length > 3 ? seg[3] : null;
    final sub = seg.length > 4 ? seg[4] : null;
    final b = body is Map ? body.cast<String, Object?>() : <String, Object?>{};
    bool is_(String m) => method == m;

    switch (res) {
      case 'tenant':
        if (id == null) {
          if (is_('GET')) return MockResult.json(200, _profileJson(tenantId));
          if (is_('PATCH')) {
            for (final k in ['name', 'timezone', 'defaultLocale', 'contactEmail', 'websiteUrl']) {
              if (b.containsKey(k) && b[k] != null) _profile[k] = b[k];
            }
            return MockResult.json(200, _profileJson(tenantId));
          }
        }
        if (id == 'settings') {
          if (is_('PUT')) _settings.addAll(b);
          return MockResult.json(200, _settings);
        }
        if (id == 'logo') {
          if (is_('GET')) {
            return _logo == null
                ? const MockResult.json(404, {'title': 'No logo', 'status': 404})
                : MockResult.bytes(200, _logo, 'image/png', headers: {'etag': '"v$_logoVersion"', 'cache-control': 'private, max-age=0, must-revalidate'});
          }
          if (is_('PUT')) {
            _logo = bytes;
            _logoVersion++;
            return MockResult.json(200, {
              'contentType': 'image/png', 'sizeBytes': bytes?.length ?? 1, 'etag': '"v$_logoVersion"', 'updatedAt': _now(),
            });
          }
          if (is_('DELETE')) {
            if (_logo == null) return const MockResult.json(404, {'title': 'No logo', 'status': 404});
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
        if (id != null && sub == 'rollover' && is_('POST')) return MockResult.json(200, _rollover(id));
      case 'age-categories':
        if (id == null && is_('GET')) return MockResult.json(200, _categories);
        if (id == null && is_('POST')) {
          final c = {'id': _id('cat'), ...b};
          _categories.add(c);
          return MockResult.json(201, c);
        }
        if (id != null && is_('PATCH')) {
          final c = _categories.firstWhere((c) => c['id'] == id);
          c.addAll(b);
          return MockResult.json(200, c);
        }
        if (id != null && is_('DELETE')) {
          if (_teams.any((t) => (t['ageCategory']! as Map)['id'] == id)) {
            return const MockResult.json(409, {'title': 'Category in use', 'status': 409});
          }
          _categories.removeWhere((c) => c['id'] == id);
          return const MockResult.empty(204);
        }
      case 'members':
        return _members_(method, id, sub, query, b);
      case 'guardian-links':
        if (id == null && is_('GET')) {
          return MockResult.json(200, _page([
            for (final l in _links)
              if ((query['playerId'] == null || (l['player']! as Map)['id'] == query['playerId']) &&
                  (query['guardianPersonId'] == null || (l['guardian']! as Map)['personId'] == query['guardianPersonId']))
                l,
          ]));
        }
        if (id == null && is_('POST')) {
          final m = _members.firstWhere((m) => m['personId'] == b['guardianPersonId']);
          final p = _playerById(b['playerId']! as String);
          final l = {
            'id': _id('link'), 'guardian': _person(m['personId']! as String, m['displayName']! as String),
            'player': _ref(p['id']! as String, p['displayName']! as String), 'createdAt': _now(),
          };
          _links.add(l);
          return MockResult.json(201, l);
        }
        if (id != null && is_('DELETE')) {
          _links.removeWhere((l) => l['id'] == id);
          return const MockResult.empty(204);
        }
      case 'teams':
        return _teams_(method, id, sub, seg, query, b);
      case 'players':
        return _players_(method, id, sub, query, b);
      case 'approval-requests':
        return _approvals_(method, id, sub, query, b);
      case 'eligibility-cases':
        if (id == null && is_('GET')) {
          return MockResult.json(200, _page([
            for (final c in _cases) if (query['status'] == null || c['status'] == query['status']) c,
          ]));
        }
        if (id != null && sub == 'resolve' && is_('POST')) {
          final c = _cases.firstWhere((c) => c['id'] == id);
          if (b['resolution'] == 'REASSIGNED') {
            _assign(b['targetTeamId']! as String, (c['player']! as Map)['id']! as String, null);
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

  Map<String, Object?> _rollover(String fromId) {
    final next = {
      'id': _id('season'), 'name': 'Temporada siguiente', 'startsOn': '2027-09-01', 'endsOn': '2028-06-30',
      'referenceYear': 2027, 'current': false,
    };
    _seasons.add(next);
    final cloned = <Object?>[];
    final orphans = <Object?>[];
    final opened = <Object?>[];
    for (final t in _teams.where((t) => t['seasonId'] == fromId).toList()) {
      final copy = {...t, 'id': _id('team'), 'seasonId': next['id'], 'playerCount': 0};
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
            'previousTeam': {'id': t['id'], 'name': t['name']}, 'reasons': ['CATEGORY_TOO_LOW'],
          });
          final caseId = _id('case');
          opened.add(caseId);
          _cases.add({
            'id': caseId, 'player': _ref(p['id']! as String, p['displayName']! as String),
            'team': {'id': t['id'], 'name': t['name']}, 'reason': 'CATEGORY_TOO_LOW', 'status': 'OPEN', 'openedAt': _now(),
          });
        }
      }
    }
    return {'fromSeasonId': fromId, 'toSeasonId': next['id'], 'clonedTeams': cloned, 'orphans': orphans, 'openedCaseIds': opened};
  }

  MockResult? _members_(String method, String? id, String? sub, Map<String, dynamic> q, Map<String, Object?> b) {
    if (id == null && method == 'GET') {
      final text = (q['q'] as String?)?.toLowerCase();
      return MockResult.json(200, _page([
        for (final m in _members)
          if ((text == null || (m['displayName']! as String).toLowerCase().contains(text) ||
                  ((m['email'] as String?) ?? '').toLowerCase().contains(text)) &&
              (q['active'] == null || '${m['active']}' == '${q['active']}') &&
              (q['role'] == null || (m['roles']! as List).contains(q['role'])))
            m,
      ]));
    }
    if (id == null && method == 'POST') {
      final m = _member(_id('m'), b['givenName']! as String, b['familyName']! as String, (b['roles']! as List).cast<String>())
        ..['email'] = b['email']
        ..['invitationStatus'] = 'PENDING'
        ..['temporaryPasswordStatus'] = 'ACTIVE';
      _members.add(m);
      return MockResult.json(201, {...m, 'temporaryPassword': _mockPassword()});
    }
    final m = _members.where((m) => m['personId'] == id).firstOrNull;
    if (m == null) return const MockResult.json(404, {'title': 'Not found', 'status': 404});
    if (sub == null && method == 'GET') return MockResult.json(200, m);
    if (sub == 'roles' && method == 'PUT') {
      m['roles'] = b['roles'];
      return MockResult.json(200, m);
    }
    if (sub == 'deactivate' && method == 'POST') {
      m['active'] = false;
      return MockResult.json(200, m);
    }
    if (sub == 'temporary-password' && method == 'POST') {
      if (m['invitationStatus'] != 'PENDING') {
        return const MockResult.json(409, {'title': 'Conflict', 'status': 409, 'code': 'INVITATION_NOT_PENDING'});
      }
      m['temporaryPasswordStatus'] = 'ACTIVE';
      return MockResult.json(200, {...m, 'temporaryPassword': _mockPassword()});
    }
    return null;
  }

  int _passwordCount = 0;

  /// Demo stand-in for the server-generated temporary password (12+ characters, different every time).
  String _mockPassword() => 'demo-temp-pass-${++_passwordCount}';

  MockResult? _teams_(String method, String? id, String? sub, List<String> seg, Map<String, dynamic> q, Map<String, Object?> b) {
    if (id == null && method == 'GET') {
      return MockResult.json(200, _page([
        for (final t in _teams)
          if ((q['seasonId'] == null || t['seasonId'] == q['seasonId']) &&
              (q['ageCategoryId'] == null || (t['ageCategory']! as Map)['id'] == q['ageCategoryId']))
            t,
      ]));
    }
    if (id == null && method == 'POST') {
      final cat = _categories.firstWhere((c) => c['id'] == b['ageCategoryId']);
      final t = {
        'id': _id('team'), 'seasonId': b['seasonId'], 'name': b['name'], 'alias': b['alias'], 'ageCategory': cat,
        'genderPolicy': b['genderPolicy'], 'playerCount': 0,
      };
      _teams.add(t);
      return MockResult.json(201, t);
    }
    final t = _teams.where((t) => t['id'] == id).firstOrNull;
    if (t == null) return const MockResult.json(404, {'title': 'Not found', 'status': 404});
    if (sub == null && method == 'GET') return MockResult.json(200, t);
    if (sub == null && method == 'PATCH') {
      if (b['ageCategoryId'] != null) t['ageCategory'] = _categories.firstWhere((c) => c['id'] == b['ageCategoryId']);
      for (final k in ['name', 'alias', 'genderPolicy']) {
        if (b.containsKey(k)) t[k] = b[k];
      }
      return MockResult.json(200, t);
    }
    if (sub == 'staff') {
      final list = _staff.putIfAbsent(id!, () => []);
      final personId = seg.length > 5 ? seg[5] : null;
      if (personId == null && method == 'GET') return MockResult.json(200, list);
      if (personId != null && method == 'PUT') {
        final m = _members.firstWhere((m) => m['personId'] == personId);
        list.removeWhere((s) => (s['person']! as Map)['personId'] == personId);
        final s = {'person': _person(personId, m['displayName']! as String), 'role': b['role'], 'since': '2026-09-01'};
        list.add(s);
        return MockResult.json(200, s);
      }
      if (personId != null && method == 'DELETE') {
        list.removeWhere((s) => (s['person']! as Map)['personId'] == personId);
        return const MockResult.empty(204);
      }
    }
    if (sub == 'players') {
      final playerId = seg.length > 5 ? seg[5] : null;
      final tail = seg.length > 6 ? seg[6] : null;
      if (playerId == null && method == 'GET') {
        return MockResult.json(200, [
          for (final p in _players)
            if ((p['teams']! as List).any((a) => ((a as Map)['team'] as Map)['id'] == id)) _teamPlayer(id!, p['id']! as String),
        ]);
      }
      if (playerId == null && method == 'POST') {
        final pid = b['playerId']! as String;
        if (_check(id!, pid)['result'] == 'INELIGIBLE') {
          return const MockResult.json(422, {'title': 'Player is not eligible', 'status': 422, 'code': 'PLAYER_INELIGIBLE'});
        }
        return MockResult.json(201, _assign(id, pid, b['jerseyNumber'] as String?));
      }
      if (playerId != null && tail == 'eligibility' && method == 'GET') return MockResult.json(200, _check(id!, playerId));
      if (playerId != null && method == 'DELETE') {
        final p = _playerById(playerId);
        (p['teams']! as List).removeWhere((a) => ((a as Map)['team'] as Map)['id'] == id);
        if ((p['teams']! as List).isEmpty && p['status'] == 'ACTIVE') p['status'] = 'ORPHAN';
        _recount();
        return const MockResult.empty(204);
      }
      if (playerId != null && method == 'PATCH') {
        final p = _playerById(playerId);
        for (final a in (p['teams']! as List).cast<Map<String, Object?>>()) {
          if ((a['team'] as Map)['id'] == id) a['jerseyNumber'] = b['jerseyNumber'];
        }
        return MockResult.json(200, _teamPlayer(id!, playerId));
      }
    }
    return null;
  }

  MockResult? _players_(String method, String? id, String? sub, Map<String, dynamic> q, Map<String, Object?> b) {
    if (id == null && method == 'GET') {
      final text = (q['q'] as String?)?.toLowerCase();
      return MockResult.json(200, _page([
        for (final p in _players)
          if ((q['status'] == null || p['status'] == q['status']) &&
              (q['teamId'] == null || (p['teams']! as List).any((a) => ((a as Map)['team'] as Map)['id'] == q['teamId'])) &&
              (text == null || (p['displayName']! as String).toLowerCase().contains(text)))
            _playerJson(p),
      ]));
    }
    if (id == null && method == 'POST') {
      final admin = roles.contains('ADMIN');
      final pid = _id('p');
      final p = {
        'id': pid, 'personId': 'person-$pid', 'givenName': b['givenName'], 'familyName': b['familyName'],
        'displayName': '${b['givenName']} ${b['familyName']}', 'birthDate': b['birthDate'], 'gender': b['gender'],
        'status': admin ? 'ORPHAN' : 'PENDING_APPROVAL', 'teams': <Object?>[], 'createdAt': _now(),
      };
      _players.add(p);
      if (admin && b['teamId'] != null) _assign(b['teamId']! as String, pid, b['jerseyNumber'] as String?);
      final a = _approval(_id('ap'), 'ADD_PLAYER', admin ? 'APPROVED' : 'PENDING', pid, p['displayName']! as String, b['note'] as String?);
      _approvals.add(a);
      return MockResult.json(admin ? 201 : 202, {'player': _playerJson(p), 'approvalRequest': a});
    }
    final p = _players.where((p) => p['id'] == id).firstOrNull;
    if (p == null) return const MockResult.json(404, {'title': 'Not found', 'status': 404});
    if (sub == null && method == 'GET') return MockResult.json(200, _playerJson(p));
    if (sub == 'eligible-teams' && method == 'GET') {
      return MockResult.json(200, [
        for (final t in _teams)
          if (t['seasonId'] == (q['seasonId'] ?? 'season-2026'))
            {'team': t, 'eligibility': _check(t['id']! as String, id!)},
      ]);
    }
    if (sub == 'withdraw' && method == 'POST') {
      final admin = roles.contains('ADMIN');
      if (admin) {
        p['status'] = 'WITHDRAWN';
        (p['teams']! as List).clear();
        _recount();
      }
      final a = _approval(_id('ap'), 'WITHDRAW_PLAYER', admin ? 'APPROVED' : 'PENDING', id!, p['displayName']! as String, null, reason: b['reason'] as String?);
      _approvals.add(a);
      return MockResult.json(admin ? 200 : 202, {'player': _playerJson(p), 'approvalRequest': a});
    }
    return null;
  }

  MockResult? _approvals_(String method, String? id, String? sub, Map<String, dynamic> q, Map<String, Object?> b) {
    if (id == null && method == 'GET') {
      return MockResult.json(200, _page([
        for (final a in _approvals) if (q['status'] == null || a['status'] == q['status']) a,
      ]));
    }
    final a = _approvals.where((a) => a['id'] == id).firstOrNull;
    if (a == null) return const MockResult.json(404, {'title': 'Not found', 'status': 404});
    if (sub == null && method == 'GET') return MockResult.json(200, a);
    if (a['status'] != 'PENDING') return const MockResult.json(409, {'title': 'Already decided', 'status': 409});
    final pid = (a['player']! as Map)['id'] as String;
    switch (sub) {
      case 'approve':
        a['status'] = 'APPROVED';
        a['decisionNote'] = b['note'];
        final p = _players.where((p) => p['id'] == pid).firstOrNull;
        if (p != null && a['action'] == 'ADD_PLAYER' && p['status'] == 'PENDING_APPROVAL') p['status'] = 'ORPHAN';
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
  static Uint8List encode(MockResult r) => r.bytes ?? Uint8List.fromList(utf8.encode(jsonEncode(r.json ?? {})));
}
