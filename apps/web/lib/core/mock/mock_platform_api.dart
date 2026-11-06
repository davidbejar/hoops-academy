import 'mock_core_api.dart';
import 'mock_query.dart';

/// In-memory stand-in for core-service's `/platform/**` (super admin console), dev mock mode only.
/// Tenants and their lifecycle, administrators, usage with a few months of history and the audit list of every
/// academy, with the platform actor shown unmasked like the server does for the super admin.
class MockPlatformApi {
  MockPlatformApi({required this.tenantAId, required this.tenantBId, DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _seed();
  }

  final String tenantAId;
  final String tenantBId;
  final DateTime Function() _now;

  static const suspendedTenantId = '33333333-3333-4333-8333-333333333333';
  static const superAdminSubject = 'mock-super-admin';

  final List<Map<String, Object?>> _tenants = [];
  final Map<String, List<Map<String, Object?>>> _admins = {};
  final List<Map<String, Object?>> _audit = [];
  var _seq = 100;

  String _id(String prefix) => '$prefix-${_seq++}';
  String get _stamp => _now().toUtc().toIso8601String();
  String _password() => 'MockPass${(_seq++).toString().padLeft(4, '0')}xY';

  void _seed() {
    final now = _now().toUtc();
    Map<String, Object?> tenant(
      String id,
      String slug,
      String name,
      String status,
      String zone,
      String locale,
      int ageDays,
    ) => {
      'id': id,
      'slug': slug,
      'name': name,
      'status': status,
      'timezone': zone,
      'defaultLocale': locale,
      'createdAt': now.subtract(Duration(days: ageDays)).toIso8601String(),
      'suspendedAt': status == 'SUSPENDED' ? now.subtract(const Duration(days: 9)).toIso8601String() : null,
      'withdrawnAt': null,
      'retainUntil': null,
    };
    _tenants.addAll([
      tenant(tenantAId, 'demo', 'Academia Demo', 'ACTIVE', 'Europe/Madrid', 'es', 150),
      tenant(tenantBId, 'norte', 'Club Norte', 'ACTIVE', 'Europe/Madrid', 'en', 100),
      tenant(suspendedTenantId, 'sur', 'Academia Sur', 'SUSPENDED', 'Asia/Jakarta', 'id', 60),
    ]);
    _admins[tenantAId] = [
      _admin('m-ana', 'Alicia', 'Admin', 'alicia@demo.example', 'ACCEPTED', 'NONE', ['COACH']),
      _admin('m-new', 'Bruno', 'Nuevo', 'bruno@demo.example', 'PENDING', 'ACTIVE', []),
    ];
    _admins[tenantBId] = [_admin('n-1', 'Nora', 'Norte', 'nora@norte.example', 'ACCEPTED', 'NONE', [])];
    _admins[suspendedTenantId] = [_admin('s-1', 'Sari', 'Surya', 'sari@sur.example', 'PENDING', 'EXPIRED', [])];

    Map<String, Object?> event(
      int hoursAgo,
      String tenantId,
      String action,
      Map<String, Object?> actor,
      Map<String, Object?> target,
    ) {
      final name = _tenants.firstWhere((t) => t['id'] == tenantId)['name'];
      return {
        'id': '00000000-0000-4000-8000-${(700 + _audit.length).toString().padLeft(12, '0')}',
        'at': now.subtract(Duration(hours: hoursAgo)).toIso8601String(),
        'action': action,
        'actor': actor,
        'target': target,
        'metadata': <String, Object?>{},
        'tenantId': tenantId,
        'tenantName': name,
      };
    }

    const platform = {'kind': 'PLATFORM', 'subject': superAdminSubject, 'personId': null, 'displayName': null};
    const system = {'kind': 'SYSTEM', 'subject': 'system', 'personId': null, 'displayName': null};
    Map<String, Object?> person(String id, String name) => {
      'kind': 'PERSON',
      'subject': 'sub-$id',
      'personId': id,
      'displayName': name,
    };
    Map<String, Object?> tenantTarget(String id) => {
      'type': 'tenant',
      'id': id,
      'displayName': _tenants.firstWhere((t) => t['id'] == id)['name'],
    };
    Map<String, Object?> personTarget(String id, String? name) => {'type': 'person', 'id': id, 'displayName': name};

    _audit.addAll([
      event(2, tenantAId, 'member.invited', person('m-ana', 'Alicia Admin'), personTarget('m-pat', null)),
      event(30, suspendedTenantId, 'tenant.suspended', platform, tenantTarget(suspendedTenantId)),
      event(50, tenantAId, 'admin.added', platform, personTarget('m-new', 'Bruno Nuevo')),
      event(70, tenantBId, 'tenant.profile_changed', person('n-1', 'Nora Norte'), tenantTarget(tenantBId)),
      event(26 * 24, tenantAId, 'member.temporary_password_expired', system, personTarget('m-pat', null)),
      event(40 * 24, suspendedTenantId, 'admin.temporary_password_issued', platform, personTarget('s-1', 'Sari Surya')),
      event(60 * 24, suspendedTenantId, 'tenant.created', platform, tenantTarget(suspendedTenantId)),
      event(100 * 24, tenantBId, 'tenant.created', platform, tenantTarget(tenantBId)),
      event(150 * 24, tenantAId, 'tenant.created', platform, tenantTarget(tenantAId)),
    ]);
    _audit.sort((a, b) => (b['at']! as String).compareTo(a['at']! as String));
  }

  Map<String, Object?> _admin(
    String id,
    String given,
    String family,
    String email,
    String invitation,
    String password,
    List<String> other,
  ) => {
    'personId': id,
    'givenName': given,
    'familyName': family,
    'email': email,
    'invitationStatus': invitation,
    'temporaryPasswordStatus': password,
    'otherRoles': other,
  };

  Map<String, Object?>? _find(String id) => _tenants.where((t) => t['id'] == id).firstOrNull;

  Map<String, Object?> _record(String action, Map<String, Object?> tenant, Map<String, Object?> target) {
    final e = {
      'id': '00000000-0000-4000-8000-${(700 + _seq++).toString().padLeft(12, '0')}',
      'at': _stamp,
      'action': action,
      'actor': {'kind': 'PLATFORM', 'subject': superAdminSubject, 'personId': null, 'displayName': null},
      'target': target,
      'metadata': <String, Object?>{},
      'tenantId': tenant['id'],
      'tenantName': tenant['name'],
    };
    _audit.insert(0, e);
    return e;
  }

  Map<String, Object?> _tenantTarget(Map<String, Object?> t) => {
    'type': 'tenant',
    'id': t['id'],
    'displayName': t['name'],
  };

  /// `/platform/**`; null when the path is not served.
  MockResult? handle({
    required String method,
    required String path,
    required Map<String, dynamic> query,
    Object? body,
  }) {
    final seg = path.split('/').where((s) => s.isNotEmpty).toList(); // platform, tenants, {id}, ...
    if (seg.isEmpty || seg[0] != 'platform' || seg.length < 2) return null;
    final q = MockQuery(query);
    final b = body is Map ? body.cast<String, Object?>() : <String, Object?>{};

    if (seg[1] == 'audit-events' && method == 'GET') return _auditList(q);
    if (seg[1] != 'tenants') return null;
    if (seg.length == 2) {
      if (method == 'GET') return _list(q);
      if (method == 'POST') return _create(b);
      return null;
    }
    final tenant = _find(seg[2]);
    if (tenant == null) return mockProblem(404, 'Not found');
    final rest = seg.sublist(3);
    return switch ((method, rest)) {
      ('GET', []) => MockResult.json(200, tenant),
      ('PATCH', []) => _update(tenant, b),
      ('POST', ['suspend']) => _lifecycle(tenant, 'SUSPENDED', 'tenant.suspended', b),
      ('POST', ['withdraw']) => _lifecycle(tenant, 'WITHDRAWN', 'tenant.withdrawn', b),
      ('POST', ['reactivate']) => _lifecycle(tenant, 'ACTIVE', 'tenant.reactivated', b),
      ('GET', ['usage']) => MockResult.json(200, _usage(tenant)),
      ('GET', ['usage', 'history']) => MockResult.json(200, _history(tenant)),
      (_, ['admins', ...]) => _adminRoute(tenant, method, rest.sublist(1), q, b),
      _ => null,
    };
  }

  MockResult _list(MockQuery q) {
    final status = q.text('status');
    final text = q.text('q')?.toLowerCase();
    final items = [
      for (final t in _tenants)
        if ((status == null || t['status'] == status) &&
            (text == null || '${t['name']}'.toLowerCase().contains(text) || '${t['slug']}'.contains(text)))
          t,
    ];
    return q.page(items, defaultSize: 100);
  }

  MockResult _create(Map<String, Object?> b) {
    final slug = '${b['slug']}';
    if (_tenants.any((t) => t['slug'] == slug)) return mockProblem(409, 'Conflict', code: 'SLUG_TAKEN');
    final first = (b['firstAdmin'] as Map).cast<String, Object?>();
    final id = '00000000-0000-4000-8000-${(5000 + _seq++).toString().padLeft(12, '0')}';
    final tenant = <String, Object?>{
      'id': id,
      'slug': slug,
      'name': b['name'],
      'status': 'ACTIVE',
      'timezone': b['timezone'],
      'defaultLocale': b['defaultLocale'],
      'createdAt': _stamp,
      'suspendedAt': null,
      'withdrawnAt': null,
      'retainUntil': null,
    };
    _tenants.add(tenant);
    _admins[id] = [
      _admin(
        _id('adm'),
        '${first['givenName']}',
        '${first['familyName']}',
        '${first['email']}',
        'PENDING',
        'ACTIVE',
        [],
      ),
    ];
    _record('tenant.created', tenant, _tenantTarget(tenant));
    return MockResult.json(201, {...tenant, 'temporaryPassword': _password()});
  }

  MockResult _update(Map<String, Object?> tenant, Map<String, Object?> b) {
    for (final k in ['name', 'timezone', 'defaultLocale']) {
      if (b[k] != null) tenant[k] = b[k];
    }
    return MockResult.json(200, tenant);
  }

  MockResult _lifecycle(Map<String, Object?> tenant, String status, String action, Map<String, Object?> b) {
    if (status != 'ACTIVE' && '${b['reason'] ?? ''}'.isEmpty) return mockProblem(400, 'Bad Request');
    final now = _now().toUtc();
    tenant['status'] = status;
    tenant['suspendedAt'] = status == 'SUSPENDED' ? now.toIso8601String() : null;
    tenant['withdrawnAt'] = status == 'WITHDRAWN' ? now.toIso8601String() : null;
    tenant['retainUntil'] = status == 'WITHDRAWN'
        ? now.add(const Duration(days: 365)).toIso8601String().substring(0, 10)
        : null;
    _record(action, tenant, _tenantTarget(tenant));
    return MockResult.json(200, tenant);
  }

  // ------------------------------------------------------------------ administrators
  MockResult? _adminRoute(
    Map<String, Object?> tenant,
    String method,
    List<String> rest,
    MockQuery q,
    Map<String, Object?> b,
  ) {
    if (tenant['status'] == 'WITHDRAWN') return mockProblem(409, 'Conflict', code: 'TENANT_WITHDRAWN');
    final admins = _admins.putIfAbsent('${tenant['id']}', () => []);
    if (rest.isEmpty) {
      if (method == 'GET') return q.page(admins, defaultSize: 100);
      if (method == 'POST') {
        final email = '${b['email']}';
        if (admins.any((a) => a['email'] == email)) return mockProblem(409, 'Conflict', code: 'ALREADY_ADMIN');
        final a = _admin(_id('adm'), '${b['givenName']}', '${b['familyName']}', email, 'PENDING', 'ACTIVE', []);
        admins.add(a);
        _record('admin.added', tenant, {
          'type': 'person',
          'id': a['personId'],
          'displayName': '${a['givenName']} ${a['familyName']}',
        });
        return MockResult.json(201, {...a, 'temporaryPassword': _password()});
      }
      return null;
    }
    final admin = admins.where((a) => a['personId'] == rest[0]).firstOrNull;
    if (admin == null) return mockProblem(404, 'Not found');
    final target = {
      'type': 'person',
      'id': admin['personId'],
      'displayName': '${admin['givenName']} ${admin['familyName']}',
    };
    if (rest.length == 1) {
      if (method == 'PATCH') {
        for (final k in ['givenName', 'familyName', 'email']) {
          if (b[k] != null) admin[k] = b[k];
        }
        _record('admin.updated', tenant, target);
        return MockResult.json(200, admin);
      }
      if (method == 'DELETE') {
        admins.remove(admin);
        _record('admin.removed', tenant, target);
        return const MockResult.empty(204);
      }
    }
    if (rest.length == 2 && method == 'POST' && (rest[1] == 'temporary-password' || rest[1] == 'resend-invitation')) {
      if (admin['invitationStatus'] != 'PENDING') return mockProblem(409, 'Conflict', code: 'INVITATION_NOT_PENDING');
      admin['temporaryPasswordStatus'] = 'ACTIVE';
      _record('admin.temporary_password_issued', tenant, target);
      return MockResult.json(200, {...admin, 'temporaryPassword': _password()});
    }
    return null;
  }

  // ------------------------------------------------------------------ usage
  Map<String, Object?> _report(String tenantId, String service, DateTime at, double scale) {
    int n(num base) => (base * scale).round();
    final counters = switch (service) {
      'core' => {
        'members': n(14),
        'membersAdmin': 2,
        'membersCoach': n(4),
        'players': n(42),
        'activePlayers': n(38),
        'teams': n(5),
        'seasons': 2,
      },
      'game' => {
        'matches': n(24),
        'liveMatches': 0,
        'finishedMatches': n(20),
        'matchEvents': n(3100),
        'matchEventsLast30Days': n(900),
      },
      _ => {
        'trainingSchedules': n(6),
        'trainingSessions': n(120),
        'attendanceRecords': n(1500),
        'trainingPlans': n(9),
        'physicalTestResults': n(60),
        'injuries': n(7),
      },
    };
    return {
      'tenantId': tenantId,
      'service': service,
      'collectedAt': at.toIso8601String(),
      'lastActivityAt': at.subtract(const Duration(hours: 3)).toIso8601String(),
      'counters': counters,
    };
  }

  Map<String, Object?> _usage(Map<String, Object?> tenant) {
    final now = _now().toUtc();
    final id = '${tenant['id']}';
    return {
      'tenantId': id,
      'collectedAt': now.toIso8601String(),
      'services': [
        for (final s in ['core', 'game', 'athlete']) _report(id, s, now, id == tenantAId ? 1 : 0.4),
      ],
      'unavailableServices': <String>[],
    };
  }

  Map<String, Object?> _history(Map<String, Object?> tenant) {
    final now = _now().toUtc();
    final id = '${tenant['id']}';
    // About four months, one snapshot every 3 to 4 weeks; the second one is partial (the game service was down).
    final daysAgo = [120, 91, 62, 35, 14, 0];
    String day(DateTime d) => d.toIso8601String().substring(0, 10);
    final snapshots = [
      for (var i = 0; i < daysAgo.length; i++)
        () {
          final at = now.subtract(Duration(days: daysAgo[i]));
          final partial = i == 1;
          return {
            'date': day(at),
            'collectedAt': at.toIso8601String(),
            'services': [
              for (final s in ['core', 'game', 'athlete'])
                if (!(partial && s == 'game')) _report(id, s, at, (0.3 + i * 0.14) * (id == tenantAId ? 1 : 0.4)),
            ],
            'unavailableServices': partial ? ['game'] : <String>[],
          };
        }(),
    ];
    return {'tenantId': id, 'from': snapshots.first['date'], 'to': snapshots.last['date'], 'snapshots': snapshots};
  }

  // ------------------------------------------------------------------ audit
  MockResult _auditList(MockQuery q) {
    final tenantId = q.text('tenantId');
    if (tenantId != null && _find(tenantId) == null) return mockProblem(404, 'Not found');
    final from = q.instant('from');
    final to = q.instant('to');
    if (from != null && to != null && !from.isBefore(to)) return mockProblem(400, 'Bad Request');
    final actions = q.set('action');
    final items = [
      for (final e in _audit)
        if ((tenantId == null || e['tenantId'] == tenantId) &&
            (actions.isEmpty || actions.contains(e['action'])) &&
            (from == null || !DateTime.parse('${e['at']}').isBefore(from)) &&
            (to == null || DateTime.parse('${e['at']}').isBefore(to)))
          e,
    ];
    return q.page(items, defaultSize: 50);
  }
}
