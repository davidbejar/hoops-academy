import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers every list `GET` the way the services page it (ADR-0061): `size`
/// 1..200 (default 50; anything else is a 400, as `PageOffset` refuses it),
/// 0-based `page`, `totalPages` from the count. The list holds [count] copies
/// of one item with distinct `id` / `personId`: [template] when given,
/// otherwise the first item [inner] answers for the same request (so the
/// copies have the shape the generated client expects). Other methods go to
/// [inner] unchanged.
class ServerPagesAdapter implements HttpClientAdapter {
  ServerPagesAdapter({required this.count, this.template, this.inner})
    : assert(template != null || inner != null);

  final int count;
  final Map<String, Object?>? template;
  final HttpClientAdapter? inner;

  /// Every page served, in order.
  final List<({String path, int page, int size})> served = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method.toUpperCase() != 'GET') {
      return inner!.fetch(options, requestStream, cancelFuture);
    }
    final item = template ?? await _firstItem(options, cancelFuture);
    final q = options.queryParameters;
    final page = int.parse('${q['page'] ?? 0}');
    final size = int.parse('${q['size'] ?? 50}');
    if (page < 0 || size < 1 || size > 200) {
      return _json(400, {'title': 'Bad Request', 'status': 400});
    }
    served.add((path: options.path, page: page, size: size));
    final from = (page * size).clamp(0, count);
    final to = (from + size).clamp(0, count);
    return _json(200, {
      'items': [for (var i = from; i < to; i++) _copy(item, i)],
      'page': {
        'page': page,
        'size': size,
        'totalElements': count,
        'totalPages': (count + size - 1) ~/ size,
      },
    });
  }

  /// The first item of [inner]'s list for this request (a test error when it is not a list or is empty).
  Future<Map<String, Object?>> _firstItem(
    RequestOptions options,
    Future<void>? cancelFuture,
  ) async {
    final probe = options.copyWith(
      queryParameters: {...options.queryParameters, 'page': 0, 'size': 1},
    );
    final body = await inner!.fetch(probe, null, cancelFuture);
    final bytes = await body.stream.fold<List<int>>([], (a, b) => a..addAll(b));
    final json = jsonDecode(utf8.decode(bytes));
    if (json is! Map || json['items'] is! List || json['page'] is! Map) {
      throw StateError('${options.path} is not a list operation');
    }
    final items = json['items'] as List;
    if (items.isEmpty) {
      throw StateError('no ${options.path} item to copy');
    }
    return (items.first as Map).cast<String, Object?>();
  }

  static Map<String, Object?> _copy(Map<String, Object?> item, int i) => {
    ...item,
    for (final key in const ['id', 'personId'])
      if (item[key] != null) key: '${item[key]}~$i',
  };

  static ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [
        status < 400 ? 'application/json' : 'application/problem+json',
      ],
    },
  );

  @override
  void close({bool force = false}) {}
}
