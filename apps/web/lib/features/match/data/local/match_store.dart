import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/match_event.dart';
import '../../domain/pending_event.dart';
import 'match_database.dart';

/// Offline store of the live-match feature: device identity, the event queue
/// (outbox), the merged server feed and the match / roster caches.
class MatchStore {
  MatchStore(this._db, {DateTime Function()? now, Uuid? uuid})
    : _now = now ?? DateTime.now,
      _uuid = uuid ?? const Uuid();

  final MatchDatabase _db;
  final DateTime Function() _now;
  final Uuid _uuid;
  String? _deviceId;

  Future<void> close() => _db.close();

  // ------------------------------------------------------------- identity

  /// Stable id of this installation, generated on first use.
  Future<String> deviceId() async {
    final cached = _deviceId;
    if (cached != null) return cached;
    final id = await _db.transaction(() async {
      final row = await (_db.select(_db.device)..where((d) => d.slot.equals(0))).getSingleOrNull();
      if (row != null) return row.deviceId;
      final id = 'web-${_uuid.v4()}';
      await _db.into(_db.device).insert(DeviceCompanion.insert(slot: const Value(0), deviceId: id));
      return id;
    });
    return _deviceId = id;
  }

  // ---------------------------------------------------------------- queue

  /// Records an event: allocates a UUIDv7 id and the next clientSeq of the
  /// match in one transaction, stores it PENDING and returns it.
  Future<PendingEvent> record({
    required String tenantId,
    required String personId,
    required String matchId,
    required int period,
    required int clockSecondsRemaining,
    required MatchEvent Function(EventMeta meta) build,
  }) async {
    final device = await deviceId();
    return _db.transaction(() async {
      final seqRow = await (_db.select(_db.clientSequences)..where((s) => s.matchId.equals(matchId))).getSingleOrNull();
      final seq = (seqRow?.lastClientSeq ?? 0) + 1;
      await _db.into(_db.clientSequences).insertOnConflictUpdate(
        ClientSequencesCompanion.insert(matchId: matchId, lastClientSeq: seq),
      );
      final event = build(EventMeta(
        id: _uuid.v7(),
        deviceId: device,
        clientSeq: seq,
        period: period,
        clockSecondsRemaining: clockSecondsRemaining,
        recordedAtClient: _now().toUtc(),
      ));
      final json = event.toJson();
      await _db.into(_db.pendingEvents).insert(PendingEventsCompanion.insert(
        id: event.id,
        tenantId: tenantId,
        matchId: matchId,
        personId: personId,
        deviceId: device,
        clientSeq: seq,
        type: event.type.wire,
        playerId: Value(event.playerId),
        period: event.meta.period,
        clockSecondsRemaining: event.meta.clockSecondsRemaining,
        payload: Value(json['payload'] == null ? null : jsonEncode(json['payload'])),
        recordedAtClient: event.meta.recordedAtClient.toIso8601String(),
        status: EventStatus.pending.wire,
      ));
      return PendingEvent(
        event: event,
        matchId: matchId,
        tenantId: tenantId,
        personId: personId,
        status: EventStatus.pending,
      );
    });
  }

  static final _unsynced = [EventStatus.pending.wire, EventStatus.sent.wire];

  SimpleSelectStatement<$PendingEventsTable, PendingEventRow> _outboxQuery(String tenantId, String personId) =>
      _db.select(_db.pendingEvents)
        ..where((e) => e.tenantId.equals(tenantId) & e.personId.equals(personId) & e.status.isIn(_unsynced));

  /// Unanswered (PENDING or SENT) events of the caller for one match, in
  /// clientSeq order.
  Future<List<PendingEvent>> outbox({
    required String tenantId,
    required String personId,
    required String matchId,
    int limit = 500,
  }) async {
    final q = _outboxQuery(tenantId, personId)
      ..where((e) => e.matchId.equals(matchId))
      ..orderBy([(e) => OrderingTerm.asc(e.clientSeq)])
      ..limit(limit);
    return (await q.get()).map(_toPending).toList();
  }

