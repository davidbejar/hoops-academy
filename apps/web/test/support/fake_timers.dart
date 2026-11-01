import 'package:hoops_app/features/match/application/sync/sync_worker.dart';

/// Manually driven timers for the sync worker.
class FakeTimers implements SyncTimers {
  final List<FakeTimer> pending = [];
  final List<FakePeriodic> periodic = [];

  @override
  SyncTimer once(Duration duration, Future<void> Function() callback) {
    final t = FakeTimer(this, duration, callback);
    pending.add(t);
    return t;
  }

  @override
  SyncTimer every(Duration duration, Future<void> Function() callback) {
    final t = FakePeriodic(this, duration, callback);
    periodic.add(t);
    return t;
  }

  /// Fires every pending one-shot timer (new ones scheduled meanwhile wait).
  Future<void> fireAll() async {
    final due = [...pending];
    pending.clear();
    for (final t in due) {
      await t.callback();
    }
  }
}

class FakeTimer implements SyncTimer {
  FakeTimer(this._owner, this.duration, this.callback);
  final FakeTimers _owner;
  final Duration duration;
  final Future<void> Function() callback;

  @override
  void cancel() => _owner.pending.remove(this);
}

class FakePeriodic implements SyncTimer {
  FakePeriodic(this._owner, this.duration, this.callback);
  final FakeTimers _owner;
  final Duration duration;
  final Future<void> Function() callback;

  Future<void> tick() => callback();

  @override
  void cancel() => _owner.periodic.remove(this);
}
