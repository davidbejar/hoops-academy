import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/auth/oidc_auth_service.dart';
import 'package:hoops_app/core/auth/cross_tab_lock_stub.dart' as in_process;
import 'package:hoops_app/core/auth/serial_refresh.dart';
import 'package:hoops_app/core/config/app_config.dart';
import 'package:oidc/oidc.dart';

// F-08 / ADR-0034: Keycloak rotates refresh tokens, refuses one that was
// already used and then ends the session. The app survives that only if
// package:oidc sends the refresh token of the LAST answer, and if two tabs
// never both send the same one (SerialRefresh). A fake token endpoint (the
// manager's token hook) rotates like the realm does.

const _issuer = 'http://localhost:8080/auth/realms/academy';
// Test-only HS256 key: package:oidc verifies id_tokens with the client secret.
const _secret = 'test-only-hmac-key-0123456789abcdef';

final _config = AppConfig(
  issuer: Uri.parse(_issuer),
  clientId: 'web',
  apiBase: 'http://localhost:8080',
  mockApi: false,
  scopes: const ['openid', 'profile', 'email'],
);

void main() {
  test(
    'every refresh presents the refresh token of the previous answer',
    () async {
      final keycloak = _RotatingTokenEndpoint();
      final manager = _manager(keycloak);
      await manager.init();
      await manager.loginPassword(username: 'coach', password: 'x');
      final service = OidcAuthService(
        _config,
        origin: Uri.parse('http://localhost:5173/'),
        manager: manager,
      );

      expect(await service.refresh(), isTrue);
      expect(await service.refresh(), isTrue);
      expect(await service.refresh(), isTrue);

      expect(keycloak.presented, ['refresh-1', 'refresh-2', 'refresh-3']);
      expect(keycloak.rejected, isEmpty);
      expect(manager.currentUser?.token.refreshToken, 'refresh-4');
      expect(await service.accessToken(), 'access-4');
    },
  );

  test('a refresh token the realm already rotated away is refused', () async {
    final keycloak = _RotatingTokenEndpoint();
    final manager = _manager(keycloak);
    await manager.init();
    await manager.loginPassword(username: 'coach', password: 'x');
    final service = OidcAuthService(
      _config,
      origin: Uri.parse('http://localhost:5173/'),
      manager: manager,
    );
    expect(await service.refresh(), isTrue);

    final reused = manager.refreshToken(overrideRefreshToken: 'refresh-1');

    await expectLater(reused, throwsA(anything));
    expect(keycloak.rejected, ['refresh-1']);
  });

  group('two tabs share one stored session', () {
    // Both tabs restore the same tokens and refresh before the same expiry.
    Future<(OidcUserManager, OidcUserManager, _RotatingTokenEndpoint)> tabs({
      required bool serial,
    }) async {
      final keycloak = _RotatingTokenEndpoint();
      final store = OidcMemoryStore();
      final first = _manager(keycloak, store: store, serial: serial);
      await first.init();
      await first.loginPassword(username: 'coach', password: 'x');
      final second = _manager(keycloak, store: store, serial: serial);
      await second.init();
      // init restores the stored session at once and re-saves it in the
      // background; let that finish before either tab refreshes
      await pumpEventQueue(times: 100);
      expect(second.currentUser?.token.refreshToken, 'refresh-1');
      return (first, second, keycloak);
    }

    test('without serialising, the second tab spends a used token and the realm ends the session', () async {
      final (first, second, keycloak) = await tabs(serial: false);

      final results = await Future.wait([
        first.refreshToken().then((_) => true, onError: (Object _) => false),
        second.refreshToken().then((_) => true, onError: (Object _) => false),
      ]);

      expect(results, contains(false));
      expect(keycloak.rejected, ['refresh-1']);
      await expectLater(first.refreshToken(), throwsA(anything));
    });

    test(
      'tabs refreshing at the same moment take turns on one chain',
      () async {
        final (first, second, keycloak) = await tabs(serial: true);

        await Future.wait([first.refreshToken(), second.refreshToken()]);
        await Future.wait([first.refreshToken(), second.refreshToken()]);

        expect(keycloak.rejected, isEmpty);
        expect(keycloak.presented, [
          'refresh-1',
          'refresh-2',
          'refresh-3',
          'refresh-4',
        ]);
      },
    );

    test(
      'a tab whose copy another tab already spent sends the stored token',
      () async {
        final (first, second, keycloak) = await tabs(serial: true);
        await first.refreshToken();

        final refreshed = await second.refreshToken();

        expect(keycloak.rejected, isEmpty);
        expect(keycloak.presented, ['refresh-1', 'refresh-2']);
        expect(refreshed?.token.refreshToken, 'refresh-3');
      },
    );

    test('a refusal (session ended elsewhere) is passed on', () async {
      final (first, _, keycloak) = await tabs(serial: true);
      keycloak.revokeSession();

      await expectLater(first.refreshToken(), throwsA(anything));
    });
  });
}

