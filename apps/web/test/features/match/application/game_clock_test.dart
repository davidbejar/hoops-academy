import 'package:fake_async/fake_async.dart';
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
}
