import '../time/tenant_zone.dart';
import 'mock_authz.dart';
import 'mock_core_api.dart';
import 'mock_query.dart';

/// In-memory stand-in for athlete-service (`/api/athlete/**`) for one demo academy, dev mock mode only: a week of
/// training sessions with attendance, planned absences, plans, injuries, measurements and physical tests with norm
/// bands. The team rosters and the players' facts are read from [core] (one source per academy, WP47); the `clear`
/// lists of update requests follow ADR-0032. What a role sees and may change follows `docs/domain/authz-matrix.md`
/// through `core.authz`: a staff member their teams, a guardian the linked players, a player himself; a player or
/// team the user may not see is a 404, a visible one they may not change a 403.
class MockAthleteApi {
  MockAthleteApi({
    required this.core,
    DateTime Function()? now,
    String zone = 'Europe/Madrid',
  }) : _now = now ?? DateTime.now,
       _zone = TenantZone.of(zone),
       _home = core.homeTeamId {
    _seed();
  }

  final MockCoreApi core;
  final String _home;

  final DateTime Function() _now;
  final TenantZone _zone;

  static const _recorder = {'personId': 'a1', 'displayName': 'Casey Coach'};

  MockAuthz get _az => core.authz;

  Set<String> _roster(String? teamId) =>
      teamId == null ? const {} : core.rosterOf(teamId);

  /// The seeded cast of the home team: three players for the health and fitness data (the third from another team in
  /// the demo academy, so it has no sessions of the first two).
  String get _a => _home == MockCoreApi.ownTeamId ? 'p-ana' : 'p-nora';
  String get _b => _home == MockCoreApi.ownTeamId ? 'p-leo' : 'p-nico';
  String get _c => _home == MockCoreApi.ownTeamId ? 'p-mia' : 'p-nuria';

  final _schedules = <Map<String, Object?>>[];
  final _sessions = <Map<String, Object?>>[];
  final _attendance = <String, Map<String, Map<String, Object?>>>{};
  final _absences = <Map<String, Object?>>[];
  final _plans = <Map<String, Object?>>[];
  final _assignments = <Map<String, Object?>>[];
  final _completions = <Map<String, Object?>>[];
  final _injuries = <Map<String, Object?>>[];
  final _measurements = <Map<String, Object?>>[];
  final _types = <Map<String, Object?>>[];
  final _results = <Map<String, Object?>>[];
  final _norms = <Map<String, Object?>>[];
  var _seq = 100;

  String _id(String prefix) => '$prefix-${_seq++}';
  String get _stamp => _now().toUtc().toIso8601String();
  DateTime get _today => _zone.today(_now());
  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _dayIn(int days) => _date(_today.add(Duration(days: days)));

  // ------------------------------------------------------------------ seed
  void _seed() {
    _seedTraining();
    _seedPlans();
    _seedHealth();
    _seedFitness();
  }

  void _seedTraining() {
    Map<String, Object?> schedule(
      String id,
      String team,
      String day,
      String time,
      int minutes,
      String place,
    ) => {
      'id': id,
      'teamId': team,
      'dayOfWeek': day,
      'startTime': time,
      'durationMinutes': minutes,
      'location': place,
      'validFrom': _dayIn(-120),
      'validUntil': null,
    };
    final demo = _home == MockCoreApi.ownTeamId;
    _schedules.addAll(
      demo
          ? [
              schedule(
                'sch-mon',
                _home,
                'MONDAY',
                '17:30',
                90,
                'Pabellón Norte',
              ),
              schedule(
                'sch-wed',
                _home,
                'WEDNESDAY',
                '17:30',
                90,
                'Pabellón Norte',
              ),
              schedule(
                'sch-fri',
                _home,
                'FRIDAY',
                '17:00',
                60,
                'Pista exterior',
              ),
              schedule(
                'sch-tue',
                'team-inf-a',
                'TUESDAY',
                '18:30',
                90,
                'Pabellón Sur',
              ),
              schedule(
                'sch-thu',
                'team-inf-a',
                'THURSDAY',
                '18:30',
                90,
                'Pabellón Sur',
              ),
            ]
          : [
              schedule(
                'sch-norte-tue',
                _home,
                'TUESDAY',
                '18:00',
                90,
                'Polideportivo Norte',
              ),
              schedule(
                'sch-norte-thu',
                _home,
                'THURSDAY',
                '18:00',
                90,
                'Polideportivo Norte',
              ),
              schedule(
                'sch-norte-sat',
                _home,
                'SATURDAY',
                '10:00',
                60,
                'Pista exterior',
              ),
            ],
    );
    const days = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    final today = _today;
    for (var offset = -14; offset <= 21; offset++) {
      final day = today.add(Duration(days: offset));
      for (final s in _schedules.where(
        (s) => s['dayOfWeek'] == days[day.weekday - 1],
      )) {
        final time = '${s['startTime']}'.split(':').map(int.parse).toList();
        _sessions.add({
          'id': 'ses-${s['id']}-${_date(day)}',
          'teamId': s['teamId'],
          'scheduleId': s['id'],
          'startsAt': _zone
              .instant(DateTime(day.year, day.month, day.day, time[0], time[1]))
              .toIso8601String(),
          'durationMinutes': s['durationMinutes'],
          'location': s['location'],
          'status': offset < 0 ? 'DONE' : 'PLANNED',
          'planId': null,
          'notes': null,
          'cancelReason': null,
        });
      }
    }
    // The first upcoming session of Mini A is cancelled, the next one carries the warm-up plan.
    final upcoming = _sessions
        .where((s) => s['teamId'] == _home && s['status'] == 'PLANNED')
        .toList();
    if (upcoming.length > 1) {
      upcoming[0]
        ..['status'] = 'CANCELLED'
        ..['cancelReason'] = 'Pabellón cerrado por obras';
      upcoming[1]['planId'] = 'plan-warmup';
    }
    // Attendance of the finished sessions of Mini A: mostly present, one late, one absent.
    var n = 0;
    for (final s in _sessions.where(
      (s) => s['teamId'] == _home && s['status'] == 'DONE',
    )) {
      final sheet = _attendance['${s['id']}'] = {};
      for (final p in _roster(_home)) {
        final late = n % 4 == 1 && p == _b;
        final absent = n % 5 == 2 && p == _a;
        sheet[p] = {
          'status': absent ? 'ABSENT' : (late ? 'LATE' : 'PRESENT'),
          'minutesLate': late ? 10 : null,
          'note': absent ? 'Enferma' : null,
          'recordedBy': _recorder,
          'recordedAt': s['startsAt'],
        };
      }
      n++;
    }
    _absences.addAll([
      _absence('abs-1', _a, _dayIn(2), _dayIn(3), 'Torneo de ajedrez'),
      _absence('abs-2', _b, _dayIn(-20), _dayIn(-18), 'Vacaciones'),
    ]);
  }

