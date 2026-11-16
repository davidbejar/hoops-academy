import 'package:intl/intl.dart';
import 'package:intl/number_symbols.dart';

/// Shows and reads amounts of the academy's one currency (ADR-0056).
///
/// Every amount is an integer in the currency's minor unit; [minorDigits]
/// (from the finance settings: EUR 2, JPY 0, BHD 3) says how many decimals
/// that unit has. The number is formatted for [locale]. A whole amount of a
/// currency that is written without decimals (rupiah) shows none even though
/// its minor unit has two.
class MoneyFormat {
  const MoneyFormat({
    required this.currency,
    required this.minorDigits,
    required this.locale,
  });

  /// The contract's largest amount (`AmountMinor`): 10^11 minor units.
  static const maxAmountMinor = 100000000000;

  /// Longest digit string [parse] looks at; beyond it the amount is too large
  /// anyway and the integer math stays far from overflow.
  static const _maxDigits = 15;

  final String currency;
  final int minorDigits;
  final String locale;

  int get _scale {
    var scale = 1;
    for (var i = 0; i < minorDigits; i++) {
      scale *= 10;
    }
    return scale;
  }

  NumberFormat _numberFormat(int digits) => NumberFormat.simpleCurrency(
    locale: locale,
    name: currency,
    decimalDigits: digits,
  );

  /// Decimals shown for [amountMinor]: all of the minor unit, fewer only when
  /// the amount is whole and the currency is conventionally written with
  /// fewer.
  int _digitsFor(int amountMinor) {
    if (amountMinor % _scale != 0) return minorDigits;
    final conventional = NumberFormat.simpleCurrency(
      locale: locale,
      name: currency,
    ).decimalDigits;
    return conventional == null || conventional > minorDigits
        ? minorDigits
        : conventional;
  }

  /// `45,00 €`, `Rp150.000`, `¥1,500`.
  String format(int amountMinor) =>
      _numberFormat(_digitsFor(amountMinor)).format(amountMinor / _scale);

  /// The amount as a form field shows it: the locale's decimal separator, no
  /// symbol and no grouping. [parse] reads it back.
  String inputText(int amountMinor) {
    final digits = _digitsFor(amountMinor);
    final whole = amountMinor ~/ _scale;
    if (digits == 0) return '$whole';
    final fraction = (amountMinor % _scale)
        .toString()
        .padLeft(minorDigits, '0')
        .substring(0, digits);
    return '$whole${_symbols.DECIMAL_SEP}$fraction';
  }

  NumberSymbols get _symbols => NumberFormat.decimalPattern(locale).symbols;

  /// The amount in minor units that [text] says, or null when it is not an
  /// amount of this currency: empty, not a number, more decimals than the
  /// minor unit has, zero, or above [maxAmountMinor].
  ///
  /// Reads the locale's decimal separator and grouping, with or without the
  /// currency's symbol or code. The other separator counts as a decimal point
  /// when it cannot be grouping (`45.50` in Spanish).
  int? parse(String text) {
    final cleaned = _withoutCurrency(text).trim();
    final decimal = _symbols.DECIMAL_SEP;
    final group = _symbols.GROUP_SEP;
    final digits = RegExp(r'\d');
    if (cleaned.isEmpty || !digits.hasMatch(cleaned)) return null;
    final allowed = RegExp(
      '^[\\d${RegExp.escape(decimal)}${RegExp.escape(group)}]+\$',
    );
    if (!allowed.hasMatch(cleaned)) return null;

    final (whole, fraction) = _split(cleaned, decimal, group);
    if (whole == null) return null;
    if (fraction.length > minorDigits) return null;
    final wholeDigits = whole.replaceAll(group, '');
    if (wholeDigits.length + minorDigits > _maxDigits) return null;
    if (wholeDigits.isEmpty && fraction.isEmpty) return null;
    if (!_validGrouping(whole, group)) return null;

    final amount =
        int.parse(wholeDigits.isEmpty ? '0' : wholeDigits) * _scale +
        (fraction.isEmpty ? 0 : int.parse(fraction.padRight(minorDigits, '0')));
    return amount < 1 || amount > maxAmountMinor ? null : amount;
  }

  /// The whole part (still with its grouping) and the decimals of [text].
  (String?, String) _split(String text, String decimal, String group) {
    final parts = text.split(decimal);
    if (parts.length == 2) return (parts[0], parts[1]);
    if (parts.length > 2) return (null, '');
    // No locale decimal separator: the grouping one may be a decimal point
    // (`45.50`) when what follows it cannot be a group of three digits.
    final byGroup = text.split(group);
    if (byGroup.length == 2 &&
        byGroup[1].length != 3 &&
        byGroup[1].isNotEmpty &&
        byGroup[1].length <= minorDigits) {
      return (byGroup[0], byGroup[1]);
    }
    return (text, '');
  }

  /// `1.234.567`: groups of three after the first.
  bool _validGrouping(String whole, String group) {
    if (!whole.contains(group)) return true;
    final groups = whole.split(group);
    return groups.first.isNotEmpty &&
        groups.skip(1).every((g) => g.length == 3);
  }

  String _withoutCurrency(String text) {
    final symbol = _numberFormat(0).currencySymbol;
    return text.replaceAll(currency, '').replaceAll(symbol, '');
  }
}
