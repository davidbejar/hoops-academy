import 'dart:async';

import 'package:flutter/foundation.dart';

/// The staff device's local game clock (seconds remaining in the period).
/// Not an event: events carry its value; PERIOD_START / PERIOD_END mark the
/// running intervals for the projection.
class GameClock extends ChangeNotifier {
  GameClock({this.tick = const Duration(seconds: 1)});

  final Duration tick;
  int _remaining = 0;
  Timer? _timer;

  int get remaining => _remaining;
  bool get running => _timer != null;

  void set(int seconds) {
    _remaining = seconds < 0 ? 0 : seconds;
    notifyListeners();
  }

  void adjust(int delta) => set(_remaining + delta);

  void start() {
    if (running || _remaining == 0) return;
    _timer = Timer.periodic(tick, (_) {
      _remaining--;
      if (_remaining <= 0) {
        _remaining = 0;
        _stop();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    _stop();
    notifyListeners();
  }

  void toggle() => running ? pause() : start();

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}

String formatClock(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
