import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/export/server_file.dart';

void main() {
  group('file name of a Content-Disposition', () {
    test('reads the quoted name', () {
      expect(
        fileNameOfDisposition(
          'attachment; filename="hoops-demo-roster-mini-a-20261116.pdf"',
        ),
        'hoops-demo-roster-mini-a-20261116.pdf',
      );
    });

    test('reads an unquoted name', () {
      expect(
        fileNameOfDisposition('attachment; filename=sheet.pdf'),
        'sheet.pdf',
      );
    });

    test('no header or no name gives null', () {
      expect(fileNameOfDisposition(null), isNull);
      expect(fileNameOfDisposition('attachment'), isNull);
    });

    test('a name that is not a plain file name is refused', () {
      expect(
        fileNameOfDisposition('attachment; filename="../../etc/passwd"'),
        isNull,
      );
      expect(fileNameOfDisposition('attachment; filename="a b.pdf"'), isNull);
      expect(fileNameOfDisposition('attachment; filename=""'), isNull);
    });
  });
}