  Future<List<String>> matchesWithOutbox({required String tenantId, required String personId}) async {
    final rows = await _outboxQuery(tenantId, personId).get();
    return {for (final r in rows) r.matchId}.toList();
  }

  /// Unsynced count (all matches when [matchId] is null).
  Future<int> unsyncedCount({required String tenantId, required String personId, String? matchId}) async {
    final q = _outboxQuery(tenantId, personId);
    if (matchId != null) q.where((e) => e.matchId.equals(matchId));
    return (await q.get()).length;
  }

  Future<int> rejectedCount({required String tenantId, required String personId}) async {
    final q = _db.select(_db.pendingEvents)
      ..where((e) => e.tenantId.equals(tenantId) & e.personId.equals(personId) & e.status.equals(EventStatus.rejected.wire));
    return (await q.get()).length;
  }

  Future<void> markSent(List<String> ids) =>
      (_db.update(_db.pendingEvents)..where((e) => e.id.isIn(ids) & e.status.equals(EventStatus.pending.wire)))
          .write(PendingEventsCompanion(status: Value(EventStatus.sent.wire)));

  /// The batch never reached the server's store (e.g. 401): answer pending.
  Future<void> revertToPending(List<String> ids) =>
      (_db.update(_db.pendingEvents)..where((e) => e.id.isIn(ids) & e.status.equals(EventStatus.sent.wire)))
          .write(PendingEventsCompanion(status: Value(EventStatus.pending.wire)));

  Future<void> applyResults(List<EventResult> results) => _db.transaction(() async {
    for (final r in results) {
      await (_db.update(_db.pendingEvents)..where((e) => e.id.equals(r.eventId))).write(PendingEventsCompanion(
        status: Value(r.status.wire),
        serverSeq: Value(r.serverSeq),
        rejectReason: Value(r.reason),
      ));
    }
  });

  /// Removes a REJECTED event after the user confirmed (other states are kept).
  Future<void> discard(String eventId) => (_db.delete(_db.pendingEvents)
        ..where((e) => e.id.equals(eventId) & e.status.equals(EventStatus.rejected.wire)))
      .go();

  /// Test seam: forget every answer of a match (simulates lost responses).
  Future<void> debugResetToPending(String matchId) =>
      (_db.update(_db.pendingEvents)..where((e) => e.matchId.equals(matchId)))
          .write(PendingEventsCompanion(status: Value(EventStatus.pending.wire), serverSeq: const Value(null)));

  /// Every event recorded on this device for [matchId], clientSeq order.
  Future<List<PendingEvent>> ownEvents(String matchId) => _ownQuery(matchId).get().then(_toPendingList);

  Stream<List<PendingEvent>> watchOwnEvents(String matchId) => _ownQuery(matchId).watch().map(_toPendingList);

  Stream<int> watchUnsyncedCount({required String tenantId, required String personId}) =>
      _outboxQuery(tenantId, personId).watch().map((r) => r.length);

  SimpleSelectStatement<$PendingEventsTable, PendingEventRow> _ownQuery(String matchId) => _db.select(_db.pendingEvents)
    ..where((e) => e.matchId.equals(matchId))
    ..orderBy([(e) => OrderingTerm.asc(e.clientSeq)]);

  List<PendingEvent> _toPendingList(List<PendingEventRow> rows) => rows.map(_toPending).toList();

  PendingEvent _toPending(PendingEventRow r) => PendingEvent(
    event: MatchEvent.fromJson({
      'id': r.id,
      'deviceId': r.deviceId,
      'clientSeq': r.clientSeq,
      'type': r.type,
      'period': r.period,
      'clockSecondsRemaining': r.clockSecondsRemaining,
      'recordedAtClient': r.recordedAtClient,
      'playerId': ?r.playerId,
      if (r.payload != null) 'payload': jsonDecode(r.payload!),
    }),
    matchId: r.matchId,
    tenantId: r.tenantId,
    personId: r.personId,
    status: EventStatus.fromWire(r.status),
    rejectReason: r.rejectReason,
    serverSeq: r.serverSeq,
  );

  // ----------------------------------------------------------------- feed

