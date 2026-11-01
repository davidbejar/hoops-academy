import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

// Paths are relative to apps/web (the cwd of `flutter test`).
const _spaConfigs = [
  '../../infra/compose/nginx/web-headers.conf',
  '../../deploy/containers/web-nginx.conf',
];
const _redirectConfigs = [
  '../../infra/compose/nginx/redirect-headers.conf',
  '../../deploy/containers/web-nginx.conf',
];

String _hash(String body) => 'sha256-${base64.encode(sha256.convert(utf8.encode(body)).bytes)}';

List<String> _inline(String html, String tag) => [
  for (final m in RegExp('<$tag(?![^>]*\\bsrc=)[^>]*>(.*?)</$tag>', dotAll: true).allMatches(html)) m.group(1)!,
];

String _read(String path) => File(path).readAsStringSync();

/// The value of every Content-Security-Policy header in [conf].
List<String> _policies(String conf) => [
  for (final m in RegExp(r'Content-Security-Policy "([^"]*)"').allMatches(conf)) m.group(1)!,
];

void main() {
  final index = _read('web/index.html');
  final redirect = _read('web/redirect.html');

  test('index.html has exactly one inline script (the service worker registration)', () {
    expect(_inline(index, 'script'), hasLength(1));
  });

  for (final conf in _spaConfigs) {
    test('SPA CSP in $conf allows every inline script of index.html by hash', () {
      final policies = _policies(_read(conf)).where((p) => p.contains("'wasm-unsafe-eval'")).toList();
      expect(policies, isNotEmpty);
      for (final policy in policies) {
        for (final script in _inline(index, 'script')) {
          expect(policy, contains("'${_hash(script)}'"));
        }
      }
    });
  }

  for (final conf in _redirectConfigs) {
    test('redirect CSP in $conf allows the inline script and style of redirect.html by hash', () {
      final policies = _policies(_read(conf)).where((p) => !p.contains("'wasm-unsafe-eval'")).toList();
      expect(policies, isNotEmpty);
      for (final policy in policies) {
        for (final script in _inline(redirect, 'script')) {
          expect(policy, contains("'${_hash(script)}'"));
        }
        for (final style in _inline(redirect, 'style')) {
          expect(policy, contains("'${_hash(style)}'"));
        }
      }
    });
  }

  test('no CSP allows a third-party host: CanvasKit and fonts are served by the app itself (F-09)', () {
    for (final conf in {..._spaConfigs, ..._redirectConfigs}) {
      for (final policy in _policies(_read(conf))) {
        expect(policy, isNot(contains('gstatic')), reason: conf);
        expect(policy, isNot(contains('https:')), reason: conf);
        expect(policy, isNot(contains('http:')), reason: conf);
      }
    }
  });

  test('web/ sources do not reference a CDN', () {
    for (final f in ['web/index.html', 'web/redirect.html', 'web/flutter_bootstrap.js', 'web/sw.js', 'web/manifest.json']) {
      expect(_read(f), isNot(contains('gstatic')), reason: f);
    }
  });
}
