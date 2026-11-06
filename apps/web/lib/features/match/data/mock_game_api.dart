import '../../../core/mock/mock_core_api.dart';
import '../domain/feed_visibility.dart';
import '../domain/match_event.dart';
import '../domain/projector/projection.dart';
import '../domain/projector/projector.dart';

/// In-memory game-service for dev mock mode (`HOOPS_MOCK_API=true`), JSON in
/// and out like the real API (behind the generated clients): matches, roster,
/// `events:batch` with per-event results (ADR-0014 order and parent rule),
/// feed, box score and season stats (projected with the app's projector,
/// which the vector tests tie to the server).
class MockGameApi {
  MockGameApi({required this.roles, this.personId = 'a1', this.linkedPlayerIds = const ['p-ana']}) {
    _seed();
  }

  final List<String> roles;
  final String personId;
  final List<String> linkedPlayerIds;

  static const ownTeamId = MockCoreApi.ownTeamId;
  static const liveMatchId = '0190b6a0-0000-7000-8000-00000000c001';
  static const scheduledMatchId = '0190b6a0-0000-7000-8000-00000000c002';
  static const finishedMatchId = '0190b6a0-0000-7000-8000-00000000c003';

  final List<Map<String, Object?>> _matches = [];
  final Map<String, List<Map<String, Object?>>> _rosters = {};
  final Map<String, List<_Stored>> _events = {};
  var _serverSeq = 0;
  var _ids = 0;

  bool get _staff => roles.contains('ADMIN') || roles.contains('COACH') || roles.contains('ASSISTANT_COACH');

  void _seed() {
    Map<String, Object?> match(String id, String opponent, String status, DateTime at, {String home = 'HOME'}) => {
      'id': id, 'teamId': ownTeamId, 'seasonId': 'season-2026', 'opponentName': opponent, 'homeAway': home,
      'scheduledAt': at.toUtc().toIso8601String(), 'venue': 'Pabellón Norte', 'status': status,
      'periodCount': 4, 'periodMinutes': 10, 'startedAt': null, 'finishedAt': null, 'cancelledAt': null,
      'cancelReason': null, 'score': {'team': 0, 'opponent': 0}, 'lastServerSeq': 0,
    };
    final now = DateTime.now().toUtc();
    _matches.addAll([
      match(liveMatchId, 'Tigres', 'LIVE', now.subtract(const Duration(minutes: 20))),
      match(scheduledMatchId, 'Águilas', 'SCHEDULED', now.add(const Duration(days: 3)), home: 'AWAY'),
      match(finishedMatchId, 'Lobos', 'FINISHED', now.subtract(const Duration(days: 7))),
    ]);
    final roster = [
      _entry('p-ana', 'Ana Ruiz', '7', true),
      _entry('p-leo', 'Leo Gil', '10', true),
      _entry('p-sara', 'Sara Vidal', '4', true),
      _entry('p-iker', 'Iker Sanz', '5', true),
      _entry('p-noa', 'Noa Pardo', '8', true),
      _entry('p-hugo', 'Hugo Rey', '11', false),
      _entry('p-lia', 'Lía Marín', '13', false),
    ];
    _rosters[liveMatchId] = roster;
    _rosters[finishedMatchId] = roster;
    _scriptGame(finishedMatchId, periods: 4, started: now.subtract(const Duration(days: 7)));
    _scriptGame(liveMatchId, periods: 1, started: now.subtract(const Duration(minutes: 20)), finishLast: false);
    _refreshScore(liveMatchId);
    _refreshScore(finishedMatchId);
  }

  static Map<String, Object?> _entry(String id, String name, String? jersey, bool starter) =>
      {'playerId': id, 'displayName': name, 'jerseyNumber': jersey, 'isStarter': starter};

