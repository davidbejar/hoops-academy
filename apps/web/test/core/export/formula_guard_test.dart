import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/export/formula_guard.dart';

void main() {
  group('guardFormula', () {
    for (final lead in ['=', '+', '-', '@', '\t', '\r']) {
      test('prefixes a value that starts with ${lead.codeUnitAt(0)}', () {
        expect(guardFormula('${lead}SUM(A1)'), "'${lead}SUM(A1)");
      });
    }

    test('leaves ordinary text alone', () {
      expect(guardFormula('Ana García'), 'Ana García');
      expect(guardFormula("O'Neil"), "O'Neil");
      expect(guardFormula(''), '');
    });

    test('only the first character counts', () {
      expect(guardFormula('a=b'), 'a=b');
      expect(guardFormula(' =1+1'), ' =1+1');
    });

    test('a spreadsheet hyperlink payload is neutralised', () {
      expect(
        guardFormula('=HYPERLINK("http://evil","x")'),
        "'=HYPERLINK(\"http://evil\",\"x\")",
      );
    });
  });
}
