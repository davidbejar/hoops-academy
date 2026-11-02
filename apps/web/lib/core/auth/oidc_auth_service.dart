import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:oidc/oidc.dart';
import 'package:oidc_default_store/oidc_default_store.dart';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'end_session_redirect.dart';

/// Keycloak (OIDC authorization code + PKCE) via `package:oidc`.
///
/// Web redirects land on `redirect.html` (same origin); the page stores the
/// response and navigates the tab back to the `original_uri` the login was
/// started with, where [init] completes the code exchange. Tokens live in the
/// package's store (browser storage on web). Access tokens are refreshed
/// proactively (`refreshBefore`) by the package, with the 401 interceptor as a
/// backstop.
class OidcAuthService implements AuthService {
  OidcAuthService(
    AppConfig config, {
    required Uri origin,
    Uri Function()? location,
    @visibleForTesting OidcUserManager? manager,
  }) : _clientId = config.clientId,
       _location = location ?? (() => Uri.base),
       postLogoutRedirectUri = origin,
       _manager =
           manager ??
           OidcUserManager.lazy(
             discoveryDocumentUri: OidcUtils.getOpenIdConfigWellKnownUri(
               config.issuer,
             ),
             clientCredentials: OidcClientAuthentication.none(
               clientId: config.clientId,
             ),
             store: OidcDefaultStore(),
             settings: OidcUserManagerSettings(
               scope: config.scopes,
               redirectUri: origin.resolve('redirect.html'),
               postLogoutRedirectUri: origin.resolve('redirect.html'),
               refreshBefore: (_) => const Duration(seconds: 60),
               options: const OidcPlatformSpecificOptions(
                 web: OidcPlatformSpecificOptions_Web(
                   navigationMode:
                       OidcPlatformSpecificOptions_Web_NavigationMode.samePage,
                 ),
               ),
             ),
           );

  static const _revokeTimeout = Duration(seconds: 3);
  final String _clientId;
  final Uri Function() _location;

  /// Where Keycloak sends the browser after end-session: the app itself. The
  /// user is already forgotten locally, so it boots to the login screen.
  /// (Not `redirect.html`: this hand-built request carries no `state`, so the
  /// page would have nothing to resume and would strand the tab.)
  @visibleForTesting
  final Uri postLogoutRedirectUri;
  final OidcUserManager _manager;
  final _controller = StreamController<AuthStatus>.broadcast();
  AuthStatus _status = AuthStatus.unknown;

  @override
  AuthStatus get status => _status;

  @override
  Stream<AuthStatus> get statusChanges => _controller.stream;

  void _set(AuthStatus next) {
    if (next == _status) return;
    _status = next;
    _controller.add(next);
  }

  @override
  Future<void> init() async {
    _manager.userChanges().listen(
      (user) => _set(
        user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
      ),
    );
    try {
      await _manager.init();
    } on Object {
      // Discovery unreachable or stored state corrupt: treat as signed out so
      // the user can retry from the login screen.
    }
    if (_status == AuthStatus.unknown) _set(AuthStatus.unauthenticated);
  }

  @override
  Future<void> login() async {
    // samePage: redirect.html can only navigate back with an original_uri.
    await _manager.loginAuthorizationCodeFlow(originalUri: _location());
  }

  /// Local sign-out first, IdP end-session second (F-03): the stored tokens
  /// are forgotten before the browser leaves for Keycloak, so a Keycloak that
  /// is down (or no network at all, [endSession] false) cannot leave the
  /// session behind for the next person on a shared device. The refresh token
  /// is revoked best effort (short timeout) while the user is still known.
  @override
  Future<void> logout({bool endSession = true}) async {
    final user = _manager.currentUser;
    final idToken = user?.idToken;
    Uri? endpoint;
    if (endSession && user != null) {
      try {
        endpoint = _manager.discoveryDocument.endSessionEndpoint;
        await _manager
            .revokeRefreshToken(forgetUser: false)
            .timeout(_revokeTimeout);
      } on Object {
        // Never blocks the sign-out.
      }
    }
    await _manager.forgetUser();
    _set(AuthStatus.unauthenticated);
    if (endpoint == null || idToken == null) return;
    redirectBrowserTo(
      endpoint.replace(
        queryParameters: {
          ...endpoint.queryParameters,
          'client_id': _clientId,
          'id_token_hint': idToken,
          'post_logout_redirect_uri': postLogoutRedirectUri.toString(),
        },
      ),
    );
  }

  @override
  Future<String?> accessToken() async =>
      _manager.currentUser?.token.accessToken;

  @override
  Future<bool> refresh() async {
    try {
      return await _manager.refreshToken() != null;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> expireSession() => _manager.forgetUser();
}
