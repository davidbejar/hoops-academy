import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/match/data/mock_game_api.dart';
import '../mock/mock_athlete_api.dart';
import '../mock/mock_core_api.dart';
import '../mock/mock_platform_api.dart';
import '../mock/mock_state_log.dart';
import '../mock/mock_store.dart';
import '../storage/preferences.dart';

const mockTenantAId = '11111111-1111-4111-8111-111111111111';
const mockTenantBId = '22222222-2222-4222-8222-222222222222';

// 16x16 solid teal PNG, stands in for an uploaded academy logo.
final _logoPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAFklEQVR4nGPgLmolCTGMahjVMHw1AACwJgIQC/cFwQAAAABJRU5ErkJggg==',
);

/// The one demo backend of the running app, backed by the browser storage so the demo survives a reload.
final Provider<MockApiAdapter> mockApiAdapterProvider =
    Provider<MockApiAdapter>(
      (ref) => MockApiAdapter(
        store: PrefsMockStore(ref.watch(sharedPreferencesProvider)),
      ),
    );

/// In-memory stand-in for core-service (`--dart-define=HOOPS_MOCK_API=true`).
///
/// Serves `/api/core/**` (me, tenant, admin and roster), `/api/game/**`,
/// `/api/athlete/**` for both demo academies (each with its own roster, shared by the three mocks, and the demo
/// user's roles there: [roles] in Academia Demo, PARENT in Club Norte) and `/platform/**` (super admin
/// only), and enforces the same header contract as the
/// real service (bearer on everything, `X-Tenant-Id` on tenant paths), so the
/// shell's interceptors are exercised even without a backend.
class MockApiAdapter implements HttpClientAdapter {
  /// [roles] are the demo user's roles in Academia Demo, [norteRoles] in Club Norte. Unset, both come from
  /// `HOOPS_MOCK_ROLES` when it is defined; without it Academia Demo is ADMIN + COACH and Club Norte PARENT.
  /// What the user changes is replayed from [store] (default: nothing survives the adapter).
  MockApiAdapter({
    List<String>? roles,
    List<String>? norteRoles,
    bool? superAdmin,
    MockStore? store,
  }) : _roles = roles ?? _rolesFromEnvironment() ?? const ['ADMIN', 'COACH'],
       _norteRoles = norteRoles ?? _rolesFromEnvironment() ?? const ['PARENT'],
       _superAdmin = superAdmin ?? _superAdminFromEnvironment(),
       _store = store ?? MemoryMockStore() {
    _build();
  }

  void _build() {
    _platform = MockPlatformApi(
      tenantAId: mockTenantAId,
      tenantBId: mockTenantBId,
    );
    _platformLog = MockStateLog(_store, '${mockStorePrefix}v1.platform');
    _platformLog.replay(
      (e) => _platform.handle(
        method: e.method,
        path: e.path,
        query: e.query,
        body: e.body,
      ),
    );
    _academies = {
      mockTenantAId: _Academy(
        MockCoreApi(initialLogo: _logoPng, roles: _roles),
        MockStateLog(_store, _logKey(mockTenantAId, _roles)),
      ),
      mockTenantBId: _Academy(
        MockCoreApi(academy: MockAcademy.norte, roles: _norteRoles),
        MockStateLog(_store, _logKey(mockTenantBId, _norteRoles)),
      ),
    };
  }

  static String _logKey(String tenantId, List<String> roles) =>
      '${mockStorePrefix}v1.$tenantId.${roles.join(',')}';

  /// Forgets what the user changed, here and in the store: the next request sees the seed again.
  Future<void> reset() async {
    await _store.clearAll();
    _build();
  }

  /// `--dart-define=HOOPS_MOCK_ROLES=COACH` (comma separated) switches the
  /// demo user's roles in every academy to try the role variants.
  static List<String>? _rolesFromEnvironment() {
    final roles = const String.fromEnvironment('HOOPS_MOCK_ROLES')
        .split(',')
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .toList();
    return roles.isEmpty ? null : roles;
  }

  /// `--dart-define=HOOPS_MOCK_SUPER_ADMIN=false` turns the demo user into a plain member (default: a super admin,
  /// so the demo reaches the platform console from the profile menu).
  static bool _superAdminFromEnvironment() =>
      const bool.fromEnvironment('HOOPS_MOCK_SUPER_ADMIN', defaultValue: true);

  final List<String> _roles;
  final List<String> _norteRoles;
  final bool _superAdmin;
  final MockStore _store;
  late Map<String, _Academy> _academies;
  late MockPlatformApi _platform;
  late MockStateLog _platformLog;
  String _locale = 'es';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final path = options.path;
    final method = options.method.toUpperCase();

    if (!(options.headers['Authorization'] as String? ?? '').startsWith(
      'Bearer ',
    )) {
      return _problem(401, 'Unauthorized');
    }

    if (path == '/api/core/me') {
      if (method == 'PATCH') {
        final body = options.data;
        final decoded = body is String ? jsonDecode(body) : body;
        if (decoded is Map && decoded['locale'] is String) {
          _locale = decoded['locale'] as String;
        }
      }
      return _json(_me());
    }

