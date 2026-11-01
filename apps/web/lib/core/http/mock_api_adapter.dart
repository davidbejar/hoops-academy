import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

const mockTenantAId = '11111111-1111-4111-8111-111111111111';
const mockTenantBId = '22222222-2222-4222-8222-222222222222';

// 16x16 solid teal PNG, stands in for an uploaded academy logo.
final _logoPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAFklEQVR4nGPgLmolCTGMahjVMHw1AACwJgIQC/cFwQAAAABJRU5ErkJggg==',
);

/// In-memory stand-in for core-service (`--dart-define=HOOPS_MOCK_API=true`).
///
/// Serves `GET/PATCH /api/core/me`, `GET /api/core/tenant` and
/// `GET /api/core/tenant/logo`, and enforces the same header contract as the
/// real service (bearer on everything, `X-Tenant-Id` on tenant paths), so the
/// shell's interceptors are exercised even without a backend.
class MockApiAdapter implements HttpClientAdapter {
  MockApiAdapter();

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

    final tenant = options.headers['X-Tenant-Id'] as String?;
    if (path.startsWith('/api/core/tenant')) {
      if (tenant != mockTenantAId && tenant != mockTenantBId) {
        return _problem(
          tenant == null ? 400 : 404,
          tenant == null ? 'X-Tenant-Id is required' : 'Not found',
        );
      }
      if (path == '/api/core/tenant') return _json(_profile(tenant!));
      if (path == '/api/core/tenant/logo') {
        return tenant == mockTenantAId
            ? ResponseBody.fromBytes(
                _logoPng,
                200,
                headers: {
                  Headers.contentTypeHeader: ['image/png'],
                },
              )
            : _problem(404, 'No logo');
      }
    }
    return _problem(404, 'Not found');
  }

  Map<String, Object?> _me() => {
    'userId': '00000000-0000-4000-8000-000000000001',
    'sub': 'mock-sub',
    'email': 'coach1@hoops.local',
    'displayName': 'Casey Coach',
    'locale': _locale,
    'superAdmin': false,
    'memberships': [
      _membership(mockTenantAId, 'demo', 'Academia Demo', true, [
        'ADMIN',
        'COACH',
      ]),
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
    'personId': '00000000-0000-4000-8000-0000000000a1',
    'roles': roles,
    'authz': {'staffTeamIds': <String>[], 'linkedPlayerIds': <String>[]},
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
