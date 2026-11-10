import 'dart:convert';
import 'dart:typed_data';

import 'mock_core_api.dart';
import 'mock_store.dart';

/// One call to a mock, as it was made (and as it is replayed).
class MockRequest {
  const MockRequest(
    this.method,
    this.path,
    this.query,
    this.body,
    this.bytes, {
    this.language,
  });

  final String method;
  final String path;
  final Map<String, dynamic> query;
  final Object? body;
  final Uint8List? bytes;

  /// `Accept-Language`: a quick-add copies a global exercise in it (athlete 3.0.0).
  final String? language;
}

/// What the user changed in a demo mock: every call that changed something and succeeded, in order, kept in a
/// [MockStore]. A new mock replays the log over its seed, which gives back the same state (ids, jersey numbers,
/// the logo) without each mock having to serialise its own fields. Reads and failed calls are never stored.
class MockStateLog {
  MockStateLog(this._store, this._key);

  final MockStore _store;
  final String _key;
  final List<Map<String, Object?>> _entries = [];

  /// Applies the stored calls through [apply]; one that no longer works (the mock changed, or a corrupt
  /// log) is dropped so the rest still comes back.
  void replay(MockResult? Function(MockRequest request) apply) {
    final stored = _store.read(_key);
    if (stored == null) return;
    final List<Object?> decoded;
    try {
      decoded = jsonDecode(stored) as List<Object?>;
    } on Object {
      return;
    }
    for (final raw in decoded) {
      try {
        final e = (raw! as Map).cast<String, Object?>();
        final bytes = e['x'] as String?;
        final result = apply(
          MockRequest(
            e['m']! as String,
            e['p']! as String,
            ((e['q'] as Map?) ?? const {}).cast<String, dynamic>(),
            e['b'],
            bytes == null ? null : base64Decode(bytes),
            language: e['l'] as String?,
          ),
        );
        if (result != null && result.status < 400) _entries.add(e);
      } on Object {
        continue;
      }
    }
  }

  /// Keeps the call when it changed something: not a read, and [result] succeeded.
  void record(
    String method,
    String path,
    Map<String, dynamic> query,
    Object? body,
    MockResult? result, {
    Uint8List? bytes,
    String? language,
  }) {
    if (method == 'GET' || result == null || result.status >= 400) return;
    _entries.add({
      'm': method,
      'p': path,
      if (query.isNotEmpty) 'q': query,
      if (body is Map || body is List || body is String) 'b': body,
      if (bytes != null) 'x': base64Encode(bytes),
      'l': ?language,
    });
    try {
      _store.write(_key, jsonEncode(_entries, toEncodable: (o) => '$o'));
    } on Object {
      // storing is best effort, the running demo is unaffected
    }
  }
}
