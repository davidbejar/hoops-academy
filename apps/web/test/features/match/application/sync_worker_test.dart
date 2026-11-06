import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/match/application/sync/backoff.dart';
import 'package:hoops_app/features/match/application/sync/sync_status.dart';
import 'package:hoops_app/features/match/application/sync/sync_worker.dart';
import 'package:hoops_app/features/match/data/local/match_store.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';
import 'package:hoops_app/features/match/domain/pending_event.dart';
import 'package:hoops_app/features/match/domain/projector/merge.dart';
import 'package:hoops_app/features/match/domain/projector/projector.dart';

import '../../../support/fake_game_server.dart';
import '../../../support/fake_timers.dart';
import '../data/match_store_test.dart' show memoryStore, tenant, me;
import '../domain/vector_support.dart';

const matchId = 'm1';

const roster = [
  RosterPlayer(playerId: 'p1', displayName: 'Ana', isStarter: true),
  RosterPlayer(playerId: 'p2', displayName: 'Bo', isStarter: true),
  RosterPlayer(playerId: 'p3', displayName: 'Cai', isStarter: true),
  RosterPlayer(playerId: 'p4', displayName: 'Dee', isStarter: true),
  RosterPlayer(playerId: 'p5', displayName: 'Eli', isStarter: true),
  RosterPlayer(playerId: 'p6', displayName: 'Fay', isStarter: false),
];

/// Records a 50-event game on this device: period starts/ends, every stat
/// type, substitutions and opponent points.
Future<void> recordFiftyEvents(MatchStore store) async {
  var clock = 600;
  var period = 1;
  var n = 0;
  Future<void> add(MatchEvent Function(EventMeta m) build) async {
    n++;
    await store.record(
      tenantId: tenant,
      personId: me,
      matchId: matchId,
      period: period,
      clockSecondsRemaining: clock,
      build: build,
    );
  }

  await add(PeriodStart.new);
  final players = ['p1', 'p2', 'p3', 'p4', 'p5'];
  var i = 0;
  while (n < 49) {
    clock -= 10;
    final p = players[i % players.length];
    switch (i % 8) {
      case 0:
        await add((m) => Shot(m, playerId: p, points: 2, made: true));
      case 1:
        await add((m) => Shot(m, playerId: p, points: 3, made: false));
      case 2:
        await add((m) => Rebound(m, playerId: p, kind: ReboundKind.defensive));
      case 3:
        await add((m) => OpponentScore(m, points: 2));
      case 4:
        await add((m) => Assist(m, playerId: p));
      case 5:
        await add((m) => Foul(m, playerId: p, kind: FoulKind.personal));
      case 6:
        await add((m) => SubOut(m, playerId: 'p5'));
      default:
        await add((m) => SubIn(m, playerId: 'p6'));
    }
    if (i % 8 == 7) players[4] = players[4] == 'p5' ? 'p6' : 'p5';
    i++;
  }
  clock = 0;
  await add(PeriodEnd.new);
}

