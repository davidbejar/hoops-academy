import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/finance/domain/currencies.dart';

/// The contract lists no currencies, so the web keeps a copy of the service's
/// table; this fails when the two drift apart.
void main() {
  const goFile = '../../services/finance-service/internal/domain/currencies.go';

  test('the amount of decimals of a few well known currencies', () {
    expect(financeCurrencies['EUR'], 2);
    expect(financeCurrencies['IDR'], 2);
    expect(financeCurrencies['JPY'], 0);
    expect(financeCurrencies['BHD'], 3);
  });

  test('codes are three capital letters and decimals are 0 to 3', () {
    for (final e in financeCurrencies.entries) {
      expect(e.key, matches(RegExp(r'^[A-Z]{3}$')));
      expect(e.value, inInclusiveRange(0, 3), reason: e.key);
    }
  });

  test(
    'is the table of finance-service',
    () {
      final source = File(goFile).readAsStringSync();
      final server = {
        for (final m in RegExp(r'"([A-Z]{3})": (\d)').allMatches(source))
          m[1]!: int.parse(m[2]!),
      };
      expect(server, isNotEmpty);
      expect(financeCurrencies, server);
    },
    skip: File(goFile).existsSync() ? false : 'service sources not checked out',
  );
}
