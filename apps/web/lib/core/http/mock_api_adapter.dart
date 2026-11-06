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
/// `/api/athlete/**` for both demo academies (each with its own roster, shared by the three mocks, and the demo
/// user's roles there: [roles] in Academia Demo, PARENT in Club Norte) and `/platform/**` (super admin
/// only), and enforces the same header contract as the
/// real service (bearer on everything, `X-Tenant-Id` on tenant paths), so the
/// shell's interceptors are exercised even without a backend.
class MockApiAdapter implements HttpClientAdapter {
  MockApiAdapter({List<String>? roles, bool? superAdmin})
    : _roles = roles ?? _rolesFromEnvironment(),
      _superAdmin = superAdmin ?? _superAdminFromEnvironment(),
      _platform = MockPlatformApi(
        tenantAId: mockTenantAId,
        tenantBId: mockTenantBId,
      ) {
    _academies = {
      mockTenantAId: _Academy(
        MockCoreApi(initialLogo: _logoPng, roles: _roles),
      ),
      mockTenantBId: _Academy(
        MockCoreApi(academy: MockAcademy.norte, roles: const ['PARENT']),
      ),
    };
  }

  /// `--dart-define=HOOPS_MOCK_ROLES=COACH` (comma separated) switches the
  /// demo user's roles in the first academy to try the role variants.
  static List<String> _rolesFromEnvironment() => const String.fromEnvironment(
    'HOOPS_MOCK_ROLES',
    defaultValue: 'ADMIN,COACH',
  ).split(',').map((r) => r.trim()).where((r) => r.isNotEmpty).toList();

  /// `--dart-define=HOOPS_MOCK_SUPER_ADMIN=false` turns the demo user into a plain member (default: a super admin,
  /// so the demo reaches the platform console from the profile menu).
  static bool _superAdminFromEnvironment() =>
      const bool.fromEnvironment('HOOPS_MOCK_SUPER_ADMIN', defaultValue: true);

  final List<String> _roles;
  final bool _superAdmin;
  late final Map<String, _Academy> _academies;
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
    if (path.startsWith('/api/athlete/')) {
      final result = academy.athlete.handle(
        method: method,
        path: path,
        query: options.queryParameters,
        body: body,
      );
      return _result(
        result ??
            const MockResult.json(404, {'title': 'Not found', 'status': 404}),
      );
    }
    if (path.startsWith('/api/game/')) {
      final result = academy.game.handle(
        method: method,
        path: path,
        query: options.queryParameters,
        body: body,
      );
      if (result != null) return _result(result);
    }
    if (path.startsWith('/api/core/')) {
      final result = academy.core.handle(
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
    }
    return _problem(404, 'Not found');
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
      _membership(mockTenantBId, 'norte', 'Club Norte', false, const [
        'PARENT',
      ]),
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

/// One demo academy: its core data and the athlete and game mocks reading the same roster.
class _Academy {
  _Academy(this.core)
    : athlete = MockAthleteApi(core: core),
      game = MockGameApi(core: core);

  final MockCoreApi core;
  final MockAthleteApi athlete;
  final MockGameApi game;
}
