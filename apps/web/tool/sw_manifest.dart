// Build-time helper for the caching service worker (web/sw.js).
//
//   dart run tool/sw_manifest.dart [build/web]
//
// Lists the files of a finished `flutter build web`, derives a content hash as
// the build id and rewrites the `__BUILD_ID__` / `/*__PRECACHE_MANIFEST__*/[]`
// placeholders of `<build>/sw.js` in place. Pure functions so the logic is
// unit tested (test/tool/sw_manifest_test.dart); `tool/build_web.sh` calls it.
import 'dart:convert';
import 'dart:io';

/// Files the shell cannot start offline without; the build fails if missing.
const requiredShellFiles = [
  'index.html',
  'main.dart.js',
  'flutter.js',
  'flutter_bootstrap.js',
  'manifest.json',
  'redirect.html',
  'sqlite3.wasm',
  'drift_worker.js',
];

const _buildIdPlaceholder = '__BUILD_ID__';
const _manifestPlaceholder = '/*__PRECACHE_MANIFEST__*/[]';

/// The landing page's screenshots exist once per language (`*_es.png`,
/// `*_en.png`, `*_id.png`, twelve in all). English is the fallback of every
/// other language, so it is precached; the others are fetched on demand and
/// cached by the worker at runtime.
bool _otherLanguageLandingShot(String path) =>
    path.startsWith('assets/assets/landing/') &&
    path.endsWith('.png') &&
    !path.endsWith('_en.png');

/// Deferred imports whose parts are fetched only when the person asks for
/// the feature, never at start-up or install (WP97, decision 69): the Excel
/// export's library. Names are the import prefixes in the code
/// (`import '...' deferred as xlsx`).
const onDemandLibraries = {'xlsx'};

/// The parts only the [onDemandLibraries] load, as file names. dart2js lists
/// the parts of every deferred import in `main.dart.js`
/// (`deferredPartUris` and `deferredLibraryParts`, a library's parts being
/// indexes into the former); a part a screen's import needs as well stays
/// precached, because that screen needs it offline.
Set<String> onDemandParts(String mainJs) {
  final uris = RegExp(r'deferredPartUris:\[([^\]]*)\]').firstMatch(mainJs);
  final libraries = RegExp(r'deferredLibraryParts:\{([^}]*)\}')
      .firstMatch(mainJs);
  if (uris == null || libraries == null) return {};
  final files = [
    for (final m in RegExp(r'"([^"]+)"').allMatches(uris.group(1)!))
      m.group(1)!,
  ];
  final used = <String, Set<int>>{
    for (final m in RegExp(
      r'(\w+):\[([\d,]*)\]',
    ).allMatches(libraries.group(1)!))
      m.group(1)!: {
        for (final i in m.group(2)!.split(','))
          if (i.isNotEmpty) int.parse(i),
      },
  };
  final onDemand = <int>{for (final name in onDemandLibraries) ...?used[name]};
  final needed = <int>{
    for (final e in used.entries)
      if (!onDemandLibraries.contains(e.key)) ...e.value,
  };
  return {for (final i in onDemand.difference(needed)) files[i]};
}

bool _excluded(String path) =>
    path == 'sw.js' ||
    _otherLanguageLandingShot(path) ||
    // Flutter 3.47 emits a self-unregistering worker; ours replaces it.
    path == 'flutter_service_worker.js' ||
    path == 'version.json' ||
    path.startsWith('.') ||
    path.contains('/.') ||
    path.endsWith('.map') ||
    path.endsWith('.symbols') ||
    // We build for CanvasKit; the other renderers are never requested (a miss
    // is still fetched and cached at runtime).
    path.startsWith('canvaskit/skwasm') ||
    // Experimental renderer variants of Flutter 3.47 (also never requested).
    path.startsWith('canvaskit/wimp') ||
    path.startsWith('canvaskit/webparagraph/');

/// Relative, forward-slash, sorted paths of everything the worker precaches.
List<String> collectPrecache(Directory build) {
  final root = build.absolute.path;
  final files = <String>[];
  for (final entity in build.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final rel = entity.absolute.path
        .substring(root.length + 1)
        .replaceAll(r'\', '/');
    if (!_excluded(rel)) files.add(rel);
  }
  final mainJs = File('${build.path}/main.dart.js');
  if (mainJs.existsSync()) {
    files.removeWhere(onDemandParts(mainJs.readAsStringSync()).contains);
  }
  files.sort();
  for (final required in requiredShellFiles) {
    if (!files.contains(required)) {
      throw StateError(
        'Build output is missing $required; run `flutter build web` first.',
      );
    }
  }
  return files;
}

/// Stable hex digest (FNV-1a, 64 bit) over the names and bytes of [files].
String buildIdFor(Directory build, List<String> files) {
  var hash = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  void mix(List<int> bytes) {
    for (final b in bytes) {
      hash = (hash ^ b) * prime;
    }
  }

  for (final f in files) {
    mix(utf8.encode(f));
    mix(File('${build.path}/$f').readAsBytesSync());
  }
  return BigInt.from(hash).toUnsigned(64).toRadixString(16).padLeft(16, '0');
}

/// Fills the placeholders of the worker template.
String renderServiceWorker(
  String template, {
  required String buildId,
  required List<String> files,
}) {
  if (!template.contains(_buildIdPlaceholder) ||
      !template.contains(_manifestPlaceholder)) {
    throw StateError(
      'sw.js must contain $_buildIdPlaceholder and $_manifestPlaceholder',
    );
  }
  return template
      .replaceAll(_buildIdPlaceholder, buildId)
      .replaceAll(_manifestPlaceholder, jsonEncode(files));
}

class RewriteSummary {
  const RewriteSummary(this.buildId, this.files);
  final String buildId;
  final List<String> files;
}

/// Rewrites `<build>/sw.js` in place.
RewriteSummary rewriteBuild(Directory build) {
  final sw = File('${build.path}/sw.js');
  if (!sw.existsSync()) {
    throw StateError('${sw.path} not found: is web/sw.js part of the build?');
  }
  final files = collectPrecache(build);
  final id = buildIdFor(build, files);
  sw.writeAsStringSync(
    renderServiceWorker(sw.readAsStringSync(), buildId: id, files: files),
  );
  return RewriteSummary(id, files);
}

void main(List<String> args) {
  final build = Directory(args.isEmpty ? 'build/web' : args.first);
  final summary = rewriteBuild(build);
  stdout.writeln(
    'sw.js: build ${summary.buildId}, ${summary.files.length} files precached',
  );
}