void main() {
  late MatchStore store;
  late FakeGameServer server;
  late FakeTimers timers;
  late SyncWorker worker;
  late List<SyncStatus> statuses;

  setUp(() {
    store = memoryStore();
    server = FakeGameServer(roster: roster);
    timers = FakeTimers();
    worker = SyncWorker(
      store: store,
      remote: server,
      scope: () => const SyncScope(tenantId: tenant, personId: me),
      backoff: Backoff(random: Random(42)),
      timers: timers,
    );
    statuses = [];
    worker.status.addListener(() => statuses.add(worker.status.value));
  });

  tearDown(() async {
    worker.dispose();
    await store.close();
  });

  Future<List<RecordedEvent>> localEvents() async => mergeEvents(
    await store.syncedEvents(matchId),
    await store.ownEvents(matchId),
  );

  test('50 events queued offline -> reconnect -> 50 ACCEPTED; replay -> 50 DUPLICATE; '
      'local projection equals the server box score', () async {
    server.offline = true;
    await recordFiftyEvents(store);
    await worker.syncNow();
    expect(worker.status.value.pendingCount, 50);
    expect(worker.status.value.lastError, SyncErrorKind.network);
    expect(timers.pending, isNotEmpty, reason: 'a backoff retry is scheduled');

    server.offline = false;
    await worker.onConnectivityChanged(online: true);
    final own = await store.ownEvents(matchId);
    expect(own.length, 50);
    expect(own.every((e) => e.status == EventStatus.accepted), isTrue);
    expect(worker.status.value.pendingCount, 0);
    expect(worker.status.value.lastError, isNull);
    expect(server.batchClientSeqs.single, List.generate(50, (i) => i + 1));

    // Replay: the device forgets every answer (e.g. restored backup) and
    // re-sends all 50 -> all DUPLICATE with the original seqs.
    final seqs = {for (final e in own) e.event.id: e.serverSeq};
    await store.debugResetToPending(matchId);
    await worker.syncNow();
    final replayed = await store.ownEvents(matchId);
    expect(replayed.every((e) => e.status == EventStatus.duplicate), isTrue);
    expect({for (final e in replayed) e.event.id: e.serverSeq}, seqs);
    expect(server.stored(matchId).length, 50);

    final local = project(server.rules, roster, await localEvents());
    final remote = server.boxScore(matchId);
    expect(toVectorJson(local), toVectorJson(remote));
    expect(local.summary.teamScore, greaterThan(0));
  });

  test('a lost response: events go back to PENDING, the re-send is answered DUPLICATE', () async {
    await recordFiftyEvents(store);
    server.dropResponses = true;
    await worker.syncNow();
    expect(
      (await store.ownEvents(matchId))
          .every((e) => e.status == EventStatus.pending),
      isTrue,
    );
    expect(
      server.stored(matchId).length,
      50,
      reason: 'the server did store them',
    );
    server.dropResponses = false;
    await worker.syncNow();
    expect(
      (await store.ownEvents(matchId))
          .every((e) => e.status == EventStatus.duplicate),
      isTrue,
    );
  });

  for (final v in loadVectors()) {
    test('vector ${v.name}: events of other scorers merged from the feed '
        'project to the server golden', () async {
      final s = FakeGameServer(rules: v.rules, roster: v.roster)
        ..preload(matchId, v.events);
      final w = SyncWorker(
        store: store,
        remote: s,
        scope: () => const SyncScope(tenantId: tenant, personId: me),
        timers: timers,
      );
      addTearDown(w.dispose);
      await w.syncNow(matchId: matchId);
      final local = project(v.rules, v.roster, await localEvents());
      final golden = v.expected;
      final actual = toVectorJson(local);
      expect(
        normalise(actual['playerStats']),
        normalise(golden['playerStats']),
      );
      expect(normalise(actual['summary']), normalise(golden['summary']));
      expect(normalise(actual['warnings']), normalise(golden['warnings']));
      expect(actual, toVectorJson(s.boxScore(matchId)));
    });
  }

  test(
    '401 pauses the worker and preserves the queue; re-login resumes',
    () async {
      await recordFiftyEvents(store);
      server.unauthorized = true;
      await worker.syncNow();
      expect(worker.status.value.pausedForAuth, isTrue);
      expect(worker.status.value.lastError, SyncErrorKind.unauthorized);
      expect(timers.pending, isEmpty, reason: 'no retry loop while signed out');
      final queued = await store.ownEvents(matchId);
      expect(queued.length, 50);
      expect(queued.every((e) => e.status == EventStatus.pending), isTrue);

      await worker.onConnectivityChanged(online: true);
      expect(server.batchSizes, isEmpty, reason: 'stays paused until re-login');

      server.unauthorized = false;
      await worker.onAuthenticated();
      expect(worker.status.value.pausedForAuth, isFalse);
      expect(
        (await store.ownEvents(matchId))
            .every((e) => e.status == EventStatus.accepted),
        isTrue,
      );
    },
  );

  test(
    'REJECTED events are kept with their reason, counted and not resent',
    () async {
      server.rejectWhen = (e) => e.playerId == 'p3' ? 'NOT_AUTHORIZED' : null;
      await recordFiftyEvents(store);
      await worker.syncNow();
      final own = await store.ownEvents(matchId);
      final rejected = own
          .where((e) => e.status == EventStatus.rejected)
          .toList();
      expect(rejected, isNotEmpty);
      expect(rejected.every((e) => e.rejectReason == 'NOT_AUTHORIZED'), isTrue);
      expect(worker.status.value.rejectedCount, rejected.length);
      expect(worker.status.value.pendingCount, 0);
      final batches = server.batchSizes.length;
      await worker.syncNow();
      expect(server.batchSizes.length, batches, reason: 'nothing left to send');
      // The projection follows the server: rejected events do not count.
      expect(
        toVectorJson(project(server.rules, roster, await localEvents())),
        toVectorJson(server.boxScore(matchId)),
      );
      await store.discard(rejected.first.event.id);
      expect(
        worker.status.value.rejectedCount,
        rejected.length,
        reason: 'status refreshes on the next sync only',
      );
      await worker.refreshStatus();
      expect(worker.status.value.rejectedCount, rejected.length - 1);
    },
  );

  test('batches of at most 500 in clientSeq order', () async {
    for (var i = 0; i < 1200; i++) {
      await store.record(
        tenantId: tenant,
        personId: me,
        matchId: matchId,
        period: 1,
        clockSecondsRemaining: 300,
        build: (m) => Assist(m, playerId: 'p1'),
      );
    }
    await worker.syncNow();
    expect(server.batchSizes, [500, 500, 200]);
    final all = server.batchClientSeqs.expand((s) => s).toList();
    expect(all, List.generate(1200, (i) => i + 1));
  });

  test('backoff: exponential with jitter from 1 s, capped at 60 s; reset after success', () async {
    server.offline = true;
    await recordFiftyEvents(store);
    final delays = <Duration>[];
    await worker.syncNow();
    for (var i = 0; i < 9; i++) {
      delays.add(timers.pending.single.duration);
      await timers.fireAll(); // the retry fails again and schedules the next
    }
    for (var i = 0; i < delays.length; i++) {
      final nominal = min(60, 1 << i);
      expect(
        delays[i].inMilliseconds,
        inInclusiveRange(nominal * 500, nominal * 1000),
        reason: 'attempt $i',
      );
    }
    expect(delays.last, lessThanOrEqualTo(const Duration(seconds: 60)));
    server.offline = false;
    await timers.fireAll();
    expect(worker.status.value.pendingCount, 0);
    expect(timers.pending, isEmpty);
    expect(worker.backoffAttempt, 0);
  });

  test(
    'watching a match: periodic pull merges other scorers; stop on unwatch',
    () async {
      worker.watch(matchId, every: const Duration(seconds: 15));
      await pumpEventQueue();
      final otherMeta = EventMeta(
        id: '0190b6a0-0001-7000-8000-00000000aaaa',
        deviceId: 'assistant-phone',
        clientSeq: 1,
        period: 1,
        clockSecondsRemaining: 600,
        recordedAtClient: DateTime.utc(2026, 11, 1, 10),
      );
      server.preload(matchId, [RecordedEvent(PeriodStart(otherMeta))]);
      expect(timers.periodic.single.duration, const Duration(seconds: 15));
      await timers.periodic.single.tick();
      expect((await store.syncedEvents(matchId)).map((e) => e.event.id), [
        otherMeta.id,
      ]);
      worker.unwatch();
      expect(timers.periodic, isEmpty);
    },
  );

  test(
    'own accepted events pulled back from the feed are not counted twice',
    () async {
      await recordFiftyEvents(store);
      await worker.syncNow(matchId: matchId);
      expect((await store.syncedEvents(matchId)).length, 50);
      expect((await localEvents()).length, 50);
    },
  );

  test('app resume triggers a sync', () async {
    await recordFiftyEvents(store);
    await worker.onResumed();
    expect(server.batchSizes, [50]);
  });

  test('syncing flag is raised while a pass runs', () async {
    await recordFiftyEvents(store);
    await worker.syncNow();
    expect(statuses.any((s) => s.syncing), isTrue);
    expect(worker.status.value.syncing, isFalse);
  });

  test('concurrent triggers run one pass at a time', () async {
    await recordFiftyEvents(store);
    await Future.wait([worker.syncNow(), worker.syncNow(), worker.syncNow()]);
    expect(server.batchSizes.fold<int>(0, (a, b) => a + b), 50);
  });

  test(
    'events of another signed-in person are never sent with my token',
    () async {
      await store.record(
        tenantId: tenant,
        personId: 'previous-user',
        matchId: matchId,
        period: 1,
        clockSecondsRemaining: 10,
        build: (m) => Assist(m, playerId: 'p1'),
      );
      await worker.syncNow();
      expect(server.batchSizes, isEmpty);
    },
  );
}
