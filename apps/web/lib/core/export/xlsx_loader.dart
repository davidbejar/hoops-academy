import 'dart:typed_data';

import 'export_table.dart';
import 'xlsx_writer.dart' deferred as xlsx;

/// The Excel library could not be fetched (offline on first use): the screen
/// says so and CSV stays available.
class XlsxUnavailable implements Exception {
  const XlsxUnavailable(this.reason);
  final Object reason;

  @override
  String toString() => 'XlsxUnavailable($reason)';
}

/// Builds an XLSX file. The Excel package sits in a deferred part of the web
/// build (decision 69): it is downloaded here, at the moment the person picks
/// Excel, never at start-up, and it is not in the service worker's precache.
Future<Uint8List> buildXlsxDeferred(ExportTable table) async {
  try {
    await xlsx.loadLibrary();
  } on Object catch (e) {
    throw XlsxUnavailable(e);
  }
  return xlsx.XlsxWriter.build(table);
}
