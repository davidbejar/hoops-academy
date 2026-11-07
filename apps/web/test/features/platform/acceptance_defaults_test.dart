import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/platform/domain/acceptance_defaults.dart';

void main() {
  group('suggestSlug', () {
    test('lower case, accents folded, everything else one hyphen', () {
      expect(
        suggestSlug('Escuela de Baloncesto Ñandú 2026'),
        'escuela-de-baloncesto-nandu-2026',
      );
      expect(suggestSlug('  C.B. Valle -- Norte!  '), 'c-b-valle-norte');
      expect(suggestSlug('Çà Ïö'), 'ca-io');
    });

    test('at most 50 characters without a trailing hyphen', () {
      final slug = suggestSlug('${'a' * 49} b and more');
      expect(slug, 'a' * 49);
      expect(suggestSlug('x' * 80), hasLength(50));
    });

    test('empty when fewer than 3 letters or digits are left', () {
      expect(suggestSlug('!!'), '');
      expect(suggestSlug('ab'), '');
      expect(suggestSlug('a b'), 'a-b');
      expect(suggestSlug('東京'), '');
    });

    test('every suggestion matches the server rule', () {
      final rule = RegExp(r'^[a-z0-9](?:[a-z0-9-]{1,48}[a-z0-9])$');
      for (final name in ['Hoops Bali', 'Club Norte', 'Ä-ö-ü sport', '9 9']) {
        expect(suggestSlug(name), matches(rule), reason: name);
      }
    });
  });

  group('splitName', () {
    test('first word as given name, the rest as family name', () {
      expect(splitName('Lucía Pérez García'), ('Lucía', 'Pérez García'));
      expect(splitName('  Ana   Ruiz '), ('Ana', 'Ruiz'));
    });

    test('a single word or no name', () {
      expect(splitName('Sam'), ('Sam', ''));
      expect(splitName(null), ('', ''));
      expect(splitName('   '), ('', ''));
    });
  });
}