  Map<String, Object?> _absence(
    String id,
    String player,
    String from,
    String to,
    String? reason,
  ) => {
    'id': id,
    'playerId': player,
    'fromDate': from,
    'toDate': to,
    'reason': reason,
    'recordedBy': _recorder,
    'recordedAt': _stamp,
  };

  void _seedPlans() {
    Map<String, Object?> item(
      String id,
      int position,
      String title, {
      String? description,
      int? minutes,
      int? sets,
      int? reps,
    }) => {
      'id': id,
      'position': position,
      'title': title,
      'description': description,
      'durationMinutes': minutes,
      'sets': sets,
      'repetitions': reps,
    };
    Map<String, Object?> plan(
      String id,
      String name,
      String description,
      bool template,
      List<Map<String, Object?>> items,
    ) => {
      'id': id,
      'name': name,
      'description': description,
      'template': template,
      'sourceTemplateId': null,
      'archived': false,
      'items': items,
    };
    _plans.addAll([
      plan(
        'tpl-shooting',
        'Fundamentos de tiro',
        'Mecánica y volumen de tiro para categorías de base',
        true,
        [
          item(
            'tpl-s1',
            0,
            'Tiro en estático',
            description: 'Codo bajo el balón, seguimiento largo',
            minutes: 10,
            sets: 3,
            reps: 10,
          ),
          item('tpl-s2', 1, 'Tiros libres', minutes: 8, sets: 2, reps: 10),
          item('tpl-s3', 2, 'Tiro tras bote', minutes: 12, sets: 3, reps: 8),
        ],
      ),
      plan('tpl-handling', 'Manejo de balón', 'Control con ambas manos', true, [
        item('tpl-h1', 0, 'Bote con dos balones', minutes: 10),
        item('tpl-h2', 1, 'Cambios de mano en slalom', minutes: 12, sets: 4),
      ]),
      plan(
        'tpl-conditioning',
        'Acondicionamiento',
        'Resistencia y velocidad por intervalos',
        true,
        [
          item('tpl-c1', 0, 'Test de Cooper 12 min', minutes: 12),
          item('tpl-c2', 1, 'Suicidios', minutes: 8, sets: 4),
          item('tpl-c3', 2, 'Sprints de 20 m', minutes: 6, sets: 6),
        ],
      ),
      plan(
        'plan-warmup',
        'Calentamiento Mini',
        'Rutina de 15 minutos antes de entrenar',
        false,
        [
          item('w1', 0, 'Trote y movilidad', minutes: 5),
          item('w2', 1, 'Pases por parejas', minutes: 5, reps: 20),
          item('w3', 2, 'Entradas a canasta', minutes: 5, sets: 2, reps: 6),
        ],
      ),
    ]);
    _assignments.add({
      'id': 'asg-1',
      'planId': 'plan-warmup',
      'teamId': _home,
      'playerId': null,
      'dueOn': _dayIn(5),
      'notes': 'Para la semana que viene',
      'recordedBy': _recorder,
      'recordedAt': _stamp,
    });
    _completions.add({
      'id': 'cmp-1',
      'assignmentId': 'asg-1',
      'playerId': _a,
      'status': 'DONE',
      'comment': null,
      'recordedBy': _recorder,
      'recordedAt': _stamp,
    });
  }

  void _seedHealth() {
    final demo = _home == MockCoreApi.ownTeamId;
    _injuries.addAll([
      {
        'id': 'inj-1',
        'playerId': demo ? _b : _a,
        'occurredOn': _dayIn(-6),
        'bodyPart': demo ? 'rodilla izquierda' : 'muñeca derecha',
        'severity': 'MODERATE',
        'description': 'Golpe en un entrenamiento',
        'expectedReturnOn': _dayIn(12),
        'actualReturnOn': null,
        'status': 'OPEN',
        'recordedBy': _recorder,
        'recordedAt': _stamp,
      },
      {
        'id': 'inj-2',
        'playerId': demo ? _a : _b,
        'occurredOn': _dayIn(-60),
        'bodyPart': 'tobillo derecho',
        'severity': 'MINOR',
        'description': null,
        'expectedReturnOn': _dayIn(-50),
        'actualReturnOn': _dayIn(-52),
        'status': 'RECOVERED',
        'recordedBy': _recorder,
        'recordedAt': _stamp,
      },
    ]);
    Map<String, Object?> body(
      String id,
      String player,
      int daysAgo,
      double height,
      double weight,
    ) => {
      'id': id,
      'playerId': player,
      'measuredOn': _dayIn(-daysAgo),
      'heightCm': height,
      'weightKg': weight,
      'recordedBy': _recorder,
      'recordedAt': _stamp,
    };
    _measurements.addAll([
      body('bm-1', _a, 200, 142.0, 34.5),
      body('bm-2', _a, 100, 144.5, 36.0),
      body('bm-3', _a, 10, 146.0, 37.2),
      body('bm-4', _b, 150, 150.5, 40.0),
      body('bm-5', _b, 15, 153.0, 42.5),
    ]);
  }

