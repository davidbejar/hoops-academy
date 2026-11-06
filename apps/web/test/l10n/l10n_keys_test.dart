import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, String> _load(String locale) {
  final raw = jsonDecode(
    File('lib/l10n/app_$locale.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  return {
    for (final e in raw.entries)
      if (!e.key.startsWith('@')) e.key: e.value as String,
  };
}

Set<String> _placeholders(String message) =>
    RegExp(r'\{(\w+)\}').allMatches(message).map((m) => m.group(1)!).toSet();

void main() {
  final es = _load('es');
  final en = _load('en');
  final id = _load('id');

  test('es (template), en and id define exactly the same keys', () {
    expect(en.keys.toSet(), es.keys.toSet(), reason: 'en vs es');
    expect(id.keys.toSet(), es.keys.toSet(), reason: 'id vs es');
  });

  test('every key uses the same placeholders in all three languages', () {
    for (final key in es.keys.where((k) => k != '@@locale')) {
      final expected = _placeholders(es[key]!);
      expect(_placeholders(en[key]!), expected, reason: 'en/$key');
      expect(_placeholders(id[key]!), expected, reason: 'id/$key');
    }
  });

  test('no message is empty and en/id are real translations', () {
    for (final entry in {'en': en, 'id': id}.entries) {
      for (final key in es.keys) {
        expect(entry.value[key], isNotEmpty, reason: '${entry.key}/$key');
      }
    }
    // Spot-check that Indonesian is not a copy of another language.
    expect(id['navTeams'], isNot(en['navTeams']));
    expect(id['signOut'], isNot(es['signOut']));
    final identical = id.keys.where((k) => id[k] == en[k]).length;
    expect(identical, lessThan(id.length ~/ 4));
  });
}