  void _scriptGame(String matchId, {required int periods, required DateTime started, bool finishLast = true}) {
    var t = started;
    var seq = 0;
    void add(String type, int period, int clock, {String? player, Map<String, Object?>? payload}) {
      t = t.add(const Duration(seconds: 20));
      _store(matchId, {
        'id': _newId(), 'deviceId': 'mock-bench', 'clientSeq': ++seq, 'type': type, 'period': period,
        'clockSecondsRemaining': clock, 'recordedAtClient': t.toIso8601String(),
        'playerId': ?player, 'payload': ?payload,
      }, 'm-tom', 'Tomás Entrenador');
    }

    const shooters = ['p-ana', 'p-leo', 'p-sara', 'p-iker', 'p-noa'];
    for (var p = 1; p <= periods; p++) {
      add('PERIOD_START', p, 600);
      for (var i = 0; i < 4; i++) {
        final clock = 540 - i * 120;
        add('SHOT', p, clock, player: shooters[(i + p) % 5], payload: {'points': 2, 'made': i.isEven});
        if (i.isEven) add('ASSIST', p, clock, player: shooters[(i + p + 1) % 5]);
        add('OPPONENT_SCORE', p, clock - 30, payload: {'points': i == 3 ? 3 : 2});
        add('REBOUND', p, clock - 50, player: shooters[(i + 2) % 5], payload: {'kind': 'DEFENSIVE'});
      }
      if (p < periods || finishLast) add('PERIOD_END', p, 0);
    }
  }

  String _newId() {
    final n = (++_ids).toRadixString(16).padLeft(12, '0');
    return '0190b6a0-0000-7000-8000-$n';
  }

  void _store(String matchId, Map<String, Object?> json, String person, String name) {
    _events.putIfAbsent(matchId, () => []).add(_Stored(json, ++_serverSeq, person, name, DateTime.now().toUtc()));
  }

  // ------------------------------------------------------------------ routes

  /// Answers `/api/game/...`; null for unknown paths.
  MockResult? handle({
    required String method,
    required String path,
    required Map<String, dynamic> query,
    Object? body,
  }) {
    final seg = path.split('/').where((s) => s.isNotEmpty).toList();
    if (seg.length < 3 || seg[0] != 'api' || seg[1] != 'game') return null;
    final b = body is Map ? body.cast<String, Object?>() : <String, Object?>{};
    if (seg[2] == 'players' && seg.length == 5 && seg[4] == 'season-stats') {
      return _seasonStats(seg[3], query['seasonId']?.toString());
    }
    if (seg[2] != 'matches') return null;
    if (seg.length == 3) {
      if (method == 'GET') return _list(query);
      if (method == 'POST') return _create(b);
    }
    final m = seg.length > 3 ? _find(seg[3]) : null;
    if (m == null) return _problem(404, 'Not found');
    final id = m['id']! as String;
    if (seg.length == 4 && method == 'GET') return MockResult.json(200, m);
    if (seg.length == 4 && method == 'PATCH') return _patch(m, b);
    switch (seg[4]) {
      case 'start':
        if (!_staff) return _problem(403, 'Forbidden');
        if ((_rosters[id] ?? []).every((e) => e['isStarter'] != true)) return _problem(422, 'Roster needs a starter');
        m['status'] = 'LIVE';
        m['startedAt'] ??= DateTime.now().toUtc().toIso8601String();
        return MockResult.json(200, m);
      case 'finish':
        if (!_staff) return _problem(403, 'Forbidden');
        if (m['status'] != 'LIVE') return _problem(409, 'Not live');
        m['status'] = 'FINISHED';
        m['finishedAt'] = DateTime.now().toUtc().toIso8601String();
        return MockResult.json(200, m);
      case 'roster':
        if (method == 'PUT') {
          if (!_staff) return _problem(403, 'Forbidden');
          _rosters[id] = [
            for (final e in (b['entries'] as List? ?? const []).cast<Map<String, Object?>>())
              _entry(e['playerId']! as String, _names[e['playerId']] ?? e['playerId']! as String, e['jerseyNumber'] as String?, e['isStarter'] == true),
          ];
        }
        return MockResult.json(200, {'matchId': id, 'entries': _rosters[id] ?? const []});
      case 'events:batch':
        return _batch(m, (b['events'] as List? ?? const []).cast<Map<String, Object?>>());
      case 'events':
        return _feed(id, int.tryParse('${query['after'] ?? 0}') ?? 0, int.tryParse('${query['limit'] ?? 500}') ?? 500);
      case 'box-score':
        return MockResult.json(200, _boxScore(m));
    }
    return _problem(404, 'Not found');
  }