const RefreshLock _inProcessLock = in_process.withCrossTabLock;

OidcUserManager _manager(
  _RotatingTokenEndpoint keycloak, {
  OidcStore? store,
  bool serial = false,
}) {
  final shared = store ?? OidcMemoryStore();
  Future<OidcTokenResponse> send(OidcTokenHookRequest r) async =>
      keycloak.answer(r.request);
  final serialised = SerialRefresh.fromStore(shared, lock: _inProcessLock);
  return OidcUserManager(
    discoveryDocument: OidcProviderMetadata.fromJson({
      'issuer': _issuer,
      'authorization_endpoint': '$_issuer/protocol/openid-connect/auth',
      'token_endpoint': '$_issuer/protocol/openid-connect/token',
      'grant_types_supported': [
        'authorization_code',
        'refresh_token',
        'password',
      ],
      'response_types_supported': ['code'],
      'subject_types_supported': ['public'],
      'id_token_signing_alg_values_supported': ['HS256'],
    }),
    clientCredentials: const OidcClientAuthentication.clientSecretPost(
      clientId: 'web',
      clientSecret: _secret,
    ),
    store: shared,
    settings: OidcUserManagerSettings(
      redirectUri: Uri.parse('http://localhost:5173/redirect.html'),
      scope: const ['openid', 'profile', 'email'],
      hooks: OidcUserManagerHooks(
        token: OidcHook(
          modifyExecution: (request, _) =>
              serial ? serialised.execute(request, send) : send(request),
        ),
      ),
    ),
  );
}

/// Rotates like the realm (`revokeRefreshToken`, `refreshTokenMaxReuse: 0`):
/// each answer carries a new refresh token and only the latest one is valid;
/// a spent one ends the session, so no token works afterwards (Keycloak 26:
/// "Session doesn't have required client", `RealmRefreshTokenRotationKeycloakTest`).
class _RotatingTokenEndpoint {
  int _generation = 0;
  bool _revoked = false;
  final presented = <String>[];
  final rejected = <String>[];

  /// Signed out elsewhere (or the SSO session ended): every refresh fails.
  void revokeSession() => _revoked = true;

  OidcTokenResponse answer(OidcTokenRequest request) {
    if (request.grantType == OidcConstants_GrantType.refreshToken) {
      final token = request.refreshToken!;
      if (_revoked || token != 'refresh-$_generation') {
        if (!_revoked) rejected.add(token);
        _revoked = true; // Keycloak ends the client session on a reuse
        throw OidcException.serverError(
          errorResponse: OidcErrorResponse.fromJson(const {
            'error': 'invalid_grant',
            'error_description': 'Maximum allowed refresh token reuse exceeded',
          }),
        );
      }
      presented.add(token);
    }
    _generation++;
    return OidcTokenResponse.fromJson({
      'access_token': 'access-$_generation',
      'token_type': 'Bearer',
      'expires_in': 300,
      'refresh_token': 'refresh-$_generation',
      'scope': 'openid profile email',
      'id_token': _idToken(),
    });
  }
}

String _idToken() {
  String part(Object json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final unsigned =
      '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'iss': _issuer, 'sub': 'coach-sub', 'aud': 'web', 'azp': 'web', 'iat': now, 'exp': now + 300})}';
  final signature = Hmac(
    sha256,
    utf8.encode(_secret),
  ).convert(utf8.encode(unsigned)).bytes;
  return '$unsigned.${base64Url.encode(signature).replaceAll('=', '')}';
}
