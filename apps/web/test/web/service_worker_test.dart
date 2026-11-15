import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sw = File('web/sw.js').readAsStringSync();

  test('every backend route is network-only (F-19): /platform and /internal included', () {
    final list = RegExp(r'NETWORK_ONLY_PREFIXES = \[(.*?)\]')
        .firstMatch(sw)!
        .group(1)!;
    for (final p in ['/api/', '/auth/', '/platform/', '/internal/']) {
      expect(list, contains("'$p'"));
    }
  });

  test('the worker still honours SKIP_WAITING from the update prompt', () {
    expect(sw, contains("event.data.type === 'SKIP_WAITING'"));
    expect(sw, contains('self.skipWaiting()'));
  });

  // A debug run (`flutter run`) serves web/sw.js as it is, with its
  // placeholders. Cache-first under a cache name that never changes kept a
  // weeks-old app on screen in the browser profile Flutter reuses.
  group('an unstamped worker (debug run)', () {
    test('knows it is unstamped without naming the placeholder twice', () {
      expect(sw, contains("const STAMPED = !BUILD_ID.startsWith('__');"));
      expect(
        '__BUILD_ID__'.allMatches(sw).length,
        1,
        reason: 'tool/sw_manifest.dart replaces the placeholder',
      );
    });

    test('takes over at once, drops every shell cache and reloads the '
        'pages an older worker filled from its cache', () {
      final install = _listener(sw, 'install');
      expect(install, contains('if (!STAMPED)'));
      expect(install, contains('self.skipWaiting()'));

      final activate = _listener(sw, 'activate');
      expect(activate, contains('if (!STAMPED)'));
      expect(activate, contains('k.startsWith(CACHE_PREFIX)'));
      expect(activate, contains('self.clients.claim()'));
      expect(activate, contains('client.navigate(client.url)'));
    });

    test('answers nothing from a cache and stores nothing', () {
      final fetch = _listener(sw, 'fetch');
      expect(fetch, contains('if (!STAMPED) return;'));
      expect(
        fetch.indexOf('if (!STAMPED) return;'),
        lessThan(fetch.indexOf('event.respondWith')),
      );
    });
  });

  test('bootstrap does not register Flutter service worker', () {
    expect(
      File('web/flutter_bootstrap.js').readAsStringSync(),
      isNot(contains('serviceWorkerSettings:')),
    );
  });
}

/// The source of the worker's listener for [event], up to the next listener.
String _listener(String sw, String event) {
  final start = sw.indexOf("self.addEventListener('$event'");
  expect(start, isNot(-1), reason: event);
  final next = sw.indexOf('self.addEventListener(', start + 1);
  return sw.substring(start, next == -1 ? sw.length : next);
}
