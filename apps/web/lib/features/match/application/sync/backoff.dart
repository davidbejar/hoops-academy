import 'dart:math';

/// Exponential backoff with jitter: nominal delay 1 s, 2 s, 4 s ... capped at
/// 60 s; the actual delay is uniformly drawn from [nominal/2, nominal].
class Backoff {
  Backoff({Random? random, this.base = const Duration(seconds: 1), this.cap = const Duration(seconds: 60)})
    : _random = random ?? Random();

  final Random _random;
  final Duration base;
  final Duration cap;
  int attempt = 0;

  Duration next() {
    final factor = attempt >= 20 ? 1 << 20 : 1 << attempt;
    final nominal = min(cap.inMilliseconds, base.inMilliseconds * factor);
    attempt++;
    return Duration(milliseconds: (nominal * (0.5 + 0.5 * _random.nextDouble())).round());
  }

  void reset() => attempt = 0;
}