  static const _names = {'p-ana': 'Ana Ruiz', 'p-leo': 'Leo Gil', 'p-mia': 'Mía Soto', 'p-dan': 'Dani López', 'p-eva': 'Eva Mar'};

  Map<String, Object?>? _find(String id) {
    for (final m in _matches) {
      if (m['id'] == id) return m;
    }
    return null;
  }

  MockResult _list(Map<String, dynamic> q) {
    final team = q['teamId']?.toString();
    final season = q['seasonId']?.toString();
    final items = [
      for (final m in _matches)
        if ((team == null || m['teamId'] == team) && (season == null || m['seasonId'] == season)) m,
    ]..sort((a, b) => (b['scheduledAt']! as String).compareTo(a['scheduledAt']! as String));
    return MockResult.json(200, {
      'items': items,
      'page': {'page': 0, 'size': 100, 'totalElements': items.length, 'totalPages': 1},
    });
  }

  /// ADR-0032: null or absent is unchanged, `clear` empties the venue, a value that is also in `clear` is a 400.
  MockResult _patch(Map<String, Object?> m, Map<String, Object?> b) {
    if (!_staff) return _problem(403, 'Forbidden');
    final clear = (b['clear'] as List? ?? const []).cast<String>();
    if (clear.any((n) => n != 'venue') || (clear.contains('venue') && b['venue'] != null)) {
      return _problem(400, 'Bad clear list');
    }
    for (final key in const ['opponentName', 'homeAway', 'scheduledAt', 'venue', 'periodCount', 'periodMinutes']) {
      if (b[key] != null) m[key] = b[key];
    }
    if (clear.contains('venue')) m['venue'] = null;
    return MockResult.json(200, m);
  }

  MockResult _create(Map<String, Object?> b) {
    if (!_staff) return _problem(403, 'Forbidden');
    final m = <String, Object?>{
      'id': _newId(), 'teamId': b['teamId'], 'seasonId': 'season-2026', 'opponentName': b['opponentName'],
      'homeAway': b['homeAway'] ?? 'HOME', 'scheduledAt': b['scheduledAt'], 'venue': b['venue'], 'status': 'SCHEDULED',
      'periodCount': b['periodCount'] ?? 4, 'periodMinutes': b['periodMinutes'] ?? 10, 'startedAt': null,
      'finishedAt': null, 'cancelledAt': null, 'cancelReason': null, 'score': {'team': 0, 'opponent': 0}, 'lastServerSeq': 0,
    };
    _matches.add(m);
    return MockResult.json(201, m);
  }

  static const _parentTypes = {'SHOT', 'ASSIST', 'REBOUND', 'TURNOVER', 'STEAL', 'BLOCK', 'FOUL'};

