// Proves the Excel library of the export (decision 69) sits in a deferred part
// and is not precached, over the output of `flutter build web`.
//
//   dart run tool/verify_deferred_excel.dart [build/web]
//
// `tool/build_web.sh` runs it after `tool/sw_manifest.dart`; a failure fails
// the build. Checks: the `xlsx` deferred import exists in the build, the main
// bundle holds no Excel library code, a part only that import loads does, the
// service worker precaches neither that part nor any file with that code.
import 'dart:convert';
import 'dart:io';

import 'sw_manifest.dart';

/// Strings of the Excel package's writer (the names of the parts of an xlsx
/// archive); they survive minification because they are data.
const _excelMarkers = ['xl/workbook.xml'];

bool _hasMarker(String text) => _excelMarkers.any(text.contains);

/// Problems found in [build] (empty = the library is deferred and not precached).
List<String> verifyDeferredExcel(Directory build) {
  final problems = <String>[];
  final mainFile = File('${build.path}/main.dart.js');
  final main = mainFile.readAsStringSync();
  if (_hasMarker(main)) {
    problems.add('main.dart.js contains the Excel library');
  }
  if (!RegExp(r'[{,]xlsx:\[').hasMatch(main)) {
    problems.add('the deferred import "xlsx" is not in main.dart.js');
    return problems;
  }
  final parts = onDemandParts(main);
  final holders = [
    for (final part in parts)
      if (_hasMarker(File('${build.path}/$part').readAsStringSync())) part,
  ];
  if (holders.isEmpty) {
    problems.add(
      'no deferred part only the xlsx import loads holds the library',
    );
  }
  final sw = File('${build.path}/sw.js').readAsStringSync();
  final manifest = RegExp(
    r'const PRECACHE = (\[.*?\]);',
    dotAll: true,
  ).firstMatch(sw);
  if (manifest == null) {
    problems.add('sw.js has no precache list');
    return problems;
  }
  final precached = [
    for (final f in jsonDecode(manifest.group(1)!) as List<dynamic>) '$f',
  ];
  for (final part in parts) {
    if (precached.contains(part)) problems.add('the precache lists $part');
  }
  for (final f in precached.where((f) => f.endsWith('.js'))) {
    final file = File('${build.path}/$f');
    if (file.existsSync() && _hasMarker(file.readAsStringSync())) {
      problems.add('precached $f contains the Excel library');
    }
  }
  return problems;
}

void main(List<String> args) {
  final build = Directory(args.isEmpty ? 'build/web' : args.first);
  final problems = verifyDeferredExcel(build);
  if (problems.isNotEmpty) {
    stderr.writeln('Excel is not deferred:\n  ${problems.join('\n  ')}');
    exit(1);
  }
  final parts = onDemandParts(
    File('${build.path}/main.dart.js').readAsStringSync(),
  );
  final bytes = [for (final p in parts) File('${build.path}/$p').lengthSync()]
      .fold<int>(0, (a, b) => a + b);
  stdout.writeln(
    'Excel library: deferred ($bytes bytes in ${parts.join(', ')}), '
    'not in main.dart.js, not precached',
  );
}
