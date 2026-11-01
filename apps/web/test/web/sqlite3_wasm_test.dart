import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // tool/fetch_web_db_assets.sh pins "<version> <sha256>"; the committed binary must match it (F-10).
  final script = File('tool/fetch_web_db_assets.sh').readAsStringSync();
  final pin = RegExp(r'^SQLITE3_WASM_SHA256="([0-9a-f]{64})"$', multiLine: true).firstMatch(script);
  final pinnedVersion = RegExp(r'^SQLITE3_WASM_VERSION="([^"]+)"$', multiLine: true).firstMatch(script);

  test('fetch script pins a sha256 and the sqlite3 version', () {
    expect(pin, isNotNull, reason: 'SQLITE3_WASM_SHA256="<64 hex>" missing');
    expect(pinnedVersion, isNotNull);
  });

  test('the pinned version is the one resolved in pubspec.lock', () {
    final lock = File('pubspec.lock').readAsStringSync();
    final locked = RegExp(r'^  sqlite3:\n(?:    .*\n)*?    version: "([^"]+)"', multiLine: true).firstMatch(lock)!.group(1);
    expect(pinnedVersion!.group(1), locked, reason: 're-run tool/fetch_web_db_assets.sh and re-pin after bumping sqlite3');
  });

  test('web/sqlite3.wasm matches the pinned checksum', () {
    final digest = sha256.convert(File('web/sqlite3.wasm').readAsBytesSync()).toString();
    expect(digest, pin!.group(1));
  });

  test('the script verifies the download before installing it', () {
    expect(script, contains('sha256'));
    expect(script, contains(r'"$SQLITE3_WASM_SHA256"'));
    expect(utf8.encode(script), isNotEmpty);
  });
}