  MockResult _batch(Map<String, Object?> m, List<Map<String, Object?>> events) {
    if (events.isEmpty || events.length > 500) return _problem(400, 'Bad batch');
    final id = m['id']! as String;
    final stored = _events.putIfAbsent(id, () => []);
    final mine = <String>{for (final s in stored) if (s.person == personId) s.json['id']! as String};
    final results = <Map<String, Object?>>[];
    for (final e in events) {
      final eventId = e['id'] as String? ?? '00000000-0000-0000-0000-000000000000';
      final known = stored.where((s) => s.json['id'] == eventId).firstOrNull;
      String? reason;
      try {
        MatchEvent.fromJson(e);
      } on Object {
        reason = 'SCHEMA_INVALID';
      }
      if (reason == null && known != null) {
        results.add({'eventId': eventId, 'status': 'DUPLICATE', 'serverSeq': known.seq});
        continue;
      }
      if (reason == null && m['status'] == 'CANCELLED') reason = 'MATCH_CANCELLED';
      if (reason == null && !_staff) {
        final type = e['type'];
        final ok = (_parentTypes.contains(type) && linkedPlayerIds.contains(e['playerId'])) ||
            (type == 'VOID' && mine.contains((e['payload'] as Map?)?['targetEventId']));
        if (!roles.contains('PARENT') || !ok) reason = 'NOT_AUTHORIZED';
      }
      if (reason == null &&
          stored.any((s) => s.json['deviceId'] == e['deviceId'] && s.json['clientSeq'] == e['clientSeq'])) {
        reason = 'CLIENT_SEQ_CONFLICT';
      }
      if (reason != null) {
        results.add({'eventId': eventId, 'status': 'REJECTED', 'reason': reason, 'message': reason});
        continue;
      }
      _store(id, e, personId, 'Casey Coach');
      mine.add(eventId);
      results.add({'eventId': eventId, 'status': 'ACCEPTED', 'serverSeq': _serverSeq});
    }
    _refreshScore(id);
    return MockResult.json(200, {'results': results, 'lastServerSeq': m['lastServerSeq']});
  }

  /// Filtered like game-service (ADR-0030): staff read every event, anybody
  /// else team-level events plus those of linked players.
  MockResult _feed(String matchId, int after, int limit) {
    final stored = _events[matchId] ?? <_Stored>[];
    final visible = visibleFeed(stored, (s) => MatchEvent.fromJson(s.json), visiblePlayers: _staff ? null : {...linkedPlayerIds});
    final all = [for (final s in visible) if (s.seq > after) s];
    final page = all.take(limit).toList();
    final voided = _project(matchId).voidedBy;
    return MockResult.json(200, {
      'events': [
        for (final s in page)
          {
            'serverSeq': s.seq,
            'event': s.json,
            'recordedBy': {'personId': s.person, 'displayName': s.name},
            'receivedAt': s.receivedAt.toIso8601String(),
            'voidedByEventId': voided[s.json['id']],
          },
      ],
      'lastServerSeq': stored.isEmpty ? 0 : stored.last.seq,
      'hasMore': all.length > page.length,
    });
  }

  Projection _project(String matchId) {
    final m = _find(matchId)!;
    return project(
      MatchRules(periodCount: m['periodCount']! as int, periodMinutes: m['periodMinutes']! as int),
      [
        for (final e in _rosters[matchId] ?? const <Map<String, Object?>>[])
          RosterPlayer(playerId: e['playerId']! as String, displayName: e['displayName']! as String, isStarter: e['isStarter'] == true),
      ],
      [for (final s in _events[matchId] ?? <_Stored>[]) RecordedEvent(MatchEvent.fromJson(s.json), serverSeq: s.seq)],
    );
  }

  void _refreshScore(String matchId) {
    final p = _project(matchId);
    final m = _find(matchId)!;
    m['score'] = {'team': p.summary.teamScore, 'opponent': p.summary.opponentScore};
    m['lastServerSeq'] = p.summary.lastServerSeq;
  }

