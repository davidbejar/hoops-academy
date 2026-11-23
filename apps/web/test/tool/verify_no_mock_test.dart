import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/verify_no_mock.dart';

Directory _build({String main = 'main()', String part = 'screen'}) {
  final dir = Directory.systemTemp.createTempSync('verify_no_mock_test');
  File('${dir.path}/main.dart.js').writeAsStringSync(main);
  File('${dir.path}/main.dart.js_1.part.js').writeAsStringSync(part);
  File('${dir.path}/flutter.js').writeAsStringSync('loader');
  return dir;
}

/// ADR-0070: the seeding and failure hooks live in the demo mock, which a
/// release build must not hold.
void main() {
  test('passes a build without mock code', () {
    final dir = _build();
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(verifyNoMock(dir), isEmpty);
  });

  for (final marker in mockMarkers) {
    test('fails when the main bundle holds "$marker"', () {
      final dir = _build(main: 'x="$marker"');
      addTearDown(() => dir.deleteSync(recursive: true));
      expect(verifyNoMock(dir).join(), contains('main.dart.js'));
    });
  }

  test('fails when a deferred part holds mock code', () {
    final dir = _build(part: 'y="urn:hoops:problem:mock"');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(verifyNoMock(dir).join(), contains('main.dart.js_1.part.js'));
  });

  test('fails without a build', () {
    final dir = Directory.systemTemp.createTempSync('verify_no_mock_empty');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(verifyNoMock(dir).join(), contains('no main.dart.js'));
  });

  test('build_web.sh runs it after the build', () {
    final script = File('tool/build_web.sh').readAsStringSync();
    expect(script, contains('dart run tool/verify_no_mock.dart build/web'));
    expect(
      script.indexOf('verify_no_mock'),
      greaterThan(script.indexOf('flutter build web')),
    );
  });

  test('the markers are in the mock code they stand for', () {
    String read(String path) => File(path).readAsStringSync();
    expect(read('lib/core/mock/mock_query.dart'), contains(mockMarkers[0]));
    expect(read('lib/core/mock/mock_core_api.dart'), contains(mockMarkers[1]));
  });
}
