import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../../../core/session/capabilities.dart';
import '../data/local/match_store.dart';
import '../domain/match_event.dart';
import '../domain/pending_event.dart';
import '../domain/projector/event_ordering.dart';
import '../domain/projector/merge.dart';
import '../domain/projector/projection.dart';
import '../domain/projector/projector.dart';
import '../domain/scoring_rights.dart';
import '../domain/stat_action.dart';
import 'match_providers.dart';

/// The caller may not record this (UI should have disabled it).
class NotAllowed implements Exception {
  const NotAllowed(this.what);
  final String what;
  @override
  String toString() => 'NotAllowed($what)';
}

/// One row of the event log (latest first).
class LogEntry {
  const LogEntry({
    required this.event,
    required this.mine,
    required this.voided,
    required this.canVoid,
    this.serverSeq,
    this.status,
    this.rejectReason,
    this.recordedBy,
  });

  final MatchEvent event;
  final int? serverSeq;

  /// Sync state when recorded on this device; null = pulled from the feed.
  final EventStatus? status;
  final String? rejectReason;
  final bool mine;
  final bool voided;
  final bool canVoid;
  final String? recordedBy;
}

/// Everything the live screen renders, recomputed on every store change.
class LiveMatch {
  const LiveMatch({
    required this.match,
    required this.roster,
    required this.rules,
    required this.projection,
    required this.own,
    required this.synced,
    required this.log,
    required this.rights,
    required this.fromCache,
  });

  final gen.Match match;
  final List<RosterPlayer> roster;
  final MatchRules rules;
  final Projection projection;
  final List<PendingEvent> own;
  final List<StoredEvent> synced;
  final List<LogEntry> log;
  final ScoringRights rights;

  /// Match / roster shown from the offline cache (network unavailable).
  final bool fromCache;

  int get unsynced => own.where((e) => e.status.unsynced).length;
  int get rejected => own.where((e) => e.status == EventStatus.rejected).length;
  bool get finished => match.status == gen.MatchStatus.FINISHED;

  RosterPlayer? player(String? id) {
    for (final r in roster) {
      if (r.playerId == id) return r;
    }
    return null;
  }

  /// Period new events are recorded in (1 before the first start).
  int get currentPeriod => projection.live.period == 0 ? 1 : projection.live.period;

  /// The period the "start" button opens.
  int get nextPeriod => projection.live.period + 1;
}

class LiveMatchController extends AsyncNotifier<LiveMatch> {
  LiveMatchController(this.matchId);
  final String matchId;

  late gen.Match _match;
  late List<RosterPlayer> _roster;
  late ScoringRights _rights;
  late String _personId;
  bool _fromCache = false;
  List<StoredEvent> _synced = const [];
  List<PendingEvent> _own = const [];

  MatchStore get _store => ref.read(matchStoreProvider);

  @override
  Future<LiveMatch> build() async {
    final store = ref.watch(matchStoreProvider);
    final repo = ref.watch(matchesRepositoryProvider);
    final worker = ref.watch(syncWorkerProvider);
    final caps = ref.watch(capabilitiesProvider);
    _personId = ref.watch(syncScopeProvider)?.personId ?? caps.personId ?? '';
    _fromCache = false;

    try {
      _match = await repo.get(matchId);
      await store.saveMatchJson(
        tenantId: _tenantOr(_match.id), matchId: _match.id, teamId: _match.teamId, json: encodeMatch(_match),
      );
    } on Object catch (e) {
      final cached = isOfflineError(e) ? await store.matchJson(matchId) : null;
      if (cached == null) rethrow;
      _match = decodeMatch(cached);
      _fromCache = true;
    }
    try {
      _roster = await repo.roster(matchId);
      await store.saveRoster(matchId, [
        for (final r in _roster)
          CachedRosterEntry(playerId: r.playerId, displayName: r.displayName, jerseyNumber: r.jerseyNumber, isStarter: r.isStarter),
      ]);
    } on Object catch (e) {
      final cached = isOfflineError(e) ? await store.roster(matchId) : null;
      if (cached == null) rethrow;
      _roster = [
        for (final c in cached)
          RosterPlayer(playerId: c.playerId, displayName: c.displayName, jerseyNumber: c.jerseyNumber, isStarter: c.isStarter),
      ];
      _fromCache = true;
    }
    _rights = ScoringRights.of(caps, teamId: _match.teamId);
    _synced = await store.syncedEvents(matchId);
    _own = await store.ownEvents(matchId);

    final subs = [
      store.watchSyncedEvents(matchId).listen((e) {
        _synced = e;
        _emit();
      }),
      store.watchOwnEvents(matchId).listen((e) {
        _own = e;
        _emit();
      }),
    ];
    worker.watch(matchId);
    ref.onDispose(() {
      for (final s in subs) {
        unawaited(s.cancel());
      }
      worker.unwatch();
    });
    return _compose();
  }

  /// Cache rows are keyed by the active academy (same source as the sync scope).
  String _tenantOr(String fallback) => ref.read(syncScopeProvider)?.tenantId ?? fallback;

  void _emit() {
    if (state.hasValue) state = AsyncData(_compose());
  }

