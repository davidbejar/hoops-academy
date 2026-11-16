import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/finance/domain/money.dart';

/// Amounts are integers in the currency's minor unit; `minorDigits` comes from
/// the academy's finance settings (EUR 2, JPY 0, BHD 3). IDR is shown without
/// decimals while the amount is whole, as the people of an academy write it.
void main() {
  const nb = ' ';

  MoneyFormat money(String currency, int digits, String locale) =>
      MoneyFormat(currency: currency, minorDigits: digits, locale: locale);

  group('format', () {
    test('euro in the three locales', () {
      expect(money('EUR', 2, 'es').format(4500), '45,00$nb€');
      expect(money('EUR', 2, 'en').format(4500), '€45.00');
      expect(money('EUR', 2, 'id').format(4500), '€45,00');
    });

    test('groups thousands the way the locale does', () {
      expect(money('EUR', 2, 'es').format(123456789), '1.234.567,89$nb€');
      expect(money('EUR', 2, 'en').format(123456789), '€1,234,567.89');
    });

    test('rupiah has no decimals while the amount is whole', () {
      expect(money('IDR', 2, 'id').format(15000000), 'Rp150.000');
      expect(money('IDR', 2, 'en').format(15000000), 'Rp150,000');
    });

    test('rupiah keeps its decimals when the amount has a fraction', () {
      expect(money('IDR', 2, 'id').format(15000050), 'Rp150.000,50');
    });

    test('a currency with no minor unit, and one with three digits', () {
      expect(money('JPY', 0, 'en').format(1500), '¥1,500');
      expect(money('BHD', 3, 'en').format(12345), 'din12.345');
    });

    test('the smallest amounts keep their leading zero', () {
      expect(money('EUR', 2, 'en').format(5), '€0.05');
    });

    test('the largest amount the contract allows is exact', () {
      expect(
        money('JPY', 0, 'en').format(MoneyFormat.maxAmountMinor),
        '¥100,000,000,000',
      );
    });
  });

  group('inputText', () {
    test('is what the field shows when editing: no symbol, no grouping', () {
      expect(money('EUR', 2, 'es').inputText(123456), '1234,56');
      expect(money('EUR', 2, 'en').inputText(123456), '1234.56');
      expect(money('EUR', 2, 'en').inputText(4500), '45.00');
      expect(money('IDR', 2, 'id').inputText(15000000), '150000');
      expect(money('JPY', 0, 'en').inputText(1500), '1500');
    });

    test('parses back to the same amount', () {
      for (final (code, digits, locale, minor) in [
        ('EUR', 2, 'es', 123456),
        ('EUR', 2, 'en', 5),
        ('IDR', 2, 'id', 15000000),
        ('IDR', 2, 'id', 15000050),
        ('BHD', 3, 'en', 12345),
        ('JPY', 0, 'id', 1500),
      ]) {
        final m = money(code, digits, locale);
        expect(m.parse(m.inputText(minor)), minor, reason: '$code $locale');
      }
    });
  });

  group('parse', () {
    test('reads the locale decimal separator', () {
      expect(money('EUR', 2, 'es').parse('45,50'), 4550);
      expect(money('EUR', 2, 'en').parse('45.50'), 4550);
      expect(money('EUR', 2, 'id').parse('45,5'), 4550);
    });

    test('a whole number is whole units', () {
      expect(money('EUR', 2, 'en').parse('45'), 4500);
      expect(money('JPY', 0, 'en').parse('1500'), 1500);
      expect(money('BHD', 3, 'en').parse('1.2'), 1200);
    });

    test('accepts the locale grouping, spaces and the currency symbol', () {
      expect(money('EUR', 2, 'es').parse('1.234,56'), 123456);
      expect(money('EUR', 2, 'en').parse('1,234.56'), 123456);
      expect(money('EUR', 2, 'es').parse(' 45,00$nb€ '), 4500);
      expect(money('EUR', 2, 'en').parse('€45.00'), 4500);
      expect(money('IDR', 2, 'id').parse('Rp 150.000'), 15000000);
      expect(money('EUR', 2, 'en').parse('EUR 45'), 4500);
    });

    test(
      'the other separator is a decimal point when it cannot be grouping',
      () {
        // Spanish keyboards often type the point: 45.50 cannot be 4,550.
        expect(money('EUR', 2, 'es').parse('45.50'), 4550);
        // but three digits after it are a group: 45.500 is 45,500.
        expect(money('EUR', 2, 'es').parse('45.500'), 4550000);
        expect(money('EUR', 2, 'en').parse('45,5'), 4550);
      },
    );

    test('refuses what is not an amount', () {
      final m = money('EUR', 2, 'en');
      for (final text in ['', '  ', 'abc', '1.2.3', '-5', '45.555', '€']) {
        expect(m.parse(text), isNull, reason: '"$text"');
      }
    });

    test('refuses more decimals than the currency has', () {
      expect(money('JPY', 0, 'en').parse('1500.5'), isNull);
      expect(money('EUR', 2, 'en').parse('1.234'), isNull);
    });

    test('refuses zero and anything above the contract maximum', () {
      final m = money('JPY', 0, 'en');
      expect(m.parse('0'), isNull);
      expect(m.parse('1'), 1);
      expect(m.parse('100000000000'), MoneyFormat.maxAmountMinor);
      expect(m.parse('100000000001'), isNull);
      expect(m.parse('99999999999999999999999'), isNull);
    });
  });
}
