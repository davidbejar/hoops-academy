import 'dart:async';
import 'dart:convert';

import 'package:oidc/oidc.dart';

import 'cross_tab_lock.dart';

/// Signature of [withCrossTabLock]; tests pass an in-process lock.
typedef RefreshLock = Future<void> Function(
  String name,
  Future<void> Function() body,
);

/// Keeps every browser tab of the app on the same refresh-token chain
/// (ADR-0034).
///
/// Keycloak rotates the refresh token on every refresh, and when a spent one
/// is presented again it refuses it AND ends the client's session, so every
/// tab is signed out. All tabs share the stored session but each keeps its
/// own copy in memory, and all of them refresh before the same expiry. Wrapped
/// around the token request, this lets one tab refresh at a time (a lock all
/// tabs share), sends the refresh token currently in the store instead of a
/// copy another tab has already spent, and holds the lock until the answer is
/// stored, so the next tab sees the new token.
class SerialRefresh {
  SerialRefresh({
    required this.storedRefreshToken,
    this.lock = withCrossTabLock,
    this.saveTimeout = const Duration(seconds: 2),
    this.pollInterval = const Duration(milliseconds: 25),
  });

  /// Reads the refresh token of the session `package:oidc` keeps in [store].
  factory SerialRefresh.fromStore(
    OidcStore store, {
    String? managerId,
    RefreshLock lock = withCrossTabLock,
  }) => SerialRefresh(
    lock: lock,
    storedRefreshToken: () async {
      final raw = await store.get(
        OidcStoreNamespace.secureTokens,
        key: OidcConstants_Store.currentToken,
        managerId: managerId,
      );
      if (raw == null) return null;
      final token = jsonDecode(raw);
      return token is Map ? token['refresh_token'] as String? : null;
    },
  );

  static const lockName = 'hoops-oidc-refresh';

  /// The refresh token in the shared session store, if any.
  final Future<String?> Function() storedRefreshToken;
  final RefreshLock lock;

  /// Longest wait for `package:oidc` to store an answer before the lock is
  /// released anyway.
  final Duration saveTimeout;
  final Duration pollInterval;

  /// The token hook for `OidcUserManagerSettings.hooks`.
  OidcHook<OidcTokenHookRequest, OidcTokenResponse> get hook =>
      OidcHook(modifyExecution: execute);

  Future<OidcTokenResponse> execute(
    OidcTokenHookRequest request,
    OidcHookExecution<OidcTokenHookRequest, OidcTokenResponse> send,
  ) {
    if (request.request.grantType != OidcConstants_GrantType.refreshToken) {
      return send(request);
    }
    final answer = Completer<OidcTokenResponse>();
    unawaited(
      lock(lockName, () async {
        try {
          await _presentTheStoredToken(request);
          final response = await send(request);
          answer.complete(response);
          await _untilStored(response.refreshToken);
        } on Object catch (e, st) {
          if (!answer.isCompleted) answer.completeError(e, st);
        }
      }),
    );
    return answer.future;
  }

  Future<void> _presentTheStoredToken(OidcTokenHookRequest request) async {
    final sent = request.request;
    final stored = await storedRefreshToken();
    if (stored == null || stored == sent.refreshToken) return;
    request.request = OidcTokenRequest.refreshToken(
      refreshToken: stored,
      clientId: sent.clientId,
      clientSecret: sent.clientSecret,
      scope: sent.scope,
      resource: sent.resource,
      extra: sent.extra,
    );
  }

  Future<void> _untilStored(String? refreshToken) async {
    if (refreshToken == null) return;
    final deadline = DateTime.now().add(saveTimeout);
    while (await storedRefreshToken() != refreshToken &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(pollInterval);
    }
  }
}
