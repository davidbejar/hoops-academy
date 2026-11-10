import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/export/export_runner.dart';
import 'package:hoops_app/core/export/export_table.dart';
import 'package:hoops_app/core/export/xlsx_loader.dart';

import '../../support/fake_export.dart';

const table = ExportTable(
  sheetName: 'Stats',
  headers: ['a'],
  rows: [
    [TextCell('x')],
  ],
);

ExportJob job({Uint8List Function()? ics}) => ExportJob(
  slug: 'cb-norte',
  what: 'player-stats',
  day: DateTime(2026, 11, 5),
  table: table,
  ics: ics,
);

void main() {
  late FakeFileDownloader downloader;

  setUp(() => downloader = FakeFileDownloader());

  ExportRunner runner({bool offline = false}) => ExportRunner(
    downloader: downloader,
    xlsx: fakeXlsx(offline: offline),
  );

  test('CSV: saved under the rule-based name with its media type', () async {
    final outcome = await runner().run(ExportFormat.csv, job());
    expect(outcome, isA<ExportSaved>());
    final file = downloader.saved.single;
    expect(file.fileName, 'hoops-cb-norte-player-stats-20261105.csv');
    expect(file.mediaType, 'text/csv; charset=utf-8');
    expect(utf8.decode(file.bytes.sublist(3)), 'a\r\nx\r\n');
  });

  test('Excel: built by the (deferred) builder, xlsx name and type', () async {
    final outcome = await runner().run(ExportFormat.xlsx, job());
    expect((outcome as ExportSaved).fileName, endsWith('-20261105.xlsx'));
    final file = downloader.saved.single;
    expect(
      file.mediaType,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    expect(utf8.decode(file.bytes), 'xlsx:Stats');
  });

  test(
    'Excel that cannot be loaded: a message outcome, nothing saved',
    () async {
      final outcome = await runner(offline: true).run(ExportFormat.xlsx, job());
      expect(outcome, isA<ExportExcelUnavailable>());
      expect(downloader.saved, isEmpty);
    },
  );

  test('CSV still works after Excel failed', () async {
    final r = runner(offline: true);
    await r.run(ExportFormat.xlsx, job());
    expect(await r.run(ExportFormat.csv, job()), isA<ExportSaved>());
    expect(downloader.saved, hasLength(1));
  });

  test('Calendar: the job brings the ICS bytes', () async {
    final outcome = await runner().run(
      ExportFormat.ics,
      job(ics: () => Uint8List.fromList(utf8.encode('BEGIN:VCALENDAR\r\n'))),
    );
    expect((outcome as ExportSaved).fileName, endsWith('.ics'));
    expect(downloader.saved.single.mediaType, 'text/calendar; charset=utf-8');
  });

  test('Calendar without ICS content is a programming error', () {
    expect(
      () => runner().run(ExportFormat.ics, job()),
      throwsA(isA<StateError>()),
    );
  });

  test('the real deferred loader builds a workbook', () async {
    final bytes = await buildXlsxDeferred(table);
    expect(bytes.take(2), [0x50, 0x4B]);
  });

  group('Excel stays in a deferred part', () {
    final lib = Directory('lib');
    final sources = [
      for (final f in lib.listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f,
    ];

    test('only xlsx_loader imports the writer, and deferred', () {
      final importers = {
        for (final f in sources)
          if (RegExp(
            r'''^(import|export) .*xlsx_writer\.dart''',
            multiLine: true,
          ).hasMatch(f.readAsStringSync()))
            f.path: f.readAsStringSync(),
      };
      expect(importers.keys.map((p) => p.split('/').last), [
        'xlsx_loader.dart',
      ]);
      expect(importers.values.single, contains('deferred as'));
    });

    test('nothing else imports the Excel package', () {
      final importers = [
        for (final f in sources)
          if (f.readAsStringSync().contains('package:excel_community'))
            f.path.split('/').last,
      ];
      expect(importers, ['xlsx_writer.dart']);
    });

    test('the builders import no Flutter code', () {
      for (final name in [
        'export_table',
        'formula_guard',
        'csv_writer',
        'export_file_name',
        'ics_writer',
        'xlsx_writer',
      ]) {
        final text = File('lib/core/export/$name.dart').readAsStringSync();
        expect(text, isNot(contains('package:flutter')), reason: name);
        expect(text, isNot(contains('dart:ui')), reason: name);
      }
    });
  });
}
