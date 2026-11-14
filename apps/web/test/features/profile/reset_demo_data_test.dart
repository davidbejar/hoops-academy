import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/config/app_config.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/fixtures.dart';
import '../../support/harness.dart';

class _CountingAdapter extends MockApiAdapter {
  int resets = 0;

  @override
  Future<void> reset() async {
    resets++;
    await super.reset();
  }
}

AppConfig _config({required bool mock}) => AppConfig(
  issuer: Uri.parse('http://unused'),
  clientId: 'web',
  apiBase: 'http://mock.local',
  mockApi: mock,
  scopes: const ['openid'],
);

Future<Harness> _pump(
  WidgetTester tester, {
  required bool mock,
  required MockApiAdapter adapter,
}) async {
  final member = membershipWithRoles({TenantRole.admin});
  final h = Harness(
    me: FakeMeRepository(userWith([member])),
    prefs: {'hoops.selectedTenantId': member.tenantId},
    extraOverrides: [
      appConfigProvider.overrideWithValue(_config(mock: mock)),
      mockApiAdapterProvider.overrideWithValue(adapter),
    ],
  );
  await h.pump(tester);
  await tester.tap(find.byKey(const Key('profile-button')));
  await tester.pumpAndSettle();
  return h;
}

void main() {
  testWidgets('demo mode: the profile offers "Reset demo data" and runs it', (
    tester,
  ) async {
    final adapter = _CountingAdapter();
    await _pump(tester, mock: true, adapter: adapter);
    final entry = find.byKey(const Key('reset-demo-data'));
    await tester.ensureVisible(entry);
    expect(find.text('Restablecer datos de demostración'), findsOneWidget);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(adapter.resets, 1);
  });

  testWidgets('a real backend: no reset entry', (tester) async {
    await _pump(tester, mock: false, adapter: _CountingAdapter());
    expect(find.byKey(const Key('reset-demo-data')), findsNothing);
  });
}
