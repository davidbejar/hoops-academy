import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/match/domain/projector/projector.dart';

import 'vector_support.dart';

void main() {
  final vectors = loadVectors();

  test('every server vector is present (7 at WP7)', () {
    expect(vectors.length, greaterThanOrEqualTo(7));
  });

  test('fixtures are byte-identical to libs/contracts/vectors '
      '(run tool/sync_vectors.sh after a server change)', () {
    final source = Directory('../../libs/contracts/vectors');
    if (!source.existsSync()) {
      markTestSkipped('contracts folder not available');
      return;
    }
    final names = source
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .map((f) => f.uri.pathSegments.last)
        .toSet();
    expect(vectors.map((v) => v.file).toSet(), names);
    for (final name in names) {
      expect(
        File('$vectorsDir/$name').readAsStringSync(),
        File('${source.path}/$name').readAsStringSync(),
        reason: '$name differs from the server copy',
      );
    }
  });

  group('Dart projector reproduces the server vector', () {
    for (final v in vectors) {
      test(v.name, () {
        final p = project(v.rules, v.roster, v.events);
        final actual = toVectorJson(p);
        final expected = v.expected;
        expect(
          normalise(actual['playerStats']),
          normalise(expected['playerStats']),
          reason: 'playerStats',
        );
        expect(
          normalise(actual['summary']),
          normalise(expected['summary']),
          reason: 'summary',
        );
        expect(
          normalise(actual['teamTotals']),
          normalise(expected['teamTotals']),
          reason: 'teamTotals',
        );
        expect(
          normalise(actual['warnings']),
          normalise(expected['warnings']),
          reason: 'warnings',
        );
        expect(actual['voidedBy'], expected['voidedBy'], reason: 'voidedBy');
      });
    }
  });

  group('property: the projection depends only on the set of events', () {
    for (final v in vectors) {
      test('${v.name}: 25 seeded shuffles with re-deliveries', () {
        final events = v.events;
        final reference = toVectorJson(project(v.rules, v.roster, events));
        for (var seed = 1; seed <= 25; seed++) {
          final random = Random(seed);
          final arrival = [...events]..shuffle(random);
          // Re-deliver a few events (idempotent sync): same id counted once.
          for (var i = 0; i < 1 + random.nextInt(4); i++) {
            arrival.add(events[random.nextInt(events.length)]);
          }
          arrival.shuffle(random);
          expect(
            toVectorJson(project(v.rules, v.roster, arrival)),
            reference,
            reason: 'seed $seed',
          );
        }
      });
    }

    test('local pending events (no serverSeq yet) order after synced ones '
        'and give the same result once they are synced', () {
      final v = vectors.firstWhere((v) => v.name == 'simple-game');
      final synced = v.events;
      final half = synced.length ~/ 2;
      final mixed = [
        ...synced.take(half),
        for (final e in synced.skip(half)) RecordedEvent(e.event),
      ];
      final a = project(v.rules, v.roster, synced);
      final b = project(v.rules, v.roster, mixed..shuffle(Random(7)));
      expect(toVectorJson(b)['playerStats'], toVectorJson(a)['playerStats']);
      expect(
        (toVectorJson(b)['summary']! as Map)['teamScore'],
        (toVectorJson(a)['summary']! as Map)['teamScore'],
      );
    });
  });
}