  /// Highest serverSeq pulled for [matchId] (0 = nothing yet).
  Future<int> lastServerSeq(String matchId) async {
    final max = _db.syncedEvents.serverSeq.max();
    final q = _db.selectOnly(_db.syncedEvents)
      ..addColumns([max])
      ..where(_db.syncedEvents.matchId.equals(matchId));
    return (await q.getSingle()).read(max) ?? 0;
  }

  /// Upserts feed events by id (re-delivery and voidedBy updates are fine).
  Future<void> mergeFeed(String matchId, List<StoredEvent> events) => _db.batch((b) {
    for (final s in events) {
      b.insert(
        _db.syncedEvents,
        SyncedEventsCompanion.insert(
          id: s.event.id,
          matchId: matchId,
          serverSeq: s.serverSeq,
          json: jsonEncode(s.event.toJson()),
          recordedByPersonId: Value(s.recordedByPersonId),
          recordedByName: Value(s.recordedByName),
          voidedByEventId: Value(s.voidedByEventId),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  });

  Future<List<StoredEvent>> syncedEvents(String matchId) => _syncedQuery(matchId).get().then(_toStoredList);

  Stream<List<StoredEvent>> watchSyncedEvents(String matchId) => _syncedQuery(matchId).watch().map(_toStoredList);

  SimpleSelectStatement<$SyncedEventsTable, SyncedEventRow> _syncedQuery(String matchId) => _db.select(_db.syncedEvents)
    ..where((e) => e.matchId.equals(matchId))
    ..orderBy([(e) => OrderingTerm.asc(e.serverSeq)]);

  List<StoredEvent> _toStoredList(List<SyncedEventRow> rows) => [
    for (final r in rows)
      StoredEvent(
        event: MatchEvent.fromJson((jsonDecode(r.json) as Map).cast<String, Object?>()),
        serverSeq: r.serverSeq,
        recordedByPersonId: r.recordedByPersonId,
        recordedByName: r.recordedByName,
        voidedByEventId: r.voidedByEventId,
      ),
  ];

  // --------------------------------------------------------------- caches

  Future<void> saveRoster(String matchId, List<CachedRosterEntry> entries) => _db.transaction(() async {
    await (_db.delete(_db.rosterCache)..where((r) => r.matchId.equals(matchId))).go();
    await _db.batch((b) {
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        b.insert(_db.rosterCache, RosterCacheCompanion.insert(
          matchId: matchId,
          playerId: e.playerId,
          position: i,
          displayName: e.displayName,
          jerseyNumber: Value(e.jerseyNumber),
          isStarter: e.isStarter,
        ));
      }
    });
  });

  /// Cached roster in its original order; null when never cached.
  Future<List<CachedRosterEntry>?> roster(String matchId) async {
    final rows = await (_db.select(_db.rosterCache)
          ..where((r) => r.matchId.equals(matchId))
          ..orderBy([(r) => OrderingTerm.asc(r.position)]))
        .get();
    if (rows.isEmpty) return null;
    return [
      for (final r in rows)
        CachedRosterEntry(playerId: r.playerId, displayName: r.displayName, jerseyNumber: r.jerseyNumber, isStarter: r.isStarter),
    ];
  }

  Future<void> saveMatchJson({required String tenantId, required String matchId, required String teamId, required String json}) =>
      _db.into(_db.matchesCache).insertOnConflictUpdate(MatchesCacheCompanion.insert(
        id: matchId,
        tenantId: tenantId,
        teamId: teamId,
        json: json,
        cachedAt: _now(),
      ));

  Future<String?> matchJson(String matchId) async =>
      (await (_db.select(_db.matchesCache)..where((m) => m.id.equals(matchId))).getSingleOrNull())?.json;

  Future<List<String>> matchJsonsForTeam({required String tenantId, String? teamId}) async {
    final q = _db.select(_db.matchesCache)..where((m) => m.tenantId.equals(tenantId));
    if (teamId != null) q.where((m) => m.teamId.equals(teamId));
    return [for (final r in await q.get()) r.json];
  }
}
