// Proves a release build holds none of the demo mock API (ADR-0070), and so
// none of the seeding hooks the widget tests use, over the output of
// `flutter build web`.
//
//   dart run tool/verify_no_mock.dart [build/web]
//
// `tool/build_web.sh` runs it after the build; a failure fails the build. The
// guard before the build refuses HOOPS_MOCK_API, and this proves the compiler
// dropped the mock code too, so nothing the tests seed or inject can ship.
import 'dart:io';

/// Strings only the mock API holds; they survive minification because they
/// are data: the problem type of the mock's errors, the demo academy's name.
const mockMarkers = ['urn:hoops:problem:mock', 'Academia Demo'];

/// The JavaScript files of [build] (main bundle and deferred parts) that hold
/// a mock marker, with the marker (empty: no mock code in the build).
List<String> verifyNoMock(Directory build) {
  final main = File('${build.path}/main.dart.js');
  if (!main.existsSync()) return ['no main.dart.js in ${build.path}'];
  final problems = <String>[];
  final scripts =
      build
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.js'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in scripts) {
    final text = file.readAsStringSync();
    for (final marker in mockMarkers) {
      if (text.contains(marker)) {
        problems.add('${file.uri.pathSegments.last} contains "$marker"');
      }
    }
  }
  return problems;
}

void main(List<String> args) {
  final build = Directory(args.isEmpty ? 'build/web' : args.first);
  final problems = verifyNoMock(build);
  if (problems.isNotEmpty) {
    stderr.writeln(
      'The release build holds demo mock code:\n  ${problems.join('\n  ')}',
    );
    exit(1);
  }
  stdout.writeln('Demo mock: not in the build');
}
