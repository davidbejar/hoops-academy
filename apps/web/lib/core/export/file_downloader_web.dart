import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'file_downloader.dart';

/// Blob + object URL + a temporary anchor with the `download` attribute (the
/// file never touches a server).
class BlobFileDownloader implements FileDownloader {
  const BlobFileDownloader();

  @override
  void save({
    required String fileName,
    required Uint8List bytes,
    required String mediaType,
  }) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mediaType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    // The download has started synchronously; free the blob afterwards.
    Future<void>.delayed(
      const Duration(seconds: 1),
      () => web.URL.revokeObjectURL(url),
    );
  }
}

FileDownloader createDownloader() => const BlobFileDownloader();
