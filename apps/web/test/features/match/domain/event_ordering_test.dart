import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/match/domain/projector/event_ordering.dart';

const _maxSafe = 9007199254740991;

RecordedEvent _event({
  String id = '00000000-0000-7000-8000-000000000001',
  int period = 1,
  int clock = 600,
  int second = 0,
  int? serverSeq,
}) => RecordedEvent(
  PeriodStart(
    EventMeta(
      id: id,
      deviceId: 'tablet-1',
      clientSeq: 1,
      period: period,
      clockSecondsRemaining: clock,
      recordedAtClient: DateTime.utc(2026, 11, 7, 10, 0, second),
    ),
  ),
  serverSeq: serverSeq,
);

/// a sorts before b, and b after a, by exactly one step of the order.
void _before(RecordedEvent a, RecordedEvent b) {
  expect(compareGameOrder(a, b), lessThan(0));
  expect(compareGameOrder(b, a), greaterThan(0));
}

/// Game order of the local projection (WP88: pinned for the Dart mutation
/// run; the server vectors cover it end to end).
void main() {
  group('compareGameOrder', () {
    test('period first', () {
      _before(_event(period: 1, clock: 10), _event(period: 2, clock: 600));
    });

    test('then the clock, counting down', () {
      _before(_event(clock: 590, second: 9), _event(clock: 580, second: 1));
    });

    test('then the device time', () {
      _before(_event(second: 1, serverSeq: 9), _event(second: 2, serverSeq: 1));
    });

    test('then the server sequence, unsynced events last', () {
      final highId = '00000000-0000-7000-8000-0000000000ff';
      final lowId = '00000000-0000-7000-8000-000000000001';
      _before(
        _event(id: highId, serverSeq: 1),
        _event(id: lowId, serverSeq: 2),
      );
      _before(
        _event(id: highId, serverSeq: _maxSafe - 1),
        _event(id: lowId, serverSeq: null),
      );
      _before(
        _event(id: lowId, serverSeq: null),
        _event(id: highId, serverSeq: _maxSafe),
      );
    });

    test('then the id; the same event is a tie', () {
      _before(
        _event(id: '00000000-0000-7000-8000-000000000001'),
        _event(id: '00000000-0000-7000-8000-000000000002'),
      );
      expect(compareGameOrder(_event(), _event()), 0);
    });
  });

  group('compareUuids, as java.util.UUID.compareTo', () {
    test('the halves compare as signed longs', () {
      expect(
        compareUuids(
          '80000000-0000-0000-0000-000000000000',
          '7fffffff-ffff-ffff-ffff-ffffffffffff',
        ),
        -1,
      );
      expect(
        compareUuids(
          '7fffffff-ffff-ffff-ffff-ffffffffffff',
          '80000000-0000-0000-0000-000000000000',
        ),
        1,
      );
      expect(
        compareUuids(
          '00000000-0000-0000-8000-000000000000',
          '00000000-0000-0000-0000-000000000000',
        ),
        -1,
        reason: 'the least significant half is signed too',
      );
    });

    test('digits 0-7 are positive, 8-f negative', () {
      expect(
        compareUuids(
          '70000000-0000-0000-0000-000000000000',
          '60000000-0000-0000-0000-000000000000',
        ),
        greaterThan(0),
      );
      expect(
        compareUuids(
          '80000000-0000-0000-0000-000000000000',
          '70000000-0000-0000-0000-000000000000',
        ),
        -1,
      );
      expect(
        compareUuids(
          'f0000000-0000-0000-0000-000000000000',
          '80000000-0000-0000-0000-000000000000',
        ),
        greaterThan(0),
      );
      expect(
        compareUuids(
          '80000000-0000-0000-0000-000000000000',
          'f0000000-0000-0000-0000-000000000000',
        ),
        lessThan(0),
      );
    });

    test('the most significant half decides before the least', () {
      expect(
        compareUuids(
          '00000000-0000-0001-f000-000000000000',
          '00000000-0000-0000-0000-000000000000',
        ),
        greaterThan(0),
      );
    });

    test('case and dashes do not matter; equal ids are a tie', () {
      expect(
        compareUuids(
          '0000000A-0000-0000-0000-000000000000',
          '0000000a000000000000000000000000',
        ),
        0,
      );
    });

    test('anything but 32 hex digits compares as text', () {
      expect(compareUuids('b', 'a'), greaterThan(0));
      expect(
        compareUuids('00000000-0000-0000-0000-000000000000', 'zz'),
        lessThan(0),
      );
      expect(
        compareUuids('zz', '00000000-0000-0000-0000-000000000000'),
        greaterThan(0),
      );
    });
  });

  test('canonicalOrder sorts and keeps the earliest of a repeated id', () {
    final first = _event(
      id: '00000000-0000-7000-8000-000000000009',
      clock: 500,
    );
    final repeat = _event(
      id: '00000000-0000-7000-8000-000000000009',
      clock: 400,
    );
    final other = _event(
      id: '00000000-0000-7000-8000-000000000001',
      clock: 450,
    );
    expect(canonicalOrder([repeat, other, first]), [first, other]);
  });
}
