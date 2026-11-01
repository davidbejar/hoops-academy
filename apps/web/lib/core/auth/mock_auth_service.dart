import 'dart:async';

import 'auth_service.dart';

/// Dev/test identity provider: "signs in" instantly with a fake token.
class MockAuthService implements AuthService {
  MockAuthService({AuthStatus initial = AuthStatus.unauthenticated})
    : _status = initial;

  final _controller = StreamController<AuthStatus>.broadcast();
  AuthStatus _status;

  @override
  AuthStatus get status => _status;

  @override
  Stream<AuthStatus> get statusChanges => _controller.stream;

  void _set(AuthStatus next) {
    _status = next;
    _controller.add(next);
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> login() async => _set(AuthStatus.authenticated);

  @override
  Future<void> logout() async => _set(AuthStatus.unauthenticated);

  @override
  Future<String?> accessToken() async =>
      _status == AuthStatus.authenticated ? 'mock-access-token' : null;

  @override
  Future<bool> refresh() async => _status == AuthStatus.authenticated;

  @override
  Future<void> expireSession() async => _set(AuthStatus.unauthenticated);
}
