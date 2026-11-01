enum AuthStatus { unknown, unauthenticated, authenticated }

/// Port over the identity provider. The app never touches `oidc` types
/// outside `oidc_auth_service.dart`.
abstract class AuthService {
  AuthStatus get status;
  Stream<AuthStatus> get statusChanges;

  /// Restores a stored session and completes a pending redirect, if any.
  Future<void> init();

  /// Starts the PKCE authorization-code flow (leaves the page on web).
  Future<void> login();

  /// Ends the session. The local session is always forgotten first, so this
  /// also works offline; with [endSession] the IdP session is ended too
  /// (best effort, leaves the page on web). Pass false while offline.
  Future<void> logout({bool endSession = true});

  /// The current access token, or null when signed out.
  Future<String?> accessToken();

  /// Forces a refresh-token exchange; false when it failed.
  Future<bool> refresh();

  /// Drops the local session without contacting the IdP (refresh failed).
  Future<void> expireSession();
}
