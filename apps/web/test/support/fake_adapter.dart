import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Records requests and answers from a queue of canned responses.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this._responses);

  final List<FakeResponse> _responses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final r = _responses.length > 1 ? _responses.removeAt(0) : _responses.first;
    if (r.networkError) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      r.body,
      r.status,
      headers: {
        Headers.contentTypeHeader: [r.contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeResponse {
  const FakeResponse(
    this.status,
    this.body, {
    this.contentType = 'application/json',
    this.networkError = false,
  });

  const FakeResponse.network()
    : status = 0,
      body = '',
      contentType = '',
      networkError = true;

  factory FakeResponse.problem(int status, Map<String, Object?> json) =>
      FakeResponse(
        status,
        jsonEncode(json),
        contentType: 'application/problem+json',
      );

  final int status;
  final String body;
  final String contentType;
  final bool networkError;
}
