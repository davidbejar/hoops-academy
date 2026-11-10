import 'package:excel_community/excel_community.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/export/export_table.dart';
import 'package:hoops_app/core/export/xlsx_writer.dart';

xl.Sheet read(ExportTable t) {
  final book = xl.Excel.decodeBytes(XlsxWriter.build(t));
  return book.tables.values.single;
}

void main() {
  final table = ExportTable(
    sheetName: 'Stats',
    headers: const ['Name', 'Date', 'Pts', 'Time'],
    rows: [
      [
        const TextCell('Ana'),
        DateCell(DateTime(2026, 3, 7)),
        const NumberCell(-3),
        const TimeCell(9, 5),
      ],
      [
        const TextCell('=1+1'),
        const EmptyCell(),
        const NumberCell(12.5),
        const EmptyCell(),
      ],
    ],
  );

  test('media type', () {
    expect(
      XlsxWriter.mediaType,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  });

  test('is a zip (xlsx) with one sheet named after the table', () {
    final bytes = XlsxWriter.build(table);
    expect(bytes.take(2), [0x50, 0x4B]);
    final book = xl.Excel.decodeBytes(bytes);
    expect(book.tables.keys, ['Stats']);
  });

  test('header row first', () {
    final sheet = read(table);
    expect(sheet.rows.first.map((c) => c?.value.toString()), [
      'Name',
      'Date',
      'Pts',
      'Time',
    ]);
  });

  test('dates are typed date cells, not text', () {
    final cell = read(table).rows[1][1]!;
    expect(cell.value, isA<xl.DateCellValue>());
    final v = cell.value as xl.DateCellValue;
    expect((v.year, v.month, v.day), (2026, 3, 7));
  });

  test('times are typed time cells', () {
    final cell = read(table).rows[1][3]!;
    expect(cell.value, isA<xl.TimeCellValue>());
    final v = cell.value as xl.TimeCellValue;
    expect((v.hour, v.minute), (9, 5));
  });

  test('numbers are numbers, a negative one is not guarded', () {
    final sheet = read(table);
    expect(sheet.rows[1][2]!.value, isA<xl.IntCellValue>());
    expect((sheet.rows[1][2]!.value as xl.IntCellValue).value, -3);
    expect(sheet.rows[2][2]!.value, isA<xl.DoubleCellValue>());
    expect((sheet.rows[2][2]!.value as xl.DoubleCellValue).value, 12.5);
  });

  test('text that looks like a formula is guarded', () {
    final cell = read(table).rows[2][0]!;
    expect(cell.value, isA<xl.TextCellValue>());
    expect(cell.value.toString(), "'=1+1");
  });

  test('empty cells stay empty', () {
    final sheet = read(table);
    expect(sheet.rows[2][1]?.value, isNull);
  });

  test('the sheet name is made legal (31 characters, no : / ? * [ ] \\)', () {
    final name = XlsxWriter.legalSheetName('Box score: Ana/Bea? [A] ' * 3);
    expect(name.length, lessThanOrEqualTo(31));
    expect(name, isNot(matches(r'[:\\/?*\[\]]')));
    expect(XlsxWriter.legalSheetName('   '), 'Sheet1');
  });
}
