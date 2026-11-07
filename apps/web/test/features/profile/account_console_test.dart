import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/config/app_config.dart';
import 'package:hoops_app/core/navigation/external_link.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/fixtures.dart';
import '../../support/harness.dart';

AppConfig _config({required bool mock, String issuer = 'http://kc/realms/a'}) =>
    AppConfig(
      issuer: Uri.parse(issuer),
      clientId: 'web',
      apiBase: 'http://mock.local',
      mockApi: mock,
      scopes: const ['openid'],
    );

Future<List<Uri>> _pump(
  WidgetTester tester, {
  required bool mock,
  String issuer = 'http://kc/realms/a',
}) async {
  final opened = <Uri>[];
  final member = membershipWithRoles({TenantRole.coach});
  final h = Harness(
    me: FakeMeRepository(userWith([member])),
    prefs: {'hoops.selectedTenantId': member.tenantId},
    extraOverrides: [
      appConfigProvider.overrideWithValue(_config(mock: mock, issuer: issuer)),
      externalLinkOpenerProvider.overrideWithValue(opened.add),
    ],
  );
  await h.pump(tester);
  await tester.tap(find.byKey(const Key('profile-button')));
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  testWidgets('the profile links to the account console in a new tab', (
    tester,
  ) async {
    final opened = await _pump(tester, mock: false);
    final entry = find.byKey(const Key('open-account-console'));
    await tester.ensureVisible(entry);
    expect(find.text('Cuenta y seguridad'), findsOneWidget);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse('http://kc/realms/a/account')]);
  });

  testWidgets('a trailing slash of the issuer does not double up', (
    tester,
  ) async {
    final opened = await _pump(
      tester,
      mock: false,
      issuer: 'http://kc/realms/a/',
    );
    await tester.tap(find.byKey(const Key('open-account-console')));
    await tester.pumpAndSettle();
    expect(opened.single.toString(), 'http://kc/realms/a/account');
  });

  testWidgets('the demo has no identity provider: no account entry', (
    tester,
  ) async {
    await _pump(tester, mock: true);
    expect(find.byKey(const Key('open-account-console')), findsNothing);
  });
}
