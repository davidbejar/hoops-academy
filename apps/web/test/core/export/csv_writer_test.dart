import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/export/csv_writer.dart';
import 'package:hoops_app/core/export/export_table.dart';

ExportTable table(List<List<ExportCell>> rows, {List<String>? headers}) =>
    ExportTable(
      sheetName: 'Sheet',
      headers: headers ?? const ['a', 'b'],
      rows: rows,
    );

void main() {
  test('media type and extension', () {
    expect(CsvWriter.mediaType, 'text/csv; charset=utf-8');
  });

  test('the file starts with the UTF-8 byte order mark', () {
    final bytes = CsvWriter.encode(table(const []));
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
  });

  test('header row, comma separator, CRLF after every record', () {
    final text = CsvWriter.write(
      table([
        [const TextCell('x'), const NumberCell(1)],
        [const TextCell('y'), const NumberCell(2)],
      ]),
    );
    expect(text, '﻿a,b\r\nx,1\r\ny,2\r\n');
  });

  test('an empty table is the header row only', () {
    expect(CsvWriter.write(table(const [])), '﻿a,b\r\n');
  });

  group('RFC 4180 quoting', () {
    String one(String value) => CsvWriter.write(
      table([
        [TextCell(value), const EmptyCell()],
      ]),
    ).substring('﻿a,b\r\n'.length);

    test('a comma', () => expect(one('a,b'), '"a,b",\r\n'));
    test(
      'a quote is doubled',
      () => expect(one('say "hi"'), '"say ""hi""",\r\n'),
    );
    test('a line feed', () => expect(one('a\nb'), '"a\nb",\r\n'));
    test('a carriage return', () => expect(one('a\rb'), '"a\rb",\r\n'));
    test('plain text stays bare', () => expect(one('Ana'), 'Ana,\r\n'));
    test('header labels are quoted too', () {
      final text = CsvWriter.write(
        table(const [], headers: ['Pts, total', 'b']),
      );
      expect(text, '﻿"Pts, total",b\r\n');
    });
  });

  group('formula-injection guard', () {
    test('text that starts with a trigger gets a leading apostrophe', () {
      final text = CsvWriter.write(
        table([
          [const TextCell('=1+1'), const TextCell('@x')],
          [const TextCell('+1'), const TextCell('-3')],
        ]),
      );
      expect(text, "﻿a,b\r\n'=1+1,'@x\r\n'+1,'-3\r\n");
    });

    test('a number keeps its minus sign', () {
      final text = CsvWriter.write(
        table([
          [const NumberCell(-3), const NumberCell(-1.5)],
        ]),
      );
      expect(text, '﻿a,b\r\n-3,-1.5\r\n');
    });

    test('the guard runs before the quoting', () {
      final text = CsvWriter.write(
        table([
          [const TextCell('=a,b'), const EmptyCell()],
        ]),
      );
      expect(text, "﻿a,b\r\n\"'=a,b\",\r\n");
    });
  });

  group('typed cells', () {
    test('dates are ISO, times HH:mm, decimals use a point', () {
      final text = CsvWriter.write(
        table([
          [DateCell(DateTime(2026, 3, 7)), const TimeCell(9, 5)],
          [const NumberCell(12.5), const NumberCell(7)],
        ]),
      );
      expect(text, '﻿a,b\r\n2026-03-07,09:05\r\n12.5,7\r\n');
    });

    test('a whole decimal has no trailing .0', () {
      final text = CsvWriter.write(
        table([
          [const NumberCell(12.0), const NumberCell(0.5)],
        ]),
      );
      expect(text, '\uFEFFa,b\r\n12,0.5\r\n');
    });

    test('non-ASCII text survives the UTF-8 round trip', () {
      final bytes = CsvWriter.encode(
        table([
          [const TextCell('Peña — Müller 李'), const EmptyCell()],
        ]),
      );
      expect(utf8.decode(bytes.sublist(3)), contains('Peña — Müller 李'));
    });
  });
}
