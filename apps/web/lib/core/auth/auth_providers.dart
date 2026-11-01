import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'mock_auth_service.dart';
import 'oidc_auth_service.dart';

/// Directory URL the app is served from (no query/fragment), against which
/// `redirect.html` is resolved.
Uri appBaseUri() {
  final b = Uri.base;
  final dir = b.path.substring(0, b.path.lastIndexOf('/') + 1);
  return Uri(
    scheme: b.scheme,
    host: b.host,
    port: b.hasPort ? b.port : null,
    path: dir.isEmpty ? '/' : dir,
  );
}

final authServiceProvider = Provider<AuthService>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.mockApi
      ? MockAuthService()
      : OidcAuthService(config, origin: appBaseUri());
});

/// Current [AuthStatus]; starts the service (restores session / completes a
/// pending redirect) the first time it is read.
class AuthStatusNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    final service = ref.watch(authServiceProvider);
    final sub = service.statusChanges.listen((s) => state = s);
    ref.onDispose(sub.cancel);
    unawaited(service.init());
    return service.status;
  }
}

final authStatusProvider = NotifierProvider<AuthStatusNotifier, AuthStatus>(
  AuthStatusNotifier.new,
);