  Map<String, Object?> _boxScore(Map<String, Object?> m) {
    final id = m['id']! as String;
    final p = _project(id);
    final roster = {for (final e in _rosters[id] ?? const <Map<String, Object?>>[]) e['playerId']: e};
    bool visible(String player) => _staff || linkedPlayerIds.contains(player);
    return {
      'matchId': id,
      'status': m['status'],
      'score': {'team': p.summary.teamScore, 'opponent': p.summary.opponentScore},
      'periodScores': [for (final s in p.summary.periodScores) {'period': s.period, 'team': s.team, 'opponent': s.opponent}],
      'teamTotals': _line(p.teamTotals),
      'players': [
        for (final l in p.playerStats)
          if (visible(l.playerId))
            {
              'playerId': l.playerId,
              'displayName': roster[l.playerId]?['displayName'] ?? l.playerId,
              'jerseyNumber': roster[l.playerId]?['jerseyNumber'],
              'wasStarter': l.wasStarter,
              'stats': _line(l.stats),
              'warnings': [for (final w in l.warnings) _warning(w)],
            },
      ],
      'warnings': [for (final w in p.warnings) _warning(w)],
      'lastServerSeq': p.summary.lastServerSeq,
    };
  }

  MockResult _seasonStats(String playerId, String? seasonId) {
    if (!_staff && !linkedPlayerIds.contains(playerId)) return _problem(404, 'Not found');
    var totals = StatLine.zero;
    var played = 0, started = 0;
    final lines = <Map<String, Object?>>[];
    for (final m in _matches) {
      if (m['status'] != 'LIVE' && m['status'] != 'FINISHED') continue;
      if (seasonId != null && m['seasonId'] != seasonId) continue;
      final line = _project(m['id']! as String).lineOf(playerId);
      if (line == null) continue;
      totals += line.stats;
      played++;
      if (line.wasStarter) started++;
      lines.add({
        'matchId': m['id'], 'scheduledAt': m['scheduledAt'], 'opponentName': m['opponentName'], 'status': m['status'],
        'wasStarter': line.wasStarter, 'stats': _line(line.stats),
      });
    }
    double avg(int v) => played == 0 ? 0 : (v / played * 100).round() / 100;
    return MockResult.json(200, {
      'playerId': playerId, 'seasonId': seasonId ?? 'season-2026', 'gamesPlayed': played, 'gamesStarted': started,
      'totals': _line(totals),
      'averages': {
        'points': avg(totals.points), 'assists': avg(totals.assists), 'rebounds': avg(totals.rebounds),
        'steals': avg(totals.steals), 'blocks': avg(totals.blocks), 'turnovers': avg(totals.turnovers),
        'personalFouls': avg(totals.personalFouls), 'technicalFouls': 0, 'unsportsmanlikeFouls': 0,
        'minutesPlayed': played == 0 ? 0 : (totals.secondsPlayed / 60 / played * 100).round() / 100,
      },
      'matches': lines,
    });
  }

  static Map<String, Object?> _line(StatLine s) => {
    'points': s.points, 'fg1Made': s.fg1Made, 'fg1Attempted': s.fg1Attempted, 'fg2Made': s.fg2Made,
    'fg2Attempted': s.fg2Attempted, 'fg3Made': s.fg3Made, 'fg3Attempted': s.fg3Attempted, 'assists': s.assists,
    'offensiveRebounds': s.offensiveRebounds, 'defensiveRebounds': s.defensiveRebounds, 'turnovers': s.turnovers,
    'steals': s.steals, 'blocks': s.blocks, 'personalFouls': s.personalFouls, 'technicalFouls': 0, 'unsportsmanlikeFouls': 0, 'secondsPlayed': s.secondsPlayed,
  };

  static Map<String, Object?> _warning(ProjectionWarning w) =>
      {'code': w.code, 'eventId': w.eventId, 'playerId': w.playerId, 'message': w.code};

  static MockResult _problem(int status, String title) =>
      MockResult.json(status, {'type': 'urn:hoops:problem:mock', 'title': title, 'status': status});
}

class _Stored {
  _Stored(this.json, this.seq, this.person, this.name, this.receivedAt);
  final Map<String, Object?> json;
  final int seq;
  final String person;
  final String name;
  final DateTime receivedAt;
}
