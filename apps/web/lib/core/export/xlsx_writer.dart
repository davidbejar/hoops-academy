import 'dart:typed_data';

import 'package:excel_community/excel_community.dart' as xl;

import 'export_table.dart';
import 'formula_guard.dart';

/// XLSX for the Excel export. This is the only file that imports the Excel
/// package, and it is reached only through the deferred import in
/// `xlsx_loader.dart`, so the library stays out of the main bundle and out of
/// the service worker's precache (decision 69).
class XlsxWriter {
  const XlsxWriter._();

  static const mediaType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const extension = 'xlsx';

  static Uint8List build(ExportTable table) {
    final book = xl.Excel.createExcel();
    final name = legalSheetName(table.sheetName);
    final defaultName = book.getDefaultSheet() ?? 'Sheet1';
    book.rename(defaultName, name);
    final sheet = book[name];
    final header = xl.CellStyle(bold: true);
    sheet.appendRow([for (final h in table.headers) _text(h)]);
    for (var c = 0; c < table.headers.length; c++) {
      sheet
              .cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
              .cellStyle =
          header;
    }
    for (final row in table.rows) {
      sheet.appendRow([for (final cell in row) _value(cell)]);
    }
    return Uint8List.fromList(book.encode()!);
  }

  static xl.CellValue _text(String s) => xl.TextCellValue(guardFormula(s));

  static xl.CellValue? _value(ExportCell cell) => switch (cell) {
    TextCell(:final value) => _text(value),
    NumberCell(:final value) =>
      value is int
          ? xl.IntCellValue(value)
          : xl.DoubleCellValue(value.toDouble()),
    DateCell(:final value) => xl.DateCellValue.fromDateTime(value),
    TimeCell(:final hour, :final minute) => xl.TimeCellValue(
      hour: hour,
      minute: minute,
    ),
    EmptyCell() => null,
  };

  /// Excel allows 31 characters and none of `: \ / ? * [ ]`.
  static String legalSheetName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[:\\/?*\[\]]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 'Sheet1';
    return cleaned.length <= 31 ? cleaned : cleaned.substring(0, 31).trim();
  }
}
