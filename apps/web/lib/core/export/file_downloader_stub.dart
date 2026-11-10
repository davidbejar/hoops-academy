import 'dart:typed_data';

import 'file_downloader.dart';

/// No browser (tests, native tooling): saving is not possible.
class UnsupportedFileDownloader implements FileDownloader {
  const UnsupportedFileDownloader();

  @override
  void save({
    required String fileName,
    required Uint8List bytes,
    required String mediaType,
  }) => throw UnsupportedError('File downloads need a browser');
}

FileDownloader createDownloader() => const UnsupportedFileDownloader();
