import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/match/application/game_clock.dart';

void main() {
  test('counts down only while running, stops at 0, can be adjusted', () {
    fakeAsync((time) {
      final clock = GameClock()..set(600);
      expect(clock.running, isFalse);
      time.elapse(const Duration(seconds: 5));
      expect(clock.remaining, 600);
      clock.start();
      time.elapse(const Duration(seconds: 5));
      expect(clock.remaining, 595);
      clock.pause();
      time.elapse(const Duration(seconds: 5));
      expect(clock.remaining, 595);
      clock.adjust(-590);
      clock.start();
      time.elapse(const Duration(seconds: 10));
      expect(clock.remaining, 0);
      expect(clock.running, isFalse, reason: 'stops at 0:00');
      clock.adjust(-5);
      expect(clock.remaining, 0);
      clock.dispose();
    });
  });

  test('formats mm:ss', () {
    expect(formatClock(605), '10:05');
    expect(formatClock(59), '0:59');
  });

  test('starts at 0:00, stopped; a negative time is 0:00', () {
    final clock = GameClock();
    expect(clock.remaining, 0);
    expect(clock.running, isFalse);
    clock.set(-1);
    expect(clock.remaining, 0);
    clock.set(-5);
    expect(clock.remaining, 0);
    clock.set(1);
    expect(clock.remaining, 1);
  });

  test('a clock at 0:00 does not start', () {
    fakeAsync((time) {
      final clock = GameClock()..start();
      expect(clock.running, isFalse);
      time.elapse(const Duration(seconds: 3));
      expect(clock.remaining, 0);
    });
  });

  test('starting a running clock adds no second tick', () {
    fakeAsync((time) {
      final clock = GameClock()..set(10);
      clock
        ..start()
        ..start();
      time.elapse(const Duration(seconds: 3));
      expect(clock.remaining, 7);
      clock.dispose();
    });
  });

  test('stops exactly at 0:00, not a tick earlier or later', () {
    fakeAsync((time) {
      final clock = GameClock()..set(3);
      clock.start();
      time.elapse(const Duration(seconds: 2));
      expect(clock.remaining, 1);
      expect(clock.running, isTrue);
      time.elapse(const Duration(seconds: 1));
      expect(clock.remaining, 0);
      expect(clock.running, isFalse);
      expect(time.pendingTimers, isEmpty);
    });
  });

  test('toggle starts and pauses', () {
    fakeAsync((time) {
      final clock = GameClock()..set(5);
      clock.toggle();
      expect(clock.running, isTrue);
      clock.toggle();
      expect(clock.running, isFalse);
    });
  });

  test('every change notifies the listeners', () {
    fakeAsync((time) {
      var notified = 0;
      final clock = GameClock()..addListener(() => notified++);
      clock.set(3);
      expect(notified, 1, reason: 'set');
      clock.start();
      expect(notified, 2, reason: 'start');
      time.elapse(const Duration(seconds: 1));
      expect(notified, 3, reason: 'tick');
      clock.pause();
      expect(notified, 4, reason: 'pause');
      clock.start();
      time.elapse(const Duration(seconds: 2));
      expect(notified, 7, reason: 'start, tick, last tick');
    });
  });

  test('dispose stops the ticks and the notifier', () {
    fakeAsync((time) {
      final clock = GameClock()..set(5);
      clock.start();
      clock.dispose();
      expect(time.pendingTimers, isEmpty);
      time.elapse(const Duration(seconds: 2));
      expect(clock.remaining, 5);
      expect(() => clock.addListener(() {}), throwsA(isA<FlutterError>()));
    });
  });
}
