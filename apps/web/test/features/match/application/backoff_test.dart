import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/match/application/sync/backoff.dart';

/// A Random whose nextDouble is fixed: 1.0 gives the nominal delay, 0.0 half.
class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final double value;
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

/// The sync retry delays (WP88: pinned for the Dart mutation run).
void main() {
  test('doubles from 1 s and stops at the 60 s cap by default', () {
    final backoff = Backoff(random: _FixedRandom(1));
    final seconds = [for (var i = 0; i < 8; i++) backoff.next().inSeconds];
    expect(seconds, [1, 2, 4, 8, 16, 32, 60, 60]);
  });

  test('the actual delay is drawn from half to all of the nominal', () {
    expect(
      Backoff(random: _FixedRandom(0)).next(),
      const Duration(milliseconds: 500),
    );
    expect(
      Backoff(random: _FixedRandom(0.5)).next(),
      const Duration(milliseconds: 750),
    );
  });

  test('the factor grows to 2^20 and stays there', () {
    final backoff = Backoff(
      random: _FixedRandom(1),
      base: const Duration(milliseconds: 1),
      cap: const Duration(days: 1),
    );
    final millis = [for (var i = 0; i < 23; i++) backoff.next().inMilliseconds];
    expect(millis, [for (var i = 0; i < 23; i++) 1 << (i < 20 ? i : 20)]);
  });

  test('reset starts again from the base', () {
    final backoff = Backoff(random: _FixedRandom(1))
      ..next()
      ..next();
    expect(backoff.attempt, 2);
    backoff.reset();
    expect(backoff.attempt, 0);
    expect(backoff.next(), const Duration(seconds: 1));
  });
}