  void _seedFitness() {
    Map<String, Object?> type(
      String id,
      String code,
      String name,
      String unit,
      bool higher,
    ) => {
      'id': id,
      'code': code,
      'name': name,
      'unit': unit,
      'higherIsBetter': higher,
      'description': null,
      'global': true,
    };
    _types.addAll([
      type('tt-sprint', 'SPRINT_20M', 'Sprint 20 m', 's', false),
      type('tt-jump', 'VERTICAL_JUMP', 'Salto vertical', 'cm', true),
      type(
        'tt-reach',
        'SIT_AND_REACH',
        'Flexibilidad (sit and reach)',
        'cm',
        true,
      ),
    ]);
    // Cut points between the five bands, worst to best, per gender (ages 10 to 12).
    const cuts = {
      'tt-sprint': {
        'MALE': [4.2, 3.9, 3.7, 3.5],
        'FEMALE': [4.4, 4.1, 3.9, 3.7],
      },
      'tt-jump': {
        'MALE': [18.0, 22.0, 27.0, 32.0],
        'FEMALE': [16.0, 20.0, 25.0, 30.0],
      },
      'tt-reach': {
        'MALE': [5.0, 9.0, 13.0, 17.0],
        'FEMALE': [7.0, 11.0, 15.0, 19.0],
      },
    };
    const bands = [
      'POOR',
      'BELOW_AVERAGE',
      'AVERAGE',
      'ABOVE_AVERAGE',
      'EXCELLENT',
    ];
    for (final t in cuts.entries) {
      final higher =
          _types.firstWhere((x) => x['id'] == t.key)['higherIsBetter'] as bool;
      for (final g in t.value.entries) {
        final c = g.value;
        for (var i = 0; i < bands.length; i++) {
          // Band i covers [low, high); the sprint (lower is better) runs the other way round.
          final low = i == 0 ? null : c[i - 1];
          final high = i == 4 ? null : c[i];
          final reversed = !higher;
          _norms.add({
            'id': 'nm-${t.key}-${g.key.toLowerCase()}-$i',
            'testTypeId': t.key,
            'gender': g.key,
            'minAge': 10,
            'maxAge': 12,
            'band': reversed ? bands[4 - i] : bands[i],
            'minValue': low,
            'maxValue': high,
            'source': t.key == 'tt-jump' ? null : 'Referencia demo, 2024',
            'global': true,
            'referencePending': t.key == 'tt-jump',
          });
        }
      }
    }
    void result(
      String id,
      String player,
      String type,
      int daysAgo,
      double value, {
      String? notes,
    }) => _results.add({
      'id': id,
      'playerId': player,
      'testTypeId': type,
      'measuredOn': _dayIn(-daysAgo),
      'value': value,
      'notes': notes,
      'recordedBy': _recorder,
      'recordedAt': _stamp,
    });
    result('tr-1', _a, 'tt-sprint', 120, 4.3);
    result('tr-2', _a, 'tt-sprint', 20, 4.05, notes: 'Pista seca');
    result('tr-3', _a, 'tt-jump', 20, 24.0);
    result('tr-4', _b, 'tt-sprint', 20, 3.95);
    result('tr-5', _b, 'tt-reach', 20, 12.0);
    result('tr-6', _c, 'tt-jump', 20, 21.0);
  }

  // ------------------------------------------------------------------ routing
  /// `/api/athlete/**`; null when the path is not served.
  MockResult? handle({
    required String method,
    required String path,
    required Map<String, dynamic> query,
    Object? body,
  }) {
    final result = _route(method, path, query, body);
    final json = result?.json;
    // Optional properties are absent rather than null on the wire; the generated models read both the same way.
    return json == null
        ? result
        : MockResult.json(result!.status, _withoutNulls(json));
  }

  static Object? _withoutNulls(Object? v) => switch (v) {
    Map<Object?, Object?>() => {
      for (final e in v.entries)
        if (e.value != null) e.key: _withoutNulls(e.value),
    },
    List<Object?>() => [for (final e in v) _withoutNulls(e)],
    _ => v,
  };

  MockResult? _route(
    String method,
    String path,
    Map<String, dynamic> query,
    Object? body,
  ) {
    final seg = path
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList(); // api, athlete, <resource>, ...
    if (seg.length < 3 || seg[0] != 'api' || seg[1] != 'athlete') return null;
    final q = MockQuery(query);
    final b = body is Map ? body.cast<String, Object?>() : <String, Object?>{};
    final id = seg.length > 3 ? seg[3] : null;
    final rest = seg.length > 4 ? seg.sublist(4) : <String>[];
    return switch (seg[2]) {
      'training-schedules' => _schedulesRoute(method, id, q, b),
      'training-sessions' => _sessionsRoute(method, id, rest, q, b),
      'planned-absences' => _absencesRoute(method, id, q, b),
      'training-plans' => _plansRoute(method, id, rest, q, b),
      'plan-assignments' => _assignmentsRoute(method, id, rest, q, b),
      'plan-completions' =>
        method == 'GET' ? q.page(_filterCompletions(q)) : null,
      'injuries' => _injuriesRoute(method, id, q, b),
      'players' when rest.firstOrNull == 'availability' && method == 'GET' =>
        _availability(id!),
      'body-measurements' => _measurementsRoute(method, id, q, b),
      'physical-test-types' => _typesRoute(method, id, b),
      'physical-test-results' => _resultsRoute(method, id, q, b),
      'physical-test-norms' => _normsRoute(method, id, q, b),
      _ => null,
    };
  }

  static const _notFound = MockResult.json(404, {
    'title': 'Not found',
    'status': 404,
    'type': 'urn:hoops:problem:mock',
  });

  Map<String, Object?>? _byId(List<Map<String, Object?>> list, String? id) =>
      list.where((e) => e['id'] == id).firstOrNull;

  static const _forbidden = MockResult.json(403, {
    'title': 'Forbidden',
    'status': 403,
    'type': 'urn:hoops:problem:mock',
  });

  static bool _writes(String method) => method != 'GET';

  /// A team the user may read (404 otherwise) and, for a change, manage (403 otherwise).
  MockResult? _gateTeam(String? team, String method) {
    if (team == null || !_az.canSeeTeam(team)) return _notFound;
    return _writes(method) && !_az.canManageTeam(team) ? _forbidden : null;
  }

  /// A player the user may read (404 otherwise) and, for a change, write for (403 otherwise). [self] lets the
  /// player himself record (planned absences, plan completions); [staffOnly] is for results (guardians read).
  MockResult? _gatePlayer(
    String? player,
    String method, {
    bool self = false,
    bool staffOnly = false,
  }) {
    if (player == null || !_az.canSeePlayer(player)) return _notFound;
    if (!_writes(method)) return null;
    final ok = staffOnly
        ? _az.staff && _az.canWritePlayer(player)
        : (self ? _az.canRecordFor(player) : _az.canWritePlayer(player));
    return ok ? null : _forbidden;
  }

  MockResult? _staffOnly(String method) =>
      _writes(method) && !_az.staff ? _forbidden : null;

  /// Generic update of a stored row: given properties replace, `clear` ones become null.
  MockResult _patch(
    Map<String, Object?> row,
    Map<String, Object?> b,
    Set<String> clearable, [
    Map<String, Object?> Function(Map<String, Object?>)? view,
  ]) {
    final error = mockApplyUpdate(row, b, clearable: clearable);
    return error ?? MockResult.json(200, view == null ? row : view(row));
  }

