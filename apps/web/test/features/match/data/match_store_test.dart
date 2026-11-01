import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/match/data/local/match_database.dart';
import 'package:hoops_app/features/match/data/local/match_store.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/match/domain/pending_event.dart';

const tenant = 't1';
const me = 'person-me';

MatchStore memoryStore() => MatchStore(
  MatchDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)),
);

Future<PendingEvent> shot(MatchStore s, String matchId, {String player = 'p1'}) => s.record(
  tenantId: tenant,
  personId: me,
  matchId: matchId,
  period: 1,
  clockSecondsRemaining: 500,
  build: (meta) => Shot(meta, playerId: player, points: 2, made: true),
);

void main() {
  test('deviceId is generated once and clientSeq is monotonic per match '
      'across app restarts', () async {
    final dir = await Directory.systemTemp.createTemp('hoops_store');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/matches.sqlite');

    var store = MatchStore(MatchDatabase(DatabaseConnection(NativeDatabase(file))));
    final device = await store.deviceId();
    final a1 = await shot(store, 'm1');
    final a2 = await shot(store, 'm1');
    final b1 = await shot(store, 'm2');
    await store.close();

    store = MatchStore(MatchDatabase(DatabaseConnection(NativeDatabase(file))));
    expect(await store.deviceId(), device);
    final a3 = await shot(store, 'm1');
    final b2 = await shot(store, 'm2');
    await store.close();

    expect([a1, a2, a3].map((e) => e.event.meta.clientSeq), [1, 2, 3]);
    expect([b1, b2].map((e) => e.event.meta.clientSeq), [1, 2]);
    expect({a1, a2, a3, b1, b2}.map((e) => e.event.meta.deviceId).toSet(), {device});
  });

  test('ids are UUIDv7 and events start PENDING', () async {
    final store = memoryStore();
    addTearDown(store.close);
    final e = await shot(store, 'm1');
    expect(e.status, EventStatus.pending);
    expect(e.event.id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(e.event.meta.recordedAtClient.isUtc, isTrue);
  });

  test('a discarded REJECTED event never frees its clientSeq', () async {
    final store = memoryStore();
    addTearDown(store.close);
    final e1 = await shot(store, 'm1');
    await store.applyResults([EventResult.rejected(e1.event.id, 'NOT_AUTHORIZED')]);
    await store.discard(e1.event.id);
    final e2 = await shot(store, 'm1');
    expect(e2.event.meta.clientSeq, 2);
  });

  test('outbox: PENDING and SENT of the caller, clientSeq order, limit', () async {
    final store = memoryStore();
    addTearDown(store.close);
    for (var i = 0; i < 7; i++) {
      await shot(store, 'm1');
    }
    await store.record(
      tenantId: tenant, personId: 'someone-else', matchId: 'm1', period: 1, clockSecondsRemaining: 10,
      build: (meta) => Assist(meta, playerId: 'p2'),
    );
    var box = await store.outbox(tenantId: tenant, personId: me, matchId: 'm1', limit: 5);
    expect(box.map((e) => e.event.meta.clientSeq), [1, 2, 3, 4, 5]);
    await store.markSent(box.map((e) => e.event.id).toList());
    box = await store.outbox(tenantId: tenant, personId: me, matchId: 'm1');
    expect(box.length, 7, reason: 'SENT stays in the outbox until answered');
    await store.applyResults([
      EventResult.accepted(box[0].event.id, 11),
      EventResult.duplicate(box[1].event.id, 9),
      EventResult.rejected(box[2].event.id, 'SCHEMA_INVALID'),
    ]);
    box = await store.outbox(tenantId: tenant, personId: me, matchId: 'm1');
    expect(box.map((e) => e.event.meta.clientSeq), [4, 5, 6, 7]);
    final own = await store.ownEvents('m1');
    expect(own.firstWhere((e) => e.event.meta.clientSeq == 1).serverSeq, 11);
    expect(own.firstWhere((e) => e.event.meta.clientSeq == 2).status, EventStatus.duplicate);
    final rejected = own.firstWhere((e) => e.event.meta.clientSeq == 3);
    expect(rejected.status, EventStatus.rejected);
    expect(rejected.rejectReason, 'SCHEMA_INVALID');
    expect(await store.matchesWithOutbox(tenantId: tenant, personId: me), ['m1']);
    expect(await store.unsyncedCount(tenantId: tenant, personId: me, matchId: 'm1'), 4);
  });

  test('feed merge keeps one row per id and advances the cursor', () async {
    final store = memoryStore();
    addTearDown(store.close);
    expect(await store.lastServerSeq('m1'), 0);
    final meta = EventMeta(
      id: 'x1', deviceId: 'other', clientSeq: 1, period: 1, clockSecondsRemaining: 600,
      recordedAtClient: DateTime.utc(2026, 11, 1),
    );
    final stored = StoredEvent(event: PeriodStart(meta), serverSeq: 4, recordedByPersonId: 'coach');
    await store.mergeFeed('m1', [stored, stored]);
    await store.mergeFeed('m1', [stored.copyWith(voidedByEventId: 'v9')]);
    final synced = await store.syncedEvents('m1');
    expect(synced.length, 1);
    expect(synced.single.voidedByEventId, 'v9');
    expect(await store.lastServerSeq('m1'), 4);
  });

  test('roster and match caches round-trip (offline after first load)', () async {
    final store = memoryStore();
    addTearDown(store.close);
    await store.saveRoster('m1', const [
      CachedRosterEntry(playerId: 'p1', displayName: 'Ana', jerseyNumber: '4', isStarter: true),
      CachedRosterEntry(playerId: 'p2', displayName: 'Bo', isStarter: false),
    ]);
    expect((await store.roster('m1'))!.map((r) => r.displayName), ['Ana', 'Bo']);
    expect(await store.roster('m2'), isNull);
    await store.saveMatchJson(tenantId: tenant, matchId: 'm1', teamId: 'team', json: '{"id":"m1"}');
    expect(await store.matchJson('m1'), '{"id":"m1"}');
    expect(await store.matchJsonsForTeam(tenantId: tenant, teamId: 'team'), ['{"id":"m1"}']);
  });
}
