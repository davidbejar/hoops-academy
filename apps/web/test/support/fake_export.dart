import 'dart:convert';
import 'dart:typed_data';

import 'package:hoops_app/core/export/export_runner.dart';
import 'package:hoops_app/core/export/export_table.dart';
import 'package:hoops_app/core/export/file_downloader.dart';

/// One file the app handed to the browser.
class SavedFile {
  const SavedFile(this.fileName, this.bytes, this.mediaType);
  final String fileName;
  final Uint8List bytes;
  final String mediaType;
}

/// Records downloads instead of clicking an anchor.
class FakeFileDownloader implements FileDownloader {
  final saved = <SavedFile>[];

  @override
  void save({
    required String fileName,
    required Uint8List bytes,
    required String mediaType,
  }) => saved.add(SavedFile(fileName, bytes, mediaType));
}

/// An XLSX builder for widget tests: no library load, a marker payload; or an
/// offline failure.
XlsxBuilder fakeXlsx({bool offline = false}) => (ExportTable table) async {
  if (offline) throw const XlsxUnavailable('offline');
  return Uint8List.fromList(utf8.encode('xlsx:${table.sheetName}'));
};
