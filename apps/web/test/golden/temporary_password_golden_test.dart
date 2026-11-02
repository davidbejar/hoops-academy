import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;

import '../support/fake_platform.dart';
import '../support/fake_repos.dart';
import '../support/fixtures.dart';
import '../support/harness.dart';

/// Regenerate with `flutter test --update-goldens test/golden/temporary_password_golden_test.dart`.
void main() {
  final bea = adminOf('p-bea', 'Beatriz', 'Soto Fernández', email: 'beatriz.soto@club-norte.example', status: api.InvitationStatus.PENDING);
  final ana = adminOf('p-ana', 'Ana', 'Ruiz', email: 'ana.ruiz@club-norte.example');

  Future<void> pumpDialog(WidgetTester tester, Size size) async {
    final repo = FakePlatformRepository(tenants: [tenantOf('t-a', 'Club Norte')], admins: {'t-a': [ana, bea]})..reissuedPrefix = 'Demo-Temp-Pass-';
    final h = Harness(
      me: FakeMeRepository(userWith(const [], superAdmin: true)),
      core: FakeCore(),
      platform: FakePlatform(repo: repo),
    );
    await h.pump(tester, size: size);
    await h.go(tester, '/platform/t-a');
    await tester.tap(find.byKey(const Key('admin-issue-p-bea')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('temp-password-dialog')), findsOneWidget);
  }

  testWidgets('temporary password dialog, 360x780', (tester) async {
    await pumpDialog(tester, const Size(360, 780));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/temporary_password_360x780.png'));
  });

  testWidgets('temporary password dialog, 1024x768', (tester) async {
    await pumpDialog(tester, const Size(1024, 768));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/temporary_password_1024x768.png'));
  });
}
