import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/ui/validators.dart';
import 'package:hoops_app/l10n/gen/app_localizations.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('es'));

  group('email', () {
    test(
      'isValidEmail: local part, @, dotted domain; the ends are trimmed',
      () {
        expect(isValidEmail('ana@club.es'), isTrue);
        expect(isValidEmail('  ana@club.es '), isTrue);
        for (final bad in ['', 'ana', 'ana@club', '@club.es', 'a b@club.es']) {
          expect(isValidEmail(bad), isFalse, reason: bad);
        }
      },
    );

    test('emailValidator needs a valid address', () {
      expect(emailValidator(l, 'ana@club.es'), isNull);
      expect(emailValidator(l, ''), l.fieldInvalidEmail);
      expect(emailValidator(l, null), l.fieldInvalidEmail);
      expect(emailValidator(l, 'ana'), l.fieldInvalidEmail);
    });

    test('optionalEmailValidator lets a blank through', () {
      expect(optionalEmailValidator(l, ''), isNull);
      expect(optionalEmailValidator(l, '  '), isNull);
      expect(optionalEmailValidator(l, null), isNull);
      expect(optionalEmailValidator(l, 'ana@club.es'), isNull);
      expect(optionalEmailValidator(l, 'ana'), l.fieldInvalidEmail);
    });
  });

  group('decimals', () {
    test('parseDecimal reads a comma or a point and trims', () {
      expect(parseDecimal('149,5'), 149.5);
      expect(parseDecimal(' 38.5 '), 38.5);
      expect(parseDecimal('12'), 12);
      expect(parseDecimal(''), isNull);
      expect(parseDecimal(null), isNull);
      expect(parseDecimal('abc'), isNull);
    });

    test('decimalValidator needs a number', () {
      expect(decimalValidator(l, '1,5'), isNull);
      expect(decimalValidator(l, ''), l.fieldInvalidNumber);
      expect(decimalValidator(l, 'x'), l.fieldInvalidNumber);
    });

    test('optionalDecimalValidator allows a blank, positive can be asked', () {
      expect(optionalDecimalValidator(l, ''), isNull);
      expect(optionalDecimalValidator(l, '0'), isNull);
      expect(optionalDecimalValidator(l, '-1'), isNull);
      expect(optionalDecimalValidator(l, 'x'), l.fieldInvalidNumber);
      expect(
        optionalDecimalValidator(l, '0', positive: true),
        l.fieldInvalidNumber,
      );
      expect(
        optionalDecimalValidator(l, '-1', positive: true),
        l.fieldInvalidNumber,
      );
      expect(optionalDecimalValidator(l, '1,2', positive: true), isNull);
    });
  });

  test('blankToNull trims and turns a blank into null', () {
    expect(blankToNull('  hola '), 'hola');
    expect(blankToNull('   '), isNull);
    expect(blankToNull(''), isNull);
    expect(blankToNull(null), isNull);
  });

  test('requiredValidator still lives next to them', () {
    expect(requiredValidator(l, ' '), l.fieldRequired);
    expect(requiredValidator(l, 'x'), isNull);
  });

  group('formatMeasure', () {
    test(
      'a whole value has no decimals, others at most two, no tail zeros',
      () {
        expect(formatMeasure(148), '148');
        expect(formatMeasure(12.5), '12.5');
        expect(formatMeasure(37.55), '37.55');
        expect(formatMeasure(12.3456), '12.35');
        expect(formatMeasure(0.1 + 0.2), '0.3');
      },
    );
  });
}
