import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/verify_deferred_excel.dart';

const _mainJs =
    'var v={deferredPartUris:["main.dart.js_1.part.js","main.dart.js_2.part.js"],'
    'deferredLibraryParts:{matches:[0],xlsx:[0,1]}};';

Directory _build({
  String main = _mainJs,
  String excelPart = 'zip xl/workbook.xml',
  String sw = 'const PRECACHE = ["index.html","main.dart.js"];',
}) {
  final dir = Directory.systemTemp.createTempSync('verify_excel_test');
  File('${dir.path}/main.dart.js').writeAsStringSync(main);
  File('${dir.path}/main.dart.js_1.part.js').writeAsStringSync('screen');
  File('${dir.path}/main.dart.js_2.part.js').writeAsStringSync(excelPart);
  File('${dir.path}/sw.js').writeAsStringSync(sw);
  return dir;
}

void main() {
  test('passes: library in the exclusive part only, part not precached', () {
    final dir = _build();
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(verifyDeferredExcel(dir), isEmpty);
  });

  test('fails when the main bundle holds the library', () {
    final dir = _build(main: '$_mainJs // xl/workbook.xml');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(verifyDeferredExcel(dir).join(), contains('main.dart.js'));
  });

  test('fails when no deferred part holds the library', () {
    final dir = _build(excelPart: 'nothing');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(verifyDeferredExcel(dir).join(), contains('no deferred part'));
  });

  test('fails when the worker precaches the part', () {
    final dir = _build(
      sw: 'const PRECACHE = ["index.html","main.dart.js_2.part.js"];',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(verifyDeferredExcel(dir).join(), contains('precache'));
  });

  test('fails when the xlsx import is missing from the build map', () {
    final dir = _build(
      main: 'var v={deferredPartUris:["main.dart.js_1.part.js"],'
          'deferredLibraryParts:{matches:[0]}};',
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(verifyDeferredExcel(dir).join(), contains('xlsx'));
  });
}
