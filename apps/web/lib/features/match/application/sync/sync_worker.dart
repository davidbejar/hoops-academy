import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_error.dart';
import '../../data/events_remote.dart';
import '../../data/local/match_store.dart';
import 'backoff.dart';
import 'sync_status.dart';

/// Whose queue is synced: only events recorded by the signed-in person in
/// the active academy are sent with their token.
class SyncScope {
  const SyncScope({required this.tenantId, required this.personId});
  final String tenantId;
  final String personId;
}

abstract class SyncTimer {
  void cancel();
}

/// Timer seam (tests drive time by hand).
abstract class SyncTimers {
  SyncTimer once(Duration duration, Future<void> Function() callback);
  SyncTimer every(Duration duration, Future<void> Function() callback);
}

class RealSyncTimers implements SyncTimers {
  const RealSyncTimers();

  @override
  SyncTimer once(Duration duration, Future<void> Function() callback) =>
      _Wrapped(Timer(duration, () => unawaited(callback())));

  @override
  SyncTimer every(Duration duration, Future<void> Function() callback) =>
      _Wrapped(Timer.periodic(duration, (_) => unawaited(callback())));
}

class _Wrapped implements SyncTimer {
  _Wrapped(this._timer);
  final Timer _timer;
  @override
  void cancel() => _timer.cancel();
}

/// Background sync of the offline event queue.
///
/// One pass: for every match with unanswered events, send them in clientSeq
/// order in batches of at most [batchSize] (`events:batch`), apply the
/// per-event results, then pull the feed (`events?after=`) of the watched /
/// requested matches. Network failures retry with [Backoff]; a 401 (refresh
/// already failed in the Dio layer) pauses until [onAuthenticated]. Nothing
/// is ever dropped: REJECTED events stay in the store with their reason.
class SyncWorker {
  SyncWorker({
    required MatchStore store,
    required EventsRemote remote,
    required SyncScope? Function() scope,
    Backoff? backoff,
    SyncTimers timers = const RealSyncTimers(),
    this.batchSize = 500,
    DateTime Function()? now,
  }) : _store = store, // ignore: prefer_initializing_formals
       _remote = remote, // ignore: prefer_initializing_formals
       _scope = scope, // ignore: prefer_initializing_formals
       _backoff = backoff ?? Backoff(),
       _timers = timers, // ignore: prefer_initializing_formals
       _now = now ?? DateTime.now;

  final MatchStore _store;
  final EventsRemote _remote;
  final SyncScope? Function() _scope;
  final Backoff _backoff;
  final SyncTimers _timers;
  final DateTime Function() _now;
  final int batchSize;

  final ValueNotifier<SyncStatus> status = ValueNotifier(const SyncStatus());
  final Set<String> _pull = {};
  String? _watched;
  SyncTimer? _retry;
  SyncTimer? _periodic;
  Future<void>? _current;
  bool _again = false;
  bool _disposed = false;

  int get backoffAttempt => _backoff.attempt;

  /// Runs a pass now (joins a running one; it then runs once more).
  Future<void> syncNow({String? matchId}) {
    if (matchId != null) _pull.add(matchId);
    final running = _current;
    if (running != null) {
      _again = true;
      return running;
    }
    final next = _loop().whenComplete(() => _current = null);
    _current = next;
    return next;
  }

  Future<void> onConnectivityChanged({required bool online}) async {
    if (online) await syncNow();
  }

  Future<void> onResumed() => syncNow();

  /// The user signed in again: resume with the preserved queue.
  Future<void> onAuthenticated() {
    _set(status.value.copyWith(pausedForAuth: false, lastError: () => null));
    return syncNow();
  }

  /// Keeps [matchId] fresh while its screen is open.
  void watch(String matchId, {Duration every = const Duration(seconds: 15)}) {
    unwatch();
    _watched = matchId;
    _periodic = _timers.every(every, () => syncNow(matchId: matchId));
    unawaited(syncNow(matchId: matchId));
  }

  void unwatch() {
    _periodic?.cancel();
    _periodic = null;
    _watched = null;
  }

  Future<void> refreshStatus() async {
    final scope = _scope();
    if (scope == null || _disposed) return;
    final pending = await _store.unsyncedCount(tenantId: scope.tenantId, personId: scope.personId);
    final rejected = await _store.rejectedCount(tenantId: scope.tenantId, personId: scope.personId);
    _set(status.value.copyWith(pendingCount: pending, rejectedCount: rejected));
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    unwatch();
    status.dispose();
  }

  Future<void> _loop() async {
    do {
      _again = false;
      await _pass();
    } while (_again && !_disposed && !status.value.pausedForAuth);
  }

  Future<void> _pass() async {
    final scope = _scope();
    if (scope == null || _disposed || status.value.pausedForAuth) {
      await refreshStatus();
      return;
    }
    _retry?.cancel();
    _retry = null;
    _set(status.value.copyWith(syncing: true));
    try {
      await _push(scope);
      final pulls = {?_watched, ..._pull};
      for (final matchId in pulls) {
        await _pullFeed(matchId);
      }
      _pull.clear();
      _backoff.reset();
      _set(status.value.copyWith(lastError: () => null, nextRetryAt: () => null));
    } on Object catch (e) {
      _fail(AppError.of(e));
    } finally {
      if (!_disposed) {
        _set(status.value.copyWith(syncing: false));
        await refreshStatus();
      }
    }
  }

  Future<void> _push(SyncScope scope) async {
    final matches = await _store.matchesWithOutbox(tenantId: scope.tenantId, personId: scope.personId);
    for (final matchId in matches) {
      while (true) {
        final batch = await _store.outbox(
          tenantId: scope.tenantId, personId: scope.personId, matchId: matchId, limit: batchSize,
        );
        if (batch.isEmpty) break;
        final ids = [for (final e in batch) e.event.id];
        await _store.markSent(ids);
        final BatchOutcome outcome;
        try {
          outcome = await _remote.submit(matchId, [for (final e in batch) e.event]);
        } on Object {
          // SENT means "in flight". Whether or not the server stored them,
          // they go back to PENDING; a re-send of a stored one is DUPLICATE.
          await _store.revertToPending(ids);
          rethrow;
        }
        await _store.applyResults(outcome.results);
        _pull.add(matchId);
        if (batch.length < batchSize) break;
      }
    }
  }

  Future<void> _pullFeed(String matchId) async {
    var hasMore = true;
    while (hasMore) {
      final after = await _store.lastServerSeq(matchId);
      final page = await _remote.feed(matchId, after: after);
      await _store.mergeFeed(matchId, page.events);
      hasMore = page.hasMore && page.events.isNotEmpty;
    }
  }

  void _fail(AppError error) {
    if (error.kind == AppErrorKind.unauthorized) {
      _set(status.value.copyWith(pausedForAuth: true, lastError: () => SyncErrorKind.unauthorized, nextRetryAt: () => null));
      return;
    }
    final kind = switch (error.kind) {
      AppErrorKind.network || AppErrorKind.timeout => SyncErrorKind.network,
      _ => SyncErrorKind.server,
    };
    final delay = _backoff.next();
    _retry = _timers.once(delay, syncNow);
    _set(status.value.copyWith(lastError: () => kind, nextRetryAt: () => _now().add(delay)));
  }

  void _set(SyncStatus s) {
    if (!_disposed) status.value = s;
  }
}
