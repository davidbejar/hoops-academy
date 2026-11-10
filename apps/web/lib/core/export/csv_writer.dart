import 'dart:convert';
import 'dart:typed_data';

import 'export_table.dart';
import 'formula_guard.dart';

/// CSV per RFC 4180 for the exports: UTF-8 with a byte order mark (Excel then
/// opens accents correctly), `,` separator, CRLF after every record, a field
/// is quoted when it holds `,`, `"`, CR or LF and its quotes are doubled.
class CsvWriter {
  const CsvWriter._();

  static const mediaType = 'text/csv; charset=utf-8';
  static const extension = 'csv';

  static const _bom = '﻿';

  static String write(ExportTable table) {
    final out = StringBuffer(_bom);
    _record(out, [for (final h in table.headers) guardFormula(h)]);
    for (final row in table.rows) {
      _record(out, [for (final cell in row) _text(cell)]);
    }
    return out.toString();
  }

  static Uint8List encode(ExportTable table) =>
      Uint8List.fromList(utf8.encode(write(table)));

  static String _text(ExportCell cell) => switch (cell) {
    TextCell(:final value) => guardFormula(value),
    NumberCell(:final value) => '$value',
    DateCell(:final value) => isoDate(value),
    TimeCell(:final hour, :final minute) => isoTime(hour, minute),
    EmptyCell() => '',
  };

  static void _record(StringBuffer out, List<String> fields) {
    out
      ..writeAll(fields.map(_field), ',')
      ..write('\r\n');
  }

  static String _field(String value) {
    final needsQuotes =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\r') ||
        value.contains('\n');
    return needsQuotes ? '"${value.replaceAll('"', '""')}"' : value;
  }
}
