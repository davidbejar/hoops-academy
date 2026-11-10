/// The format-neutral shape of a browser-built export (WP97, ADR-0048): a
/// header row and typed cells. CSV and XLSX are two writers over it.
///
/// Pure Dart, no Flutter imports (a test enforces it), so the writers run in
/// plain unit tests.
library;

/// One cell. The type decides how a writer shows it: text is guarded against
/// spreadsheet formulas, numbers are written as numbers, dates and times are
/// typed in XLSX and ISO text in CSV.
sealed class ExportCell {
  const ExportCell();
}

final class TextCell extends ExportCell {
  const TextCell(this.value);
  final String value;
}

final class NumberCell extends ExportCell {
  const NumberCell(this.value);
  final num value;
}

/// A calendar date (the academy's wall date); the time part is ignored.
final class DateCell extends ExportCell {
  const DateCell(this.value);
  final DateTime value;
}

/// A wall-clock time of day.
final class TimeCell extends ExportCell {
  const TimeCell(this.hour, this.minute);
  final int hour;
  final int minute;
}

final class EmptyCell extends ExportCell {
  const EmptyCell();
}

/// A header row and the data rows of one sheet.
class ExportTable {
  const ExportTable({
    required this.sheetName,
    required this.headers,
    required this.rows,
  });

  /// The XLSX sheet's name (CSV has none).
  final String sheetName;
  final List<String> headers;
  final List<List<ExportCell>> rows;
}

/// `yyyy-MM-dd`.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

/// `HH:mm`.
String isoTime(int hour, int minute) => '${_two(hour)}:${_two(minute)}';

String _two(int n) => n.toString().padLeft(2, '0');
