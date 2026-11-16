import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/finance/data/mock_finance_api.dart';
import 'package:hoops_app/features/finance/domain/due_query.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import '../support/fake_finance.dart';
import '../support/finance_pump.dart';

/// Regenerate with `flutter test --update-goldens test/golden/finance_golden_test.dart`.
///
/// The screens show the demo mock's seed (EUR, three plans, the dues of Mini A
/// for September to November 2026), which does not depend on the day the test
/// runs.
void main() {
  Future<void> shoot(
    WidgetTester tester,
    String name,
    String location,
    Size size,
    Brightness brightness, {
    String? dueSeed,
  }) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final repo = FakeFinanceRepository();
    var path = location;
    if (dueSeed != null) {
      final due = (await tester.runAsync(
        () => FakeFinanceRepository().dues(
          DueQuery(
            planId: MockFinanceApi.monthlyPlanId,
            period: '2026-09',
            status: fin.DueStatus.PAID,
            size: 50,
          ),
        ),
      ))!.items.first;
      path = '$location/${due.id}';
    }
    await pumpFinance(tester, repo: repo, location: path, size: size);
    final tag = brightness == Brightness.dark ? '_dark' : '';
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        'goldens/finance_${name}_${size.width.toInt()}x${size.height.toInt()}$tag.png',
      ),
    );
  }

  const phone = Size(360, 780);
  const wide = Size(1024, 768);

  final screens = {
    'settings': ('/admin/finance/settings', null),
    'plans': ('/admin/finance/plans', null),
    'dues': ('/admin/finance/dues', null),
    'due': ('/admin/finance/dues', 'paid'),
  };

  for (final MapEntry(key: name, value: (location, seed)) in screens.entries) {
    for (final (size, brightness) in [
      (phone, Brightness.light),
      (phone, Brightness.dark),
      (wide, Brightness.light),
      (wide, Brightness.dark),
    ]) {
      testWidgets(
        'finance $name, ${size.width.toInt()}x${size.height.toInt()}'
        '${brightness == Brightness.dark ? ', dark' : ''}',
        (tester) =>
            shoot(tester, name, location, size, brightness, dueSeed: seed),
      );
    }
  }
}
