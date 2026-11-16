import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A file the server made: its bytes and the name it gave in
/// `Content-Disposition` (null when it sent none we may trust).
class ServerFile {
  const ServerFile(this.bytes, {this.fileName});

  /// The bytes of [response] with the name of its `Content-Disposition`.
  factory ServerFile.of(Response<Uint8List> response) => ServerFile(
    response.data!,
    fileName: fileNameOfDisposition(
      response.headers.value('content-disposition'),
    ),
  );

  final Uint8List bytes;
  final String? fileName;
}

final _plainName = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
final _filename = RegExp(r'filename=("([^"]*)"|[^;\s]+)', caseSensitive: false);

/// The `filename` of a `Content-Disposition`, only when it is a plain file
/// name (letters, digits, dot, dash, underscore): the browser's `download`
/// attribute never gets a path or odd characters from a header.
String? fileNameOfDisposition(String? header) {
  final match = header == null ? null : _filename.firstMatch(header);
  if (match == null) return null;
  final name = match.group(2) ?? match.group(1)!;
  return _plainName.hasMatch(name) && !name.contains('..') ? name : null;
}