  // ------------------------------------------------------------------ schedules
  MockResult? _schedulesRoute(
    String method,
    String? id,
    MockQuery q,
    Map<String, Object?> b,
  ) {
    if (id == null) {
      if (method == 'GET') {
        final team = q.text('teamId');
        return MockResult.json(200, [
          for (final s in _schedules)
            if ((team == null || s['teamId'] == team) &&
                _az.canSeeTeam('${s['teamId']}'))
              s,
        ]);
      }
      if (method == 'POST') {
        final denied = _gateTeam(b['teamId'] as String?, method);
        if (denied != null) return denied;
        final s = {
          'id': _id('sch'),
          'location': null,
          'validUntil': null,
          ...b,
        };
        _schedules.add(s);
        return MockResult.json(201, s);
      }
      return null;
    }
    final s = _byId(_schedules, id);
    if (s == null) return _notFound;
    final denied = _gateTeam('${s['teamId']}', method);
    if (denied != null) return denied;
    return switch (method) {
      'GET' => MockResult.json(200, s),
      'PATCH' => _patch(s, b, {'location', 'validUntil'}),
      'DELETE' => () {
        _schedules.remove(s);
        return const MockResult.empty(204);
      }(),
      _ => null,
    };
  }

  // ------------------------------------------------------------------ sessions & attendance
  MockResult? _sessionsRoute(
    String method,
    String? id,
    List<String> rest,
    MockQuery q,
    Map<String, Object?> b,
  ) {
    if (id == null) {
      if (method == 'GET') {
        final team = q.text('teamId');
        final from = q.date('from');
        final to = q.date('to');
        final items = [
          for (final s in _sessions)
            if ((team == null || s['teamId'] == team) &&
                _az.canSeeTeam('${s['teamId']}') &&
                _inRange(
                  _date(_zone.wall(DateTime.parse('${s['startsAt']}'))),
                  from,
                  to,
                ))
              s,
        ]..sort((a, c) => '${a['startsAt']}'.compareTo('${c['startsAt']}'));
        return q.page(items, defaultSize: 200);
      }
      if (method == 'POST') {
        final denied = _gateTeam(b['teamId'] as String?, method);
        if (denied != null) return denied;
        final refused = _refuseOtherSessionsPlan(b['planId'], null);
        if (refused != null) return refused;
        final s = <String, Object?>{
          'id': _id('ses'),
          'scheduleId': null,
          'location': null,
          'planId': null,
          'notes': null,
          'cancelReason': null,
          ...b,
          'status': 'PLANNED',
        };
        _sessions.add(s);
        return MockResult.json(201, s);
      }
      return null;
    }
    final s = _byId(_sessions, id);
    if (s == null) return _notFound;
    final denied = _gateTeam('${s['teamId']}', method);
    if (denied != null) return denied;
    if (rest.isEmpty) {
      if (method == 'GET') return MockResult.json(200, s);
      if (method == 'PATCH') {
        if (s['status'] == 'CANCELLED')
          return mockProblem(409, 'Conflict', code: 'SESSION_CANCELLED');
        final refused = _refuseOtherSessionsPlan(b['planId'], id);
        if (refused != null) return refused;
        final before = s['planId'];
        final result = _patch(s, b, {'location', 'planId', 'notes'});
        if (before != s['planId']) {
          _plans.removeWhere((p) => p['id'] == before && p['sessionId'] == id);
        }
        return result;
      }
      return null;
    }
    if (rest[0] == 'items' && method == 'POST') return _quickAdd(s, b);
    if (rest[0] == 'cancel' && method == 'POST') {
      if (s['status'] == 'CANCELLED')
        return mockProblem(409, 'Conflict', code: 'SESSION_CANCELLED');
      s['status'] = 'CANCELLED';
      s['cancelReason'] = b['reason'];
      return MockResult.json(200, s);
    }
    if (rest[0] == 'attendance') {
      if (!_az.canManageTeam('${s['teamId']}'))
        return _forbidden; // attendance is for staff only
      if (method == 'GET') return MockResult.json(200, _sheet(s));
      if (method == 'PUT') return _record(s, b);
    }
    return null;
  }

  static bool _inRange(String day, String? from, String? to) =>
      (from == null || day.compareTo(from) >= 0) &&
      (to == null || day.compareTo(to) <= 0);

  Map<String, Object?> _sheet(Map<String, Object?> session) {
    final day = _date(_zone.wall(DateTime.parse('${session['startsAt']}')));
    final recorded = _attendance['${session['id']}'] ?? const {};
    return {
      'sessionId': session['id'],
      'entries': [
        for (final p in _roster('${session['teamId']}'))
          () {
            final absence = _absences
                .where(
                  (a) =>
                      a['playerId'] == p &&
                      _inRange(day, '${a['fromDate']}', '${a['toDate']}'),
                )
                .firstOrNull;
            final injury = _injuries
                .where((i) => i['playerId'] == p && i['status'] == 'OPEN')
                .firstOrNull;
            final r = recorded[p];
            return {
              'playerId': p,
              'status': r?['status'],
              'minutesLate': r?['minutesLate'],
              'note': r?['note'],
              'expectedAbsent': absence != null,
              'plannedAbsenceId': absence?['id'],
              'unavailableInjuryId': injury?['id'],
              'recordedBy': r?['recordedBy'],
              'recordedAt': r?['recordedAt'],
            };
          }(),
      ],
    };
  }

