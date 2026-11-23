import 'package:dio/dio.dart';

import 'mock_core_api.dart';

/// Reading query parameters and building pages for the in-memory mocks (the generated clients send strings,
/// numbers, dates, lists or dio's `ListParam`, depending on the operation).
class MockQuery {
  const MockQuery(this._q);

  final Map<String, dynamic> _q;

  String? text(String key) {
    final v = _q[key];
    if (v == null) return null;
    final s = '$v';
    return s.isEmpty ? null : s;
  }

  int integer(String key, int fallback) =>
      int.tryParse(text(key) ?? '') ?? fallback;

  DateTime? instant(String key) {
    final v = _q[key];
    return v is DateTime ? v : DateTime.tryParse(text(key) ?? '');
  }

  /// A `YYYY-MM-DD` date as its text (dates compare correctly as text).
  String? date(String key) {
    final v = _q[key];
    final s = v is DateTime ? v.toIso8601String() : text(key);
    return s?.substring(0, 10);
  }

  /// A repeated or comma separated parameter.
  Set<String> set(String key) {
    var v = _q[key];
    if (v is ListParam) v = v.value;
    if (v == null) return const {};
    final parts = v is Iterable ? v.map((e) => '$e') : '$v'.split(',');
    return {
      for (final p in parts)
        if (p.isNotEmpty) p,
    };
  }

  /// One page of [items] as the contract's `*Page` shape, paged like the services (`Page` and `Size` in
  /// common.yaml): 0-based `page`, `size` 1..200 with 50 by default; anything else is a 400.
  MockResult page(List<Object?> items) {
    final size = integer('size', 50);
    final page = integer('page', 0);
    if (page < 0 || size < 1 || size > 200) {
      return mockProblem(400, 'Bad Request');
    }
    final totalPages = items.isEmpty ? 0 : (items.length + size - 1) ~/ size;
    final from = (page * size).clamp(0, items.length);
    final to = (from + size).clamp(0, items.length);
    return MockResult.json(200, {
      'items': items.sublist(from, to),
      'page': {
        'page': page,
        'size': size,
        'totalElements': items.length,
        'totalPages': totalPages,
      },
    });
  }
}

MockResult mockProblem(int status, String title, {String? code}) =>
    MockResult.json(status, {
      'type': 'urn:hoops:problem:mock',
      'title': title,
      'status': status,
      'code': ?code,
    });

/// `clear` of the update requests (ADR-0032): the names of the properties to set to null.
Set<String> mockClear(Map<String, Object?> body) => {
  for (final e in (body['clear'] as List<Object?>? ?? const [])) '$e',
};

/// Applies an update body to [target]: given properties replace, `clear` ones become null, the rest stays.
/// A property both given and cleared is a 400 (returned), otherwise null.
MockResult? mockApplyUpdate(
  Map<String, Object?> target,
  Map<String, Object?> body, {
  Set<String> clearable = const {},
}) {
  final clear = mockClear(body);
  for (final name in clear) {
    if (!clearable.contains(name)) return mockProblem(400, 'Bad Request');
    if (body[name] != null) return mockProblem(400, 'Bad Request');
  }
  for (final e in body.entries) {
    if (e.key == 'clear' || e.value == null) continue;
    target[e.key] = e.value;
  }
  for (final name in clear) {
    target[name] = null;
  }
  return null;
}

/// The audit events of [events] a trail request selects (core `listAuditEvents` / `listPlatformAuditEvents`): `from`
/// inclusive, `to` exclusive, any of the `action`s; `from` not before `to` is a 400 (returned instead).
(List<Map<String, Object?>>, MockResult?) mockAuditMatching(
  Iterable<Map<String, Object?>> events,
  MockQuery q,
) {
  final from = q.instant('from');
  final to = q.instant('to');
  if (from != null && to != null && !from.isBefore(to)) {
    return (const [], mockProblem(400, 'Bad Request'));
  }
  final actions = q.set('action');
  return (
    [
      for (final e in events)
        if ((actions.isEmpty || actions.contains(e['action'])) &&
            (from == null || !DateTime.parse('${e['at']}').isBefore(from)) &&
            (to == null || DateTime.parse('${e['at']}').isBefore(to)))
          e,
    ],
    null,
  );
}
