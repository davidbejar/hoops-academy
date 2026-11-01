import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sw = File('web/sw.js').readAsStringSync();

  test('every backend route is network-only (F-19): /platform and /internal included', () {
    final list = RegExp(r'NETWORK_ONLY_PREFIXES = \[(.*?)\]').firstMatch(sw)!.group(1)!;
    for (final p in ['/api/', '/auth/', '/platform/', '/internal/']) {
      expect(list, contains("'$p'"));
    }
  });

  test('the worker still honours SKIP_WAITING from the update prompt', () {
    expect(sw, contains("event.data.type === 'SKIP_WAITING'"));
    expect(sw, contains('self.skipWaiting()'));
  });

  test('bootstrap does not register Flutter service worker', () {
    expect(File('web/flutter_bootstrap.js').readAsStringSync(), isNot(contains('serviceWorkerSettings:')));
  });
}
