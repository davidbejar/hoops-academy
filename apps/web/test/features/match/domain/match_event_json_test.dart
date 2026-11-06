import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';

import 'vector_support.dart';

void main() {
  test('every vector event survives fromJson -> toJson unchanged', () {
    var count = 0;
    for (final v in loadVectors()) {
      for (final raw in v.rawEvents) {
        final json = raw['event']! as Map<String, Object?>;
        final event = MatchEvent.fromJson(json);
        expect(
          event.toJson(),
          _canonical(json),
          reason: '${v.name} ${json['id']}',
        );
        count++;
      }
    }
    expect(count, greaterThan(100));
  });

  test('typed accessors', () {
    final meta = EventMeta(
      id: 'e1',
      deviceId: 'd',
      clientSeq: 1,
      period: 2,
      clockSecondsRemaining: 300,
      recordedAtClient: DateTime.utc(2026, 11, 1, 10),
    );
    final shot = Shot(meta, playerId: 'p1', points: 3, made: true);
    expect(shot.type, MatchEventType.shot);
    expect(shot.playerId, 'p1');
    expect(shot.toJson()['payload'], {'points': 3, 'made': true});
    expect(VoidEvent(meta, target: 'x').toJson()['payload'], {
      'targetEventId': 'x',
    });
  });
}

// recordedAtClient is normalised to UTC ISO-8601 with the server's precision.
Map<String, Object?> _canonical(Map<String, Object?> json) => {
  ...json,
  'recordedAtClient': DateTime.parse(json['recordedAtClient']! as String)
      .toUtc()
      .toIso8601String(),
};
