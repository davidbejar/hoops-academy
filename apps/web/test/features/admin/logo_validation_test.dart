import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/admin/domain/logo_validation.dart';

Uint8List _png([int extra = 0]) => Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  ...List.filled(extra, 0),
]);
Uint8List _jpeg() => Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0]);
Uint8List _webp() => Uint8List.fromList([
  0x52,
  0x49,
  0x46,
  0x46,
  1,
  2,
  3,
  4,
  0x57,
  0x45,
  0x42,
  0x50,
]);

void main() {
  test(
    'accepts png, jpeg and webp with matching extension and magic bytes',
    () {
      expect(
        validateLogo(fileName: 'a.png', bytes: _png()).mimeType,
        'image/png',
      );
      expect(
        validateLogo(fileName: 'A.JPG', bytes: _jpeg()).mimeType,
        'image/jpeg',
      );
      expect(
        validateLogo(fileName: 'a.jpeg', bytes: _jpeg()).mimeType,
        'image/jpeg',
      );
      expect(
        validateLogo(fileName: 'a.webp', bytes: _webp()).mimeType,
        'image/webp',
      );
    },
  );

  test('rejects more than 512 KB, accepts exactly 512 KB', () {
    expect(
      validateLogo(fileName: 'a.png', bytes: _png(512 * 1024)).problem,
      LogoProblem.tooLarge,
    );
    expect(
      validateLogo(fileName: 'a.png', bytes: _png(512 * 1024 - 8)).isValid,
      isTrue,
    );
  });

  test('rejects svg, gif and files without a known extension', () {
    expect(
      validateLogo(fileName: 'a.svg', bytes: _png()).problem,
      LogoProblem.wrongType,
    );
    expect(
      validateLogo(fileName: 'a.gif', bytes: _png()).problem,
      LogoProblem.wrongType,
    );
    expect(
      validateLogo(fileName: 'logo', bytes: _png()).problem,
      LogoProblem.wrongType,
    );
  });

  test('rejects a file whose bytes do not match its extension', () {
    expect(
      validateLogo(fileName: 'a.png', bytes: _jpeg()).problem,
      LogoProblem.wrongType,
    );
    expect(
      validateLogo(
        fileName: 'a.webp',
        bytes: Uint8List.fromList([1, 2, 3]),
      ).problem,
      LogoProblem.wrongType,
    );
  });

  test('rejects empty files', () {
    expect(
      validateLogo(fileName: 'a.png', bytes: Uint8List(0)).problem,
      LogoProblem.empty,
    );
  });
}
