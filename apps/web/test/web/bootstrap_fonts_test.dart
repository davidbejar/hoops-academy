import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Paths are relative to apps/web (the cwd of `flutter test`).
//
// flutter_tools bundles the Roboto fallback (assets/fonts/fallback, FontManifest.json) only in a release build with
// local CanvasKit (`--no-web-resources-cdn`, i.e. tool/build_web.sh). Pointing the engine's fontFallbackBaseUrl at
// this origin in any other build (a debug `flutter run`, compileTarget dartdevc) makes the engine fetch Roboto and
// every Noto fallback from assets/fonts/ -> 404, and no text renders at all.
void main() {
  final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();

  test('fonts are self-hosted only when the build bundles them (local CanvasKit, not a dartdevc debug build)', () {
    expect(bootstrap, contains('useLocalCanvasKit'));
    expect(bootstrap, contains("'dartdevc'"));
    expect(
      bootstrap,
      isNot(matches(RegExp(r'config:\s*\{\s*fontFallbackBaseUrl'))),
      reason: 'an unconditional override breaks every build that does not bundle Roboto',
    );
  });

  test('the release build script still bundles CanvasKit and Roboto (premise of the self-hosted font override)', () {
    expect(
      File('tool/build_web.sh').readAsStringSync(),
      contains('flutter build web --release --no-web-resources-cdn'),
    );
  });
}
