import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/landing/presentation/widgets/device_frame.dart';

import '../../tool/sw_manifest.dart';

const _template = '''
const BUILD_ID = '__BUILD_ID__';
const PRECACHE = /*__PRECACHE_MANIFEST__*/[];
''';

Directory _fakeBuild() {
  final dir = Directory.systemTemp.createTempSync('sw_manifest_test');
  void put(String path, [String content = 'x']) {
    File('${dir.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  for (final f in [
    'index.html',
    'main.dart.js',
    'main.dart.js_1.part.js',
    'main.dart.js_12.part.js',
    'flutter.js',
    'flutter_bootstrap.js',
    'manifest.json',
    'redirect.html',
    'sqlite3.wasm',
    'drift_worker.js',
    'icons/Icon-192.png',
    'favicon.png',
    'canvaskit/canvaskit.js',
    'canvaskit/canvaskit.wasm',
    'canvaskit/chromium/canvaskit.wasm',
    'assets/AssetManifest.bin.json',
    'assets/fonts/MaterialIcons-Regular.otf',
    // must be left out
    'flutter_service_worker.js',
    'sw.js',
    'main.dart.js.map',
    'canvaskit/canvaskit.js.symbols',
    'canvaskit/skwasm.wasm',
    'canvaskit/wimp.wasm',
    'canvaskit/webparagraph/canvaskit.wasm',
    'version.json',
    '.last_build_id',
  ]) {
    put(f);
  }
  put('sw.js', _template);
  return dir;
}

void main() {
  late Directory build;
  setUp(() => build = _fakeBuild());
  tearDown(() => build.deleteSync(recursive: true));

  group('collectPrecache', () {
    test('lists the app shell with forward-slash relative paths, sorted', () {
      final files = collectPrecache(build);
      expect(
        files,
        containsAll([
          'index.html',
          'main.dart.js',
          'main.dart.js_1.part.js',
          'main.dart.js_12.part.js',
          'flutter.js',
          'flutter_bootstrap.js',
          'manifest.json',
          'redirect.html',
          'sqlite3.wasm',
          'drift_worker.js',
          'icons/Icon-192.png',
          'canvaskit/canvaskit.wasm',
          'canvaskit/chromium/canvaskit.wasm',
          'assets/AssetManifest.bin.json',
        ]),
      );
      expect(files, orderedEquals([...files]..sort()));
      expect(files.any((f) => f.contains(r'\')), isFalse);
    });

    test('leaves out the worker itself, the self-unregistering Flutter worker, maps, symbols and skwasm', () {
      final files = collectPrecache(build);
      for (final unwanted in [
        'sw.js',
        'flutter_service_worker.js',
        'main.dart.js.map',
        'canvaskit/canvaskit.js.symbols',
        'canvaskit/skwasm.wasm',
        'canvaskit/wimp.wasm',
        'canvaskit/webparagraph/canvaskit.wasm',
        'version.json',
        '.last_build_id',
      ]) {
        expect(files, isNot(contains(unwanted)), reason: unwanted);
      }
    });

    test('precaches only the English landing screenshots (WP95)', () {
      // Flutter serves a pubspec asset `assets/x` at `assets/assets/x`. English
      // is the fallback of every unsupported language; the other languages are
      // fetched when needed and cached by the worker at runtime.
      final assets = [
        for (final shot in LandingShot.values)
          for (final code in ['es', 'en', 'id']) shot.assetFor(code),
      ];
      for (final asset in assets) {
        File('${build.path}/assets/$asset')
          ..createSync(recursive: true)
          ..writeAsStringSync('png');
      }
      final files = collectPrecache(build);
      for (final asset in assets) {
        asset.endsWith('_en.png')
            ? expect(files, contains('assets/$asset'))
            : expect(files, isNot(contains('assets/$asset')), reason: asset);
      }
    });

    test('fails when a required shell file is missing from the build', () {
      File('${build.path}/sqlite3.wasm').deleteSync();
      expect(
        () => collectPrecache(build),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('sqlite3.wasm'),
          ),
        ),
      );
    });
  });

  group('buildIdFor', () {
    test('is stable for the same content and changes with it', () {
      final files = collectPrecache(build);
      final a = buildIdFor(build, files);
      expect(buildIdFor(build, files), a);
      File('${build.path}/main.dart.js').writeAsStringSync('changed');
      expect(buildIdFor(build, files), isNot(a));
    });
  });

  group('renderServiceWorker', () {
    test(
      'injects the build id and the file list, leaving no placeholder behind',
      () {
        final out = renderServiceWorker(
          _template,
          buildId: 'abc123',
          files: ['index.html', 'main.dart.js'],
        );
        expect(out, contains("const BUILD_ID = 'abc123';"));
        expect(out, isNot(contains('__BUILD_ID__')));
        expect(out, isNot(contains('__PRECACHE_MANIFEST__')));
        final json = RegExp(r'const PRECACHE = (\[.*\]);')
            .firstMatch(out)!
            .group(1)!;
        expect(jsonDecode(json), ['index.html', 'main.dart.js']);
      },
    );

    test('refuses a template without both placeholders (a silent no-op would ship an unversioned worker)', () {
      expect(
        () => renderServiceWorker(
          "const BUILD_ID = 'x';",
          buildId: 'a',
          files: [],
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => renderServiceWorker(
          'const P = /*__PRECACHE_MANIFEST__*/[];',
          buildId: 'a',
          files: [],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  test('rewriteBuild rewrites build/web/sw.js in place', () {
    final summary = rewriteBuild(build);
    final out = File('${build.path}/sw.js').readAsStringSync();
    expect(out, isNot(contains('__BUILD_ID__')));
    expect(out, contains(summary.buildId));
    expect(summary.files, contains('index.html'));
    expect(summary.files, isNot(contains('sw.js')));
  });
}
