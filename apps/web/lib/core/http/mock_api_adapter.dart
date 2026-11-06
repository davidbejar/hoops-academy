import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../features/match/data/mock_game_api.dart';
import '../mock/mock_athlete_api.dart';
import '../mock/mock_core_api.dart';
import '../mock/mock_platform_api.dart';

const mockTenantAId = '11111111-1111-4111-8111-111111111111';
const mockTenantBId = '22222222-2222-4222-8222-222222222222';

// 16x16 solid teal PNG, stands in for an uploaded academy logo.
final _logoPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAFklEQVR4nGPgLmolCTGMahjVMHw1AACwJgIQC/cFwQAAAABJRU5ErkJggg==',
);

/// In-memory stand-in for core-service (`--dart-define=HOOPS_MOCK_API=true`).
///
/// Serves `/api/core/**` (me, tenant, admin and roster), `/api/game/**`,
/// `/api/athlete/**` (demo academy only) and `/platform/**` (super admin
/// only), and enforces the same header contract as the
/// real service (bearer on everything, `X-Tenant-Id` on tenant paths), so the
/// shell's interceptors are exercised even without a backend.
class MockApiAdapter implements HttpClientAdapter {
  MockApiAdapter({List<String>? roles, bool? superAdmin})
    : _roles = roles ?? _rolesFromEnvironment(),
      _superAdmin = superAdmin ?? _superAdminFromEnvironment(),
      _core = MockCoreApi(initialLogo: _logoPng, roles: roles ?? _rolesFromEnvironment()),
      _game = MockGameApi(roles: roles ?? _rolesFromEnvironment()),
      _athlete = MockAthleteApi(),
      _platform = MockPlatformApi(tenantAId: mockTenantAId, tenantBId: mockTenantBId);

  /// `--dart-define=HOOPS_MOCK_ROLES=COACH` (comma separated) switches the
  /// demo user's roles in the first academy to try the role variants.
  static List<String> _rolesFromEnvironment() => const String.fromEnvironment(
    'HOOPS_MOCK_ROLES',
    defaultValue: 'ADMIN,COACH',
  ).split(',').map((r) => r.trim()).where((r) => r.isNotEmpty).toList();

  /// `--dart-define=HOOPS_MOCK_SUPER_ADMIN=false` turns the demo user into a plain member (default: a super admin,
  /// so the demo reaches the platform console from the profile menu).
  static bool _superAdminFromEnvironment() => const bool.fromEnvironment('HOOPS_MOCK_SUPER_ADMIN', defaultValue: true);

  final List<String> _roles;
  final bool _superAdmin;
  final MockCoreApi _core;
  final MockGameApi _game;
  final MockAthleteApi _athlete;
  final MockPlatformApi _platform;
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
      final result = _platform.handle(
        method: method,
        path: path,
        query: options.queryParameters,
        body: data is String && data.isNotEmpty ? jsonDecode(data) : data,
      );
      return _result(result ?? const MockResult.json(404, {'title': 'Not found', 'status': 404}));
    }

    final tenant = options.headers['X-Tenant-Id'] as String?;
    if (path.startsWith('/api/athlete/')) {
      if (tenant != mockTenantAId) {
        return _problem(tenant == null ? 400 : 404, tenant == null ? 'X-Tenant-Id is required' : 'Not found');
      }
      final data = options.data;
      final result = _athlete.handle(
        method: method,
        path: path,
        query: options.queryParameters,
        body: data is String && data.isNotEmpty ? jsonDecode(data) : data,
      );
      return _result(result ?? const MockResult.json(404, {'title': 'Not found', 'status': 404}));
    }
    if (path.startsWith('/api/game/')) {
      if (tenant != mockTenantAId) {
        return _problem(tenant == null ? 400 : 404, tenant == null ? 'X-Tenant-Id is required' : 'Not found');
      }
      final data = options.data;
      final result = _game.handle(
        method: method,
        path: path,
        query: options.queryParameters,
        body: data is String && data.isNotEmpty ? jsonDecode(data) : data,
      );
      if (result != null) {
        return ResponseBody.fromBytes(
          MockCoreApi.encode(result),
          result.status,
          headers: {
            Headers.contentTypeHeader: [result.status >= 400 ? 'application/problem+json' : 'application/json'],
          },
        );
      }
    }
    if (path.startsWith('/api/core/')) {
      if (tenant != mockTenantAId && tenant != mockTenantBId) {
        return _problem(
          tenant == null ? 400 : 404,
          tenant == null ? 'X-Tenant-Id is required' : 'Not found',
        );
      }
      if (tenant == mockTenantBId) {
        // The second academy only has a PARENT membership and no data.
        if (path == '/api/core/tenant') return _json(_profile(tenant!));
        return path == '/api/core/tenant/logo'
            ? _problem(404, 'No logo')
            : _problem(403, 'Forbidden');
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
      final result = _core.handle(
        tenantId: tenant!,
        method: method,
        path: path,
        query: options.queryParameters,
        body: body,
        bytes: bytes,
      );
      if (result != null) {
        if (result.status == 304) {
          return ResponseBody.fromString('', 304);
        }
        final isError = result.status >= 400;
        return ResponseBody.fromBytes(
          MockCoreApi.encode(result),
          result.status,
          headers: {
            Headers.contentTypeHeader: [
              isError ? 'application/problem+json' : result.contentType,
            ],
            for (final e in result.headers.entries) e.key: [e.value],
          },
        );
      }
    }
    return _problem(404, 'Not found');
  }

  ResponseBody _result(MockResult result) => ResponseBody.fromBytes(
    MockCoreApi.encode(result),
    result.status,
    headers: {
      Headers.contentTypeHeader: [result.status >= 400 ? 'application/problem+json' : result.contentType],
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
      _membership(mockTenantBId, 'norte', 'Club Norte', false, ['PARENT']),
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
      'staffTeamIds': roles.contains('COACH') || roles.contains('ASSISTANT_COACH')
          ? <String>[MockCoreApi.ownTeamId]
          : <String>[],
      'linkedPlayerIds': id == mockTenantAId && roles.contains('PARENT') ? <String>['p-ana'] : <String>[],
      'playerTeamIds': id == mockTenantAId && (roles.contains('PARENT') || roles.contains('PLAYER'))
          ? <String>[MockCoreApi.ownTeamId]
          : <String>[],
      'timezone': 'Europe/Madrid',
    },
  };

  Map<String, Object?> _profile(String id) => {
    'id': id,
    'slug': id == mockTenantAId ? 'demo' : 'norte',
    'name': id == mockTenantAId ? 'Academia Demo' : 'Club Norte',
    'timezone': 'Europe/Madrid',
    'defaultLocale': id == mockTenantAId ? 'es' : 'en',
    'hasLogo': id == mockTenantAId,
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
