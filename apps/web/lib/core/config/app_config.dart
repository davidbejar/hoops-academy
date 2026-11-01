import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time configuration (`--dart-define=...`).
@immutable
class AppConfig {
  const AppConfig({
    required this.issuer,
    required this.clientId,
    required this.apiBase,
    required this.mockApi,
    required this.scopes,
  });

  /// Keycloak realm issuer; discovery is `<issuer>/.well-known/openid-configuration`.
  final Uri issuer;
  final String clientId;

  /// Origin the API is served from (nginx at `:8080` in the local stack).
  final String apiBase;

  /// Serve `/api/core/me` and the tenant profile from in-memory fixtures and
  /// sign in without Keycloak. For demos until core-service exists.
  final bool mockApi;
  final List<String> scopes;

  static const _issuer = String.fromEnvironment(
    'HOOPS_OIDC_ISSUER',
    defaultValue: 'http://localhost:8080/auth/realms/academy',
  );
  static const _clientId = String.fromEnvironment(
    'HOOPS_OIDC_CLIENT_ID',
    defaultValue: 'web',
  );
  static const _apiBase = String.fromEnvironment('HOOPS_API_BASE');
  static const _mock = bool.fromEnvironment('HOOPS_MOCK_API');
  static const _scopes = String.fromEnvironment(
    'HOOPS_OIDC_SCOPES',
    defaultValue: 'openid,profile,email,offline_access',
  );

  factory AppConfig.fromEnvironment() => AppConfig(
    issuer: Uri.parse(_issuer),
    clientId: _clientId,
    apiBase: _apiBase.isNotEmpty ? _apiBase : _currentOrigin(),
    mockApi: _mock,
    scopes: _scopes.split(',').map((s) => s.trim()).toList(),
  );
}

/// Origin the app is served from; empty outside a browser (tests, tools).
String _currentOrigin() {
  final base = Uri.base;
  return base.scheme == 'http' || base.scheme == 'https' ? base.origin : '';
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
