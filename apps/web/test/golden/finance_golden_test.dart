import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import '../support/finance_pump.dart';
import '../support/finance_seed.dart';

/// Regenerate with `flutter test --update-goldens test/golden/finance_golden_test.dart`.
///
/// The screens show the finance seed (EUR, three plans, the dues of Mini A for
/// September to November 2026), which does not depend on the day the test
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
    final finance = FinanceData();
    final h = await pumpFinance(
      tester,
      finance: finance,
      location: dueSeed == null ? location : null,
      size: size,
    );
    if (dueSeed != null) {
      // A paid due of September; its id is the mock's.
      final due = finance.due(fin.DueStatus.PAID, period: '2026-09');
      await h.go(tester, '$location/${due.id}');
    }
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
    'expenses': ('/admin/finance/expenses', null),
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

  // The balance's chart sits below the figures: a taller phone shows it.
  for (final (size, brightness) in [
    (const Size(360, 1400), Brightness.light),
    (const Size(360, 1400), Brightness.dark),
    (wide, Brightness.light),
    (wide, Brightness.dark),
  ]) {
    testWidgets(
      'finance balance, ${size.width.toInt()}x${size.height.toInt()}'
      '${brightness == Brightness.dark ? ', dark' : ''}',
      (tester) =>
          shoot(tester, 'balance', '/admin/finance/balance', size, brightness),
    );
  }
}
