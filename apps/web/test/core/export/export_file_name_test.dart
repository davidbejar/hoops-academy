import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/export/export_file_name.dart';

void main() {
  test('hoops-<slug>-<what>-<yyyyMMdd>.<ext>', () {
    expect(
      exportFileName(
        slug: 'cb-norte',
        what: 'box-score',
        date: DateTime(2026, 11, 5),
        extension: 'csv',
      ),
      'hoops-cb-norte-box-score-20261105.csv',
    );
  });

  test('ASCII only: accents fold, everything else becomes a dash', () {
    expect(
      exportFileName(
        slug: 'Peña / Müller',
        what: 'Estadísticas: Ana García',
        date: DateTime(2026, 1, 2),
        extension: 'xlsx',
      ),
      'hoops-pena-muller-estadisticas-ana-garcia-20260102.xlsx',
    );
  });

  test('characters outside Latin never reach the name', () {
    final name = exportFileName(
      slug: '李 academy',
      what: 'calendar',
      date: DateTime(2026, 1, 2),
      extension: 'ics',
    );
    expect(name, 'hoops-academy-calendar-20260102.ics');
    expect(RegExp(r'^[a-z0-9.\-]+$').hasMatch(name), isTrue);
  });

  test('an empty slug falls back to "academy"', () {
    expect(
      exportFileName(
        slug: '',
        what: 'calendar',
        date: DateTime(2026, 1, 2),
        extension: 'ics',
      ),
      'hoops-academy-calendar-20260102.ics',
    );
  });

  test('path separators and dots cannot escape the name', () {
    final name = exportFileName(
      slug: '../../etc',
      what: 'x\\y',
      date: DateTime(2026, 1, 2),
      extension: 'csv',
    );
    expect(name, 'hoops-etc-x-y-20260102.csv');
  });
}