    if (path.startsWith('/platform/')) {
      if (!_superAdmin) return _problem(403, 'Forbidden');
      final data = options.data;
      final body = data is String && data.isNotEmpty ? jsonDecode(data) : data;
      final result = _platform.handle(
        method: method,
        path: path,
        query: options.queryParameters,
        body: body,
      );
      _platformLog.record(method, path, options.queryParameters, body, result);
      return _result(
        result ??
            const MockResult.json(404, {'title': 'Not found', 'status': 404}),
      );
    }

    final tenant = options.headers['X-Tenant-Id'] as String?;
    final isTenantPath =
        path.startsWith('/api/athlete/') ||
        path.startsWith('/api/game/') ||
        path.startsWith('/api/core/');
    if (!isTenantPath) return _problem(404, 'Not found');
    final academy = _academies[tenant];
    if (academy == null) {
      return _problem(
        tenant == null ? 400 : 404,
        tenant == null ? 'X-Tenant-Id is required' : 'Not found',
      );
    }
    Uint8List? bytes;
    if (requestStream != null) {
      final chunks = <int>[];
      await for (final c in requestStream) {
        chunks.addAll(c);
      }
      bytes = Uint8List.fromList(chunks);
    }
    final data = options.data;
    final body = data is String && data.isNotEmpty ? jsonDecode(data) : data;
    final result = academy.handle(
      tenant!,
      MockRequest(method, path, options.queryParameters, body, bytes),
    );
    if (result == null) return _problem(404, 'Not found');
    if (path.startsWith('/api/core/')) {
      if (result.status == 304) return ResponseBody.fromString('', 304);
      return ResponseBody.fromBytes(
        MockCoreApi.encode(result),
        result.status,
        headers: {
          Headers.contentTypeHeader: [
            result.status >= 400
                ? 'application/problem+json'
                : result.contentType,
          ],
          for (final e in result.headers.entries) e.key: [e.value],
        },
      );
    }
    return _result(result);
  }

  ResponseBody _result(MockResult result) => ResponseBody.fromBytes(
    MockCoreApi.encode(result),
    result.status,
    headers: {
      Headers.contentTypeHeader: [
        result.status >= 400 ? 'application/problem+json' : result.contentType,
      ],
    },
  );

  Map<String, Object?> _me() => {
    'userId': '00000000-0000-4000-8000-000000000001',
    'sub': 'mock-sub',
    'email': 'coach1@hoops-academy.com',
    'displayName': 'Casey Coach',
    'locale': _locale,
    'superAdmin': _superAdmin,
    'memberships': [
      _membership(mockTenantAId, 'demo', 'Academia Demo', true, _roles),
      _membership(mockTenantBId, 'norte', 'Club Norte', false, _norteRoles),
    ],
  };

  Map<String, Object?> _membership(
    String id,
    String slug,
    String name,
    bool hasLogo,
    List<String> roles,
  ) => {
    'tenant': {
      'id': id,
      'slug': slug,
      'name': name,
      'status': 'ACTIVE',
      'hasLogo': hasLogo,
    },
    'personId': 'a1',
    'roles': roles,
    'authz': {
      'staffTeamIds': _academies[id]!.core.authz.staffTeamIds.toList(),
      'linkedPlayerIds': _academies[id]!.core.authz.linkedPlayerIds.toList(),
      'playerTeamIds': _academies[id]!.core.authz.playerTeamIds.toList(),
      'timezone': 'Europe/Madrid',
    },
  };

  ResponseBody _json(Object body) => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  ResponseBody _problem(int status, String title) => ResponseBody.fromString(
    jsonEncode({
      'type': 'urn:hoops:problem:mock',
      'title': title,
      'status': status,
    }),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/problem+json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// One demo academy: its core data and the athlete and game mocks reading the same roster. Every change that
/// succeeded is appended to [log], which a new instance replays to get back to the same state.
class _Academy {
  _Academy(this.core, this.log)
    : athlete = MockAthleteApi(core: core),
      game = MockGameApi(core: core) {
    log.replay((e) => handleUnlogged(e));
  }

  final MockCoreApi core;
  final MockAthleteApi athlete;
  final MockGameApi game;
  final MockStateLog log;

  MockResult? handle(String tenantId, MockRequest r) {
    final result = handleUnlogged(r, tenantId: tenantId);
    log.record(r.method, r.path, r.query, r.body, result, bytes: r.bytes);
    return result;
  }

  MockResult? handleUnlogged(MockRequest r, {String tenantId = mockTenantAId}) {
    if (r.path.startsWith('/api/athlete/')) {
      return athlete.handle(
            method: r.method,
            path: r.path,
            query: r.query,
            body: r.body,
          ) ??
          const MockResult.json(404, {'title': 'Not found', 'status': 404});
    }
    if (r.path.startsWith('/api/game/')) {
      return game.handle(
        method: r.method,
        path: r.path,
        query: r.query,
        body: r.body,
      );
    }
    if (r.path.startsWith('/api/core/')) {
      return core.handle(
        tenantId: tenantId,
        method: r.method,
        path: r.path,
        query: r.query,
        body: r.body,
        bytes: r.bytes,
      );
    }
    return null;
  }
}