  MockResult _record(Map<String, Object?> session, Map<String, Object?> b) {
    final entries = (b['entries'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>();
    final players = _roster('${session['teamId']}');
    for (final e in entries) {
      if (!players.contains(e['playerId']))
        return mockProblem(404, 'Not found');
      final late = e['status'] == 'LATE';
      if (late != (e['minutesLate'] != null))
        return mockProblem(400, 'Bad Request', code: 'MINUTES_LATE');
    }
    final sheet = _attendance.putIfAbsent('${session['id']}', () => {});
    for (final e in entries) {
      sheet['${e['playerId']}'] = {
        'status': e['status'],
        'minutesLate': e['minutesLate'],
        'note': e['note'],
        'recordedBy': _recorder,
        'recordedAt': _stamp,
      };
    }
    return MockResult.json(200, _sheet(session));
  }

  // ------------------------------------------------------------------ planned absences
  MockResult? _absencesRoute(
    String method,
    String? id,
    MockQuery q,
    Map<String, Object?> b,
  ) {
    if (id == null) {
      if (method == 'GET') {
        final player = q.text('playerId');
        final team = q.text('teamId');
        final from = q.date('from');
        final to = q.date('to');
        return q.page([
          for (final a in _absences)
            if (_az.canSeePlayer('${a['playerId']}') &&
                (player == null || a['playerId'] == player) &&
                (team == null || _roster(team).contains(a['playerId'])) &&
                (from == null || '${a['toDate']}'.compareTo(from) >= 0) &&
                (to == null || '${a['fromDate']}'.compareTo(to) <= 0))
              a,
        ], defaultSize: 100);
      }
      if (method == 'POST') {
        final denied = _gatePlayer(
          b['playerId'] as String?,
          method,
          self: true,
        );
        if (denied != null) return denied;
        final a = _absence(
          _id('abs'),
          '${b['playerId']}',
          '${b['fromDate']}',
          '${b['toDate']}',
          b['reason'] as String?,
        );
        _absences.add(a);
        return MockResult.json(201, a);
      }
      return null;
    }
    final a = _byId(_absences, id);
    if (a == null) return _notFound;
    final denied = _gatePlayer('${a['playerId']}', method, self: true);
    if (denied != null) return denied;
    return switch (method) {
      'GET' => MockResult.json(200, a),
      'PATCH' => _patch(a, b, {'reason'}),
      'DELETE' => () {
        _absences.remove(a);
        return const MockResult.empty(204);
      }(),
      _ => null,
    };
  }

  // ------------------------------------------------------------------ plans
  Map<String, Object?> _summary(Map<String, Object?> p) {
    final items = (p['items'] as List<Object?>).cast<Map<String, Object?>>();
    return {
      for (final k in [
        'id',
        'name',
        'description',
        'template',
        'sourceTemplateId',
        'archived',
        'sessionId',
      ])
        k: p[k],
      'itemCount': items.length,
      'totalDurationMinutes': items.fold<int>(
        0,
        (sum, i) => sum + ((i['durationMinutes'] as int?) ?? 0),
      ),
    };
  }

  List<Map<String, Object?>> _matchedItems(
    Map<String, Object?> plan,
    String text,
  ) => [
    for (final i in _items(plan))
      if ('${i['title']}'.toLowerCase().contains(text))
        {'id': i['id'], 'planId': plan['id'], 'title': i['title']},
  ];

  /// Copies of the items a quick-add names (fresh ids), or null when a plan
  /// or item is unknown.
  List<Map<String, Object?>>? _copiesOf(Map<String, Object?> b) {
    final copies = <Map<String, Object?>>[];
    for (final ref
        in (b['items'] as List<Object?>? ?? const [])
            .cast<Map<String, Object?>>()) {
      final source = _byId(_plans, '${ref['planId']}');
      final item = source == null
          ? null
          : _items(source).where((i) => i['id'] == ref['itemId']).firstOrNull;
      if (item == null) return null;
      copies.add({...item, 'id': _id('item')});
    }
    return copies;
  }

  /// A session references any plan except another session's own plan.
  MockResult? _refuseOtherSessionsPlan(Object? planId, String? sessionId) {
    if (planId == null) return null;
    final plan = _byId(_plans, '$planId');
    if (plan == null) return _notFound;
    final owner = plan['sessionId'];
    return owner != null && owner != sessionId
        ? mockProblem(422, 'Unprocessable', code: 'PLAN_OF_ANOTHER_SESSION')
        : null;
  }

  /// Quick-add (ADR-0041): copies go to the session's own plan, created on
  /// first use with the items of the plan the session referenced.
  MockResult _quickAdd(Map<String, Object?> s, Map<String, Object?> b) {
    if (!_az.canManageTeam('${s['teamId']}')) return _forbidden;
    if (s['status'] == 'CANCELLED')
      return mockProblem(409, 'Conflict', code: 'SESSION_CANCELLED');
    final copies = _copiesOf(b);
    if (copies == null) return _notFound;
    final current = _byId(_plans, s['planId'] as String?);
    var own = current != null && current['sessionId'] == s['id']
        ? current
        : null;
    if (own == null) {
      own = {
        'id': _id('plan'),
        'name':
            current?['name'] ??
            'Sesión ${_date(_zone.wall(DateTime.parse('${s['startsAt']}')))}',
        'description': current?['description'],
        'template': false,
        'sourceTemplateId': current?['id'],
        'archived': false,
        'sessionId': s['id'],
        'items': [
          if (current != null)
            for (final i in _items(current)) {...i, 'id': _id('item')},
        ],
      };
      _plans.add(own);
      s['planId'] = own['id'];
    }
    _items(own).addAll(copies);
    _renumber(own);
    return MockResult.json(200, _full(own));
  }

  Map<String, Object?> _full(Map<String, Object?> p) => {
    ..._summary(p),
    'items': p['items'],
  };

  List<Map<String, Object?>> _items(Map<String, Object?> plan) =>
      (plan['items']! as List<Object?>).cast<Map<String, Object?>>();

  void _renumber(Map<String, Object?> plan) {
    var i = 0;
    for (final item in _items(plan)) {
      item['position'] = i++;
    }
  }

  MockResult? _plansRoute(
    String method,
    String? idAndAction,
    List<String> rest,
    MockQuery q,
    Map<String, Object?> b,
  ) {
    final readOnlyRole = _staffOnly(method);
    if (readOnlyRole != null) return readOnlyRole;
    if (idAndAction == null) {
      if (method == 'GET') {
        // athlete 2.3.0: a session's own plan is never listed; `q` matches the
        // name or item titles, the latter reported in `matchedItems`.
        final template = q.text('template');
        final text = q.text('q')?.toLowerCase();
        return q.page([
          for (final p in _plans)
            if (p['archived'] != true &&
                p['sessionId'] == null &&
                (template == null || '${p['template']}' == template))
              if (text == null)
                _summary(p)
              else if (_matchedItems(p, text) case final found
                  when found.isNotEmpty ||
                      '${p['name']}'.toLowerCase().contains(text))
                {..._summary(p), if (found.isNotEmpty) 'matchedItems': found},
        ], defaultSize: 100);
      }
      if (method == 'POST') {
        final plan = <String, Object?>{
          'id': _id('plan'),
          'name': b['name'],
          'description': b['description'],
          'template': false,
          'sourceTemplateId': null,
          'archived': false,
          'items': <Object?>[],
        };
        for (final i
            in (b['items'] as List<Object?>? ?? const [])
                .cast<Map<String, Object?>>()) {
          _items(plan).add(_newItem(i));
        }
        _renumber(plan);
        _plans.add(plan);
        return MockResult.json(201, _full(plan));
      }
      return null;
    }
    final colon = idAndAction.indexOf(':');
    final id = colon < 0 ? idAndAction : idAndAction.substring(0, colon);
    final action = colon < 0 ? null : idAndAction.substring(colon + 1);
    final plan = _byId(_plans, id);
    if (plan == null) return _notFound;
    if (action != null && method == 'POST') {
      switch (action) {
        case 'copy':
          final copy = <String, Object?>{
            ...plan,
            'id': _id('plan'),
            'name': b['name'] ?? plan['name'],
            'template': false,
            'sourceTemplateId': plan['id'],
            'archived': false,
            'items': [
              for (final i in _items(plan)) {...i, 'id': _id('item')},
            ],
          };
          _plans.add(copy);
          return MockResult.json(201, _full(copy));
        case 'archive' || 'unarchive':
          if (plan['template'] == true) return mockProblem(403, 'Forbidden');
          plan['archived'] = action == 'archive';
          return MockResult.json(200, _summary(plan));
      }
      return null;
    }
    final readOnly = plan['template'] == true && method != 'GET';
    if (readOnly)
      return mockProblem(403, 'Forbidden', code: 'TEMPLATE_READ_ONLY');
    if (rest.isEmpty) {
      return switch (method) {
        'GET' => MockResult.json(200, _full(plan)),
        'PATCH' => _patch(plan, b, {'description'}, _full),
        'DELETE' => () {
          _plans.remove(plan);
          _assignments.removeWhere((a) => a['planId'] == id);
          for (final s in _sessions.where((s) => s['planId'] == id)) {
            s['planId'] = null;
          }
          return const MockResult.empty(204);
        }(),
        _ => null,
      };
    }
    if (rest.length == 1 && rest[0] == 'items:copy' && method == 'POST') {
      final copies = _copiesOf(b);
      if (copies == null) return _notFound;
      _items(plan).addAll(copies);
      _renumber(plan);
      return MockResult.json(200, _full(plan));
    }
    if (rest[0] != 'items') return null;
    if (rest.length == 1) {
      if (method == 'POST') {
        final item = _newItem(b);
        _items(plan).add(item);
        _renumber(plan);
        return MockResult.json(201, item);
      }
      if (method == 'PUT') {
        final order = (b['itemIds'] as List<Object?>).map((e) => '$e').toList();
        final byId = {for (final i in _items(plan)) '${i['id']}': i};
        if (order.length != byId.length || !order.every(byId.containsKey))
          return mockProblem(400, 'Bad Request');
        plan['items'] = [for (final i in order) byId[i]];
        _renumber(plan);
        return MockResult.json(200, plan['items']);
      }
      return null;
    }
    final item = _items(plan).where((i) => i['id'] == rest[1]).firstOrNull;
    if (item == null) return _notFound;
    if (method == 'PATCH') {
      return _patch(item, b, {
        'description',
        'durationMinutes',
        'sets',
        'repetitions',
        'videoUrl',
      });
    }
    if (method == 'DELETE') {
      _items(plan).remove(item);
      _renumber(plan);
      return const MockResult.empty(204);
    }
    return null;
  }

  Map<String, Object?> _newItem(Map<String, Object?> input) => {
    'id': _id('item'),
    'position': 0,
    'description': null,
    'durationMinutes': null,
    'sets': null,
    'repetitions': null,
    'videoUrl': null,
    ...input,
  };

  // ------------------------------------------------------------------ assignments & completions
  Map<String, Object?> _assignmentView(Map<String, Object?> a) {
    final plan = _byId(_plans, '${a['planId']}');
    return {
      for (final k in [
        'id',
        'teamId',
        'playerId',
        'dueOn',
        'notes',
        'recordedBy',
        'recordedAt',
      ])
        k: a[k],
      'plan': plan == null ? null : _summary(plan),
    };
  }

  /// A team assignment is visible with its team, a player's with the player.
  bool _assignmentVisible(Map<String, Object?> a) => a['playerId'] != null
      ? _az.canSeePlayer('${a['playerId']}')
      : _az.canSeeTeam('${a['teamId']}');

  Iterable<String> _targets(Map<String, Object?> a) =>
      a['playerId'] != null ? ['${a['playerId']}'] : _roster('${a['teamId']}');

  MockResult? _assignmentsRoute(
    String method,
    String? id,
    List<String> rest,
    MockQuery q,
    Map<String, Object?> b,
  ) {
    if (id == null) {
      if (method == 'GET') {
        final team = q.text('teamId');
        final player = q.text('playerId');
        return q.page([
          for (final a in _assignments)
            if (_assignmentVisible(a) &&
                (team == null ||
                    a['teamId'] == team ||
                    _targets(a).any((p) => _roster(team).contains(p))) &&
                (player == null || _targets(a).contains(player)))
              _assignmentView(a),
        ], defaultSize: 100);
      }
      if (method == 'POST') {
        final plan = _byId(_plans, '${b['planId']}');
        if (plan == null) return mockProblem(404, 'Not found');
        if (plan['archived'] == true)
          return mockProblem(409, 'Conflict', code: 'PLAN_ARCHIVED');
        if (plan['sessionId'] != null)
          return mockProblem(422, 'Unprocessable', code: 'PLAN_OF_A_SESSION');
        if ((b['teamId'] == null) == (b['playerId'] == null))
          return mockProblem(400, 'Bad Request');
        final denied = b['teamId'] != null
            ? _gateTeam(b['teamId'] as String?, method)
            : _gatePlayer(b['playerId'] as String?, method);
        if (denied != null || !_az.staff) return denied ?? _forbidden;
        final a = {
          'id': _id('asg'),
          'teamId': b['teamId'],
          'playerId': b['playerId'],
          'planId': b['planId'],
          'dueOn': b['dueOn'],
          'notes': b['notes'],
          'recordedBy': _recorder,
          'recordedAt': _stamp,
        };
        _assignments.add(a);
        return MockResult.json(201, _assignmentView(a));
      }
      return null;
    }
    final a = _byId(_assignments, id);
    if (a == null || !_assignmentVisible(a)) return _notFound;
    if (rest.isEmpty) {
      if (_writes(method) && !_az.staff) return _forbidden;
      if (method == 'GET') return MockResult.json(200, _assignmentView(a));
      if (method == 'DELETE') {
        _assignments.remove(a);
        _completions.removeWhere((c) => c['assignmentId'] == id);
        return const MockResult.empty(204);
      }
      return null;
    }
    if (rest[0] == 'progress' && method == 'GET')
      return MockResult.json(200, _progress(a));
    if (rest[0] == 'completions' && rest.length == 2 && method == 'PUT') {
      final player = rest[1];
      if (!_targets(a).contains(player)) return mockProblem(404, 'Not found');
      final denied = _gatePlayer(player, method, self: true);
      if (denied != null) return denied;
      final existing = _completions
          .where((c) => c['assignmentId'] == id && c['playerId'] == player)
          .firstOrNull;
      final row =
          existing ??
          {'id': _id('cmp'), 'assignmentId': id, 'playerId': player};
      row
        ..['status'] = b['status']
        ..['comment'] = b['comment']
        ..['recordedBy'] = _recorder
        ..['recordedAt'] = _stamp;
      if (existing == null) _completions.add(row);
      return MockResult.json(200, row);
    }
    return null;
  }

  Map<String, Object?> _progress(Map<String, Object?> a) {
    final targets = _targets(a).where(_az.canSeePlayer).toList();
    final byPlayer = {
      for (final c in _completions.where((c) => c['assignmentId'] == a['id']))
        '${c['playerId']}': c,
    };
    int count(String status) => byPlayer.values
        .where((c) => c['status'] == status && targets.contains(c['playerId']))
        .length;
    return {
      'assignmentId': a['id'],
      'total': targets.length,
      'notRecorded': targets.where((p) => !byPlayer.containsKey(p)).length,
      'counts': {
        'DONE': count('DONE'),
        'PARTIAL': count('PARTIAL'),
        'NOT_DONE': count('NOT_DONE'),
      },
      'players': [
        for (final p in targets)
          {
            'playerId': p,
            'status': byPlayer[p]?['status'],
            'completionId': byPlayer[p]?['id'],
          },
      ],
    };
  }

  List<Map<String, Object?>> _filterCompletions(MockQuery q) {
    final assignment = q.text('assignmentId');
    final player = q.text('playerId');
    return [
      for (final c in _completions)
        if (_az.canSeePlayer('${c['playerId']}') &&
            (assignment == null || c['assignmentId'] == assignment) &&
            (player == null || c['playerId'] == player))
          c,
    ];
  }

  // ------------------------------------------------------------------ injuries & measurements
  MockResult? _injuriesRoute(
    String method,
    String? id,
    MockQuery q,
    Map<String, Object?> b,
  ) {
    if (id == null) {
      if (method == 'GET') {
        final player = q.text('playerId');
        final team = q.text('teamId');
        final status = q.text('status');
        return q.page([
          for (final i in _injuries)
            if (_az.canSeePlayer('${i['playerId']}') &&
                (player == null || i['playerId'] == player) &&
                (team == null || _roster(team).contains(i['playerId'])) &&
                (status == null || i['status'] == status))
              i,
        ], defaultSize: 100);
      }
      if (method == 'POST') {
        final denied = _gatePlayer(b['playerId'] as String?, method);
        if (denied != null) return denied;
        final i = <String, Object?>{
          'id': _id('inj'),
          'description': null,
          'expectedReturnOn': null,
          'actualReturnOn': null,
          'status': 'OPEN',
          'recordedBy': _recorder,
          'recordedAt': _stamp,
          ...b,
        };
        _injuries.add(i);
        return MockResult.json(201, i);
      }
      return null;
    }
    final i = _byId(_injuries, id);
    if (i == null) return _notFound;
    final denied = _gatePlayer('${i['playerId']}', method);
    if (denied != null) return denied;
    return switch (method) {
      'GET' => MockResult.json(200, i),
      'PATCH' => _patch(i, b, {
        'description',
        'expectedReturnOn',
        'actualReturnOn',
      }),
      'DELETE' => () {
        _injuries.remove(i);
        return const MockResult.empty(204);
      }(),
      _ => null,
    };
  }

  MockResult _availability(String player) {
    final denied = _gatePlayer(player, 'GET');
    if (denied != null) return denied;
    final open = _injuries
        .where((i) => i['playerId'] == player && i['status'] == 'OPEN')
        .toList();
    final returns = [
      for (final i in open)
        if (i['expectedReturnOn'] != null) '${i['expectedReturnOn']}',
    ]..sort();
    return MockResult.json(200, {
      'playerId': player,
      'available': open.isEmpty,
      'expectedReturnOn': returns.isEmpty ? null : returns.last,
      'injuries': [for (final i in open) i['id']],
    });
  }

  MockResult? _measurementsRoute(
    String method,
    String? id,
    MockQuery q,
    Map<String, Object?> b,
  ) {
    if (id == null) {
      if (method == 'GET') {
        final player = q.text('playerId');
        final items = [
          for (final m in _measurements)
            if (_az.canSeePlayer('${m['playerId']}') &&
                (player == null || m['playerId'] == player))
              m,
        ]..sort((a, c) => '${c['measuredOn']}'.compareTo('${a['measuredOn']}'));
        return MockResult.json(200, items);
      }
      if (method == 'POST') {
        final denied = _gatePlayer(b['playerId'] as String?, method);
        if (denied != null) return denied;
        if (b['heightCm'] == null && b['weightKg'] == null)
          return mockProblem(400, 'Bad Request');
        final m = <String, Object?>{
          'id': _id('bm'),
          'heightCm': null,
          'weightKg': null,
          'recordedBy': _recorder,
          'recordedAt': _stamp,
          ...b,
        };
        _measurements.add(m);
        return MockResult.json(201, m);
      }
      return null;
    }
    final m = _byId(_measurements, id);
    if (m == null) return _notFound;
    final denied = _gatePlayer('${m['playerId']}', method);
    if (denied != null) return denied;
    return switch (method) {
      'PATCH' => _patch(m, b, {'heightCm', 'weightKg'}),
      'DELETE' => () {
        _measurements.remove(m);
        return const MockResult.empty(204);
      }(),
      _ => null,
    };
  }

  // ------------------------------------------------------------------ physical tests
  MockResult? _typesRoute(String method, String? id, Map<String, Object?> b) {
    if (_writes(method) && !_az.admin) return _forbidden;
    if (id == null) {
      if (method == 'GET') return MockResult.json(200, _types);
      if (method == 'POST') {
        if (_types.any((t) => t['code'] == b['code']))
          return mockProblem(409, 'Conflict', code: 'TEST_CODE_TAKEN');
        final t = <String, Object?>{
          'id': _id('tt'),
          'description': null,
          ...b,
          'global': false,
        };
        _types.add(t);
        return MockResult.json(201, t);
      }
      return null;
    }
    final t = _byId(_types, id);
    if (t == null || (t['global'] == true && method != 'GET')) return _notFound;
    switch (method) {
      case 'GET':
        return MockResult.json(200, t);
      case 'PATCH':
        final code = b['code'];
        if (code != null &&
            _types.any((x) => x['code'] == code && x['id'] != id)) {
          return mockProblem(409, 'Conflict', code: 'TEST_CODE_TAKEN');
        }
        return _patch(t, b, {'description'});
      case 'DELETE':
        if (_results.any((r) => r['testTypeId'] == id)) {
          return mockProblem(409, 'Conflict', code: 'TEST_TYPE_HAS_RESULTS');
        }
        _types.remove(t);
        _norms.removeWhere((n) => n['testTypeId'] == id);
        return const MockResult.empty(204);
    }
    return null;
  }

  int? _ageOn(String player, String measuredOn) {
    final facts = core.playerFacts(player);
    if (facts == null) return null;
    final on = DateTime.parse(measuredOn);
    final birthday = DateTime(facts.birthYear, 4, 12);
    return on.year -
        birthday.year -
        ((on.month * 100 + on.day) < (birthday.month * 100 + birthday.day)
            ? 1
            : 0);
  }

  List<Map<String, Object?>> _effectiveNorms() {
    final tenantKeys = {
      for (final n in _norms.where((n) => n['global'] != true))
        '${n['testTypeId']}/${n['gender']}',
    };
    return [
      for (final n in _norms)
        if (n['global'] != true ||
            !tenantKeys.contains('${n['testTypeId']}/${n['gender']}'))
          n,
    ];
  }

  Map<String, Object?> _resultView(Map<String, Object?> r) {
    final type = _byId(_types, '${r['testTypeId']}');
    final facts = core.playerFacts('${r['playerId']}');
    final age = _ageOn('${r['playerId']}', '${r['measuredOn']}');
    Map<String, Object?>? norm;
    if (facts != null && age != null) {
      final value = (r['value']! as num).toDouble();
      norm = _effectiveNorms().where((n) {
        final min = (n['minValue'] as num?)?.toDouble();
        final max = (n['maxValue'] as num?)?.toDouble();
        return n['testTypeId'] == r['testTypeId'] &&
            n['gender'] == facts.gender &&
            age >= (n['minAge']! as int) &&
            age <= (n['maxAge']! as int) &&
            (min == null || value >= min) &&
            (max == null || value < max);
      }).firstOrNull;
    }
    return {
      for (final k in [
        'id',
        'playerId',
        'testTypeId',
        'measuredOn',
        'value',
        'notes',
        'recordedBy',
        'recordedAt',
      ])
        k: r[k],
      'testCode': type?['code'],
      'unit': type?['unit'],
      'ageAtMeasurement': age,
      'bandStatus': facts == null
          ? 'MISSING_PLAYER_DATA'
          : (norm == null ? 'NO_NORM' : 'MATCHED'),
      'expectedBand': norm?['band'],
      'normId': norm?['id'],
      'referencePending': norm != null && norm['source'] == null,
    };
  }

  MockResult? _resultsRoute(
    String method,
    String? id,
    MockQuery q,
    Map<String, Object?> b,
  ) {
    if (id == null) {
      if (method == 'GET') {
        final player = q.text('playerId');
        final team = q.text('teamId');
        final type = q.text('testTypeId');
        final items = [
          for (final r in _results)
            if (_az.canSeePlayer('${r['playerId']}') &&
                (player == null || r['playerId'] == player) &&
                (team == null || _roster(team).contains(r['playerId'])) &&
                (type == null || r['testTypeId'] == type))
              r,
        ]..sort((a, c) => '${c['measuredOn']}'.compareTo('${a['measuredOn']}'));
        return q.page([
          for (final r in items) _resultView(r),
        ], defaultSize: 200);
      }
      if (method == 'POST') {
        final denied = _gatePlayer(
          b['playerId'] as String?,
          method,
          staffOnly: true,
        );
        if (denied != null) return denied;
        if (_byId(_types, '${b['testTypeId']}') == null)
          return mockProblem(404, 'Not found');
        final r = <String, Object?>{
          'id': _id('tr'),
          'notes': null,
          'recordedBy': _recorder,
          'recordedAt': _stamp,
          ...b,
        };
        _results.add(r);
        return MockResult.json(201, _resultView(r));
      }
      return null;
    }
    final r = _byId(_results, id);
    if (r == null) return _notFound;
    final denied = _gatePlayer('${r['playerId']}', method, staffOnly: true);
    if (denied != null) return denied;
    return switch (method) {
      'GET' => MockResult.json(200, _resultView(r)),
      'PATCH' => _patch(r, b, {'notes'}, _resultView),
      'DELETE' => () {
        _results.remove(r);
        return const MockResult.empty(204);
      }(),
      _ => null,
    };
  }

  MockResult? _normsRoute(
    String method,
    String? id,
    MockQuery q,
    Map<String, Object?> b,
  ) {
    if (_writes(method) && !_az.admin) return _forbidden;
    if (id == null) {
      if (method == 'GET') {
        final scope = q.text('scope') ?? 'EFFECTIVE';
        final type = q.text('testTypeId');
        final gender = q.text('gender');
        final base = switch (scope) {
          'GLOBAL' => _norms.where((n) => n['global'] == true),
          'TENANT' => _norms.where((n) => n['global'] != true),
          _ => _effectiveNorms(),
        };
        return MockResult.json(200, [
          for (final n in base)
            if ((type == null || n['testTypeId'] == type) &&
                (gender == null || n['gender'] == gender))
              n,
        ]);
      }
      if (method == 'POST') return _saveNorm(null, b);
      return null;
    }
    final n = _byId(_norms, id);
    if (n == null || n['global'] == true) return _notFound;
    if (method == 'PUT') return _saveNorm(n, b);
    if (method == 'DELETE') {
      _norms.remove(n);
      return const MockResult.empty(204);
    }
    return null;
  }

  MockResult _saveNorm(Map<String, Object?>? existing, Map<String, Object?> b) {
    if (_byId(_types, '${b['testTypeId']}') == null)
      return mockProblem(404, 'Not found');
    final clash = _norms.any(
      (n) =>
          n['global'] != true &&
          n['id'] != existing?['id'] &&
          n['testTypeId'] == b['testTypeId'] &&
          n['gender'] == b['gender'] &&
          n['band'] == b['band'] &&
          (n['minAge']! as int) <= (b['maxAge']! as int) &&
          (b['minAge']! as int) <= (n['maxAge']! as int),
    );
    if (clash) return mockProblem(409, 'Conflict', code: 'NORM_OVERLAP');
    final row = <String, Object?>{
      'id': existing?['id'] ?? _id('nm'),
      'minValue': null,
      'maxValue': null,
      'source': null,
      ...b,
      'global': false,
    };
    row['referencePending'] = row['source'] == null;
    if (existing == null) {
      _norms.add(row);
    } else {
      _norms[_norms.indexOf(existing)] = row;
    }
    return MockResult.json(existing == null ? 201 : 200, row);
  }
}
