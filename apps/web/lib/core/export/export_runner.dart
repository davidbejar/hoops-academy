import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'csv_writer.dart';
import 'export_file_name.dart';
import 'export_table.dart';
import 'file_downloader.dart';
import 'ics_writer.dart';
import 'xlsx_loader.dart';
import 'xlsx_media_type.dart';

export 'xlsx_loader.dart' show XlsxUnavailable;

enum ExportFormat { csv, xlsx, ics }

/// What a screen wants exported: the table (CSV, XLSX) and, for the team
/// calendar, the ICS content. [day] is the academy's date for the file name.
class ExportJob {
  const ExportJob({
    required this.slug,
    required this.what,
    required this.day,
    required this.table,
    this.ics,
    this.notice,
  });

  final String slug;
  final String what;
  final DateTime day;
  final ExportTable table;
  final Uint8List Function()? ics;

  /// A localised note to show after the download (e.g. one source of the
  /// calendar could not be read).
  final String? notice;
}

/// There is no data to put in the file.
class NothingToExport implements Exception {
  const NothingToExport();
}

sealed class ExportOutcome {
  const ExportOutcome();
}

final class ExportSaved extends ExportOutcome {
  const ExportSaved(this.fileName);
  final String fileName;
}

/// Excel was asked for but its library could not be loaded.
final class ExportExcelUnavailable extends ExportOutcome {
  const ExportExcelUnavailable();
}

typedef XlsxBuilder = Future<Uint8List> Function(ExportTable table);

/// Builds the file for [ExportFormat] and hands it to the browser.
class ExportRunner {
  const ExportRunner({required this.downloader, required this.xlsx});

  final FileDownloader downloader;
  final XlsxBuilder xlsx;

  Future<ExportOutcome> run(ExportFormat format, ExportJob job) async {
    final (bytes, mediaType, extension) = switch (format) {
      ExportFormat.csv => (
        CsvWriter.encode(job.table),
        CsvWriter.mediaType,
        CsvWriter.extension,
      ),
      ExportFormat.ics => (_ics(job), IcsWriter.mediaType, IcsWriter.extension),
      ExportFormat.xlsx => (await _xlsx(job), xlsxMediaType, 'xlsx'),
    };
    if (bytes == null) return const ExportExcelUnavailable();
    final name = exportFileName(
      slug: job.slug,
      what: job.what,
      date: job.day,
      extension: extension,
    );
    downloader.save(fileName: name, bytes: bytes, mediaType: mediaType);
    return ExportSaved(name);
  }

  Uint8List _ics(ExportJob job) {
    final build = job.ics;
    if (build == null) {
      throw StateError('No calendar content for ${job.what}');
    }
    return build();
  }

  Future<Uint8List?> _xlsx(ExportJob job) async {
    try {
      return await xlsx(job.table);
    } on XlsxUnavailable {
      return null;
    }
  }
}

final fileDownloaderProvider = Provider<FileDownloader>(
  (_) => createBrowserDownloader(),
);

/// The Excel builder; tests replace it.
final xlsxBuilderProvider = Provider<XlsxBuilder>((_) => buildXlsxDeferred);

final exportRunnerProvider = Provider<ExportRunner>(
  (ref) => ExportRunner(
    downloader: ref.watch(fileDownloaderProvider),
    xlsx: ref.watch(xlsxBuilderProvider),
  ),
);
