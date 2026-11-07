import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/landing/presentation/widgets/device_frame.dart';

/// The twelve screenshots (4 screens x es/en/id) exist, are 720x1560 PNGs and
/// are the ones `landing_screens_capture.dart` wrote (hash in the manifest).
void main() {
  final manifest = jsonDecode(
    File('assets/landing/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final hashes = manifest['sha256'] as Map<String, dynamic>;

  test('twelve screenshots are declared and exist', () {
    final expected = {
      for (final shot in LandingShot.values)
        for (final code in ['es', 'en', 'id']) shot.assetFor(code),
    };
    expect(expected, hasLength(12));
    for (final asset in expected) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });

  test('every PNG matches the manifest hash and the captured size', () {
    expect(hashes, hasLength(12));
    for (final entry in hashes.entries) {
      final bytes = File('assets/landing/${entry.key}').readAsBytesSync();
      expect(sha256.convert(bytes).toString(), entry.value, reason: entry.key);
      final data = ByteData.sublistView(Uint8List.fromList(bytes));
      expect((data.getUint32(16), data.getUint32(20)), (720, 1560));
    }
  });

  test('no stray landing PNG outside the manifest', () {
    final onDisk = Directory('assets/landing')
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.png'))
        .toSet();
    expect(onDisk, hashes.keys.toSet());
  });
}