  LiveMatch _compose() {
    final rules = MatchRules(periodCount: _match.periodCount, periodMinutes: _match.periodMinutes);
    final projection = project(rules, _roster, mergeEvents(_synced, _own));
    final ownById = {for (final p in _own) p.event.id: p};
    final syncedById = {for (final s in _synced) s.event.id: s};
    final all = <RecordedEvent>[
      for (final s in _synced) RecordedEvent(s.event, serverSeq: s.serverSeq),
      for (final p in _own)
        if (!syncedById.containsKey(p.event.id)) RecordedEvent(p.event, serverSeq: p.serverSeq),
    ]..sort(compareGameOrder);
    final log = <LogEntry>[
      for (final r in all.reversed)
        () {
          final own = ownById[r.id];
          final stored = syncedById[r.id];
          final mine = own != null || stored?.recordedByPersonId == _personId;
          final voided = projection.voidedBy.containsKey(r.id);
          final rejected = own?.status == EventStatus.rejected;
          return LogEntry(
            event: r.event,
            serverSeq: r.serverSeq,
            status: own?.status,
            rejectReason: own?.rejectReason,
            mine: mine,
            voided: voided,
            canVoid: !voided && !rejected && r.event is! VoidEvent && _rights.canVoid(recordedByMe: mine),
            recordedBy: stored?.recordedByName,
          );
        }(),
    ];
    return LiveMatch(
      match: _match,
      roster: _roster,
      rules: rules,
      projection: projection,
      own: _own,
      synced: _synced,
      log: log,
      rights: _rights,
      fromCache: _fromCache,
    );
  }

  // --------------------------------------------------------------- commands

  Future<void> _record(MatchEvent Function(EventMeta meta) build, {int? period, required int clock}) async {
    final s = state.requireValue;
    final scope = ref.read(syncScopeProvider);
    if (scope == null) throw const NotAllowed('signed out');
    await _store.record(
      tenantId: scope.tenantId,
      personId: scope.personId,
      matchId: matchId,
      period: period ?? s.currentPeriod,
      clockSecondsRemaining: clock.clamp(0, 3600),
      build: build,
    );
    unawaited(ref.read(syncWorkerProvider).syncNow(matchId: matchId));
  }

  void _requireStaff(String what) {
    if (!state.requireValue.rights.canRunMatch) throw NotAllowed(what);
  }

  /// [clock] defaults to the last known game clock (parents have no clock).
  Future<void> recordStat(String playerId, StatAction action, {int? clock}) async {
    final s = state.requireValue;
    if (!s.rights.canRecordFor(playerId)) throw NotAllowed('stat for $playerId');
    await _record((m) => action.build(m, playerId), clock: clock ?? s.projection.live.clock);
  }

  Future<void> startPeriod({int? clock}) async {
    _requireStaff('period');
    final s = state.requireValue;
    final period = s.nextPeriod;
    await _record(PeriodStart.new, period: period, clock: clock ?? s.rules.periodSeconds(period));
  }

  Future<void> endPeriod({int clock = 0}) async {
    _requireStaff('period');
    await _record(PeriodEnd.new, clock: clock);
  }

  Future<void> substitute({required String out, required String into, required int clock}) async {
    _requireStaff('substitution');
    await _record((m) => SubOut(m, playerId: out), clock: clock);
    await _record((m) => SubIn(m, playerId: into), clock: clock);
  }

  Future<void> opponentScore(int points, {required int clock}) async {
    _requireStaff('opponent');
    await _record((m) => OpponentScore(m, points: points), clock: clock);
  }

  Future<void> timeout(TimeoutSide side, {required int clock}) async {
    _requireStaff('timeout');
    await _record((m) => Timeout(m, side: side), clock: clock);
  }

  /// VOIDs the latest own event still in effect; false when there is none.
  Future<bool> undo() async {
    final s = state.requireValue;
    final candidates = s.own.reversed.where(
      (p) => p.event is! VoidEvent && p.status != EventStatus.rejected && !s.projection.voidedBy.containsKey(p.event.id),
    );
    if (candidates.isEmpty) return false;
    await voidEvent(candidates.first.event.id);
    return true;
  }

  Future<void> voidEvent(String eventId) async {
    final s = state.requireValue;
    final entry = s.log.where((e) => e.event.id == eventId).firstOrNull;
    if (entry == null || !entry.canVoid) throw NotAllowed('void $eventId');
    final target = entry.event.meta;
    await _record(
      (m) => VoidEvent(m, target: eventId),
      period: target.period,
      clock: target.clockSecondsRemaining,
    );
    // Optimistic: the new VOID is in the store; the stream listener re-emits.
  }

  /// Drops a REJECTED event from the queue (user confirmed).
  Future<void> discard(String eventId) async {
    await _store.discard(eventId);
    await ref.read(syncWorkerProvider).refreshStatus();
  }

  Future<void> startMatch() => _transition(ref.read(matchesRepositoryProvider).start);
  Future<void> finishMatch() => _transition(ref.read(matchesRepositoryProvider).finish);

  Future<void> _transition(Future<gen.Match> Function(String id) call) async {
    _requireStaff('match state');
    _match = await call(matchId);
    await _store.saveMatchJson(tenantId: _tenantOr(matchId), matchId: matchId, teamId: _match.teamId, json: encodeMatch(_match));
    _emit();
  }
}

final liveMatchProvider = AsyncNotifierProvider.family<LiveMatchController, LiveMatch, String>(LiveMatchController.new);
