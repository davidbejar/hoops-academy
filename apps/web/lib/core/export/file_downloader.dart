import 'dart:typed_data';

import 'file_downloader_stub.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart'
    as impl;

/// Hands a finished file to the browser's download. An interface so widget
/// tests record the file instead of clicking an anchor.
abstract class FileDownloader {
  void save({
    required String fileName,
    required Uint8List bytes,
    required String mediaType,
  });
}

/// The browser implementation (Blob + a temporary `<a download>`).
FileDownloader createBrowserDownloader() => impl.createDownloader();
