import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/me/application/me_providers.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_service.dart';
import '../tenancy/tenant_selection.dart';
import 'session.dart';

/// Derives the [SessionState] the router guards on.
final Provider<SessionState> sessionProvider = Provider<SessionState>((ref) {
  final auth = ref.watch(authStatusProvider);
  switch (auth) {
    case AuthStatus.unknown:
      return const SessionState.initializing();
    case AuthStatus.unauthenticated:
      return const SessionState.signedOut();
    case AuthStatus.authenticated:
      break;
  }

  final me = ref.watch(currentUserProvider);
  final user = me.value;
  if (user == null) {
    return me.hasError
        ? const SessionState.profileError()
        : const SessionState.loadingProfile();
  }

  return sessionFor(user, ref.watch(selectedTenantIdProvider));
});

/// The tenant requests are scoped to, if any.
final Provider<String?> activeTenantIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionProvider);
  return session is Ready ? session.membership?.tenantId : null;
});
