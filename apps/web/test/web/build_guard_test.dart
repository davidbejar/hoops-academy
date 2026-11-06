import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F-20: tool/build_web.sh refuses unsafe release configurations.
ProcessResult _guard(List<String> args, {Map<String, String> env = const {}}) =>
    Process.runSync(
      'bash',
      ['tool/build_web.sh', ...args],
      environment: {'HOOPS_BUILD_GUARD_ONLY': '1', ...env},
    );

void main() {
  const https =
      '--dart-define=HOOPS_OIDC_ISSUER=https://id.example.org/auth/realms/academy';

  test('accepts an https issuer', () => expect(_guard([https]).exitCode, 0));
  test('refuses the mock API', () {
    final r = _guard([https, '--dart-define=HOOPS_MOCK_API=true']);
    expect(r.exitCode, 1);
    expect(r.stderr, contains('HOOPS_MOCK_API'));
  });
  test('refuses an http issuer and the http default', () {
    expect(
      _guard(['--dart-define=HOOPS_OIDC_ISSUER=http://id.example.org/realms/a'])
          .exitCode,
      1,
    );
    expect(_guard([]).exitCode, 1);
  });
  test('HOOPS_ALLOW_HTTP_ISSUER=1 allows the local stack', () {
    expect(_guard([], env: {'HOOPS_ALLOW_HTTP_ISSUER': '1'}).exitCode, 0);
  });
  test('the build uses --no-web-resources-cdn', () {
    expect(
      File('tool/build_web.sh').readAsStringSync(),
      contains('--no-web-resources-cdn'),
    );
  });
}
