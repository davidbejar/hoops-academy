import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/time/dates.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final day = DateTime(2026, 3, 7, 18, 45);

  setUpAll(initializeDateFormatting);

  test('ISO text is zero padded, also for a short year', () {
    expect(isoDate(day), '2026-03-07');
    expect(isoDateOf(98, 1, 2), '0098-01-02');
    expect(compactDate(day), '20260307');
  });

  test('the compact styles of training, health and charts', () {
    expect(shortDate(day), '07/03');
    expect(fullDate(toAthDate(day)), '07/03/2026');
    expect(chartDate(day), '07/03/26');
  });

  test('every client gets the same calendar day', () {
    expect(formatDate(toApiDate(day)), '2026-03-07');
    expect(toFinDate(day).toDateTime(), DateTime(2026, 3, 7));
    expect(toAthDate(day).toDateTime(), DateTime(2026, 3, 7));
  });

  test('the locale decides the text of displayDate', () {
    expect(displayDate('en', day), 'Mar 7, 2026');
    expect(displayDate('es', day), '7 mar 2026');
    expect(displayDateTime('en', day), 'Mar 7, 2026 18:45');
  });
}
