import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/auth/oidc_auth_service.dart';
import 'package:hoops_app/core/config/app_config.dart';
import 'package:oidc/oidc.dart';

// With the web `samePage` navigation mode, Keycloak sends the browser to redirect.html, which can only go back to the
// app when the login was started with an `original_uri`; without it the page waits for an app tab that no longer
// exists and ends on "You can now close this tab and return to the app." (the tab IS the app).

final _config = AppConfig(
  issuer: Uri.parse('http://localhost:8080/auth/realms/academy'),
  clientId: 'web',
  apiBase: 'http://localhost:8080',
  mockApi: false,
  scopes: const ['openid', 'profile', 'email'],
);
final _appBase = Uri.parse('http://localhost:5173/');

void main() {
  test('login returns the browser to the app page it started from', () async {
    final manager = _RecordingManager();
    final current = Uri.parse('http://localhost:5173/#/login?from=%2Fmatches');
    final service = OidcAuthService(
      _config,
      origin: _appBase,
      location: () => current,
      manager: manager,
    );

    await service.login();

    expect(manager.loginCalls, 1);
    expect(manager.originalUri, current);
  });

  // The sign-in page is Keycloak's, on another origin: it cannot read the
  // look chosen in the app, so the app hands it over with the request.
  for (final theme in ['light', 'dark', 'system']) {
    test('login tells the sign-in page the chosen look: $theme', () async {
      final manager = _RecordingManager();
      final service = OidcAuthService(
        _config,
        origin: _appBase,
        location: () => _appBase,
        loginTheme: () => theme,
        manager: manager,
      );

      await service.login();

      expect(manager.extraParameters, {'hoops_theme': theme});
    });
  }

  test('sign-out returns to the app itself, not to redirect.html (which has no state to resume)', () {
    final service = OidcAuthService(
      _config,
      origin: _appBase,
      manager: _RecordingManager(),
    );

    expect(service.postLogoutRedirectUri, _appBase);
  });
}

class _RecordingManager extends OidcUserManager {
  _RecordingManager()
    : super.lazy(
        discoveryDocumentUri: Uri.parse(
          'http://localhost:8080/auth/realms/academy/.well-known/openid-configuration',
        ),
        clientCredentials: const OidcClientAuthentication.none(clientId: 'web'),
        store: OidcMemoryStore(),
        settings: OidcUserManagerSettings(
          redirectUri: Uri.parse('http://localhost:5173/redirect.html'),
        ),
      );

  int loginCalls = 0;
  Uri? originalUri;
  Map<String, dynamic>? extraParameters;

  @override
  Future<OidcUser?> loginAuthorizationCodeFlow({
    OidcProviderMetadata? discoveryDocumentOverride,
    Uri? redirectUriOverride,
    Uri? originalUri,
    List<String>? scopeOverride,
    List<String>? promptOverride,
    List<String>? uiLocalesOverride,
    String? displayOverride,
    List<String>? acrValuesOverride,
    dynamic extraStateData,
    bool includeIdTokenHintFromCurrentUser = true,
    String? idTokenHintOverride,
    String? loginHint,
    Duration? maxAgeOverride,
    Map<String, dynamic>? extraParameters,
    Map<String, dynamic>? extraTokenParameters,
    Map<String, String>? extraTokenHeaders,
    OidcPlatformSpecificOptions? options,
    List<String>? responseTypeOverride,
  }) async {
    loginCalls++;
    this.originalUri = originalUri;
    this.extraParameters = extraParameters;
    return null;
  }
}
