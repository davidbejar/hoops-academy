import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/config/app_config.dart';

void main() {
  test('default scopes never request offline_access (F-03/F-08): refresh tokens stay bound to the SSO session', () {
    final scopes = AppConfig.fromEnvironment().scopes;
    expect(scopes, ['openid', 'profile', 'email']);
    expect(scopes, isNot(contains('offline_access')));
  });
}
