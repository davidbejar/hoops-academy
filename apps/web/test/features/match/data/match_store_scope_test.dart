import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/match/domain/pending_event.dart';
import 'package:hoops_app/features/match/data/local/match_store.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';

import 'match_store_test.dart' show memoryStore, tenant, me;

const otherTenant = 'other-tenant';
const otherPerson = 'other-person';

const _entry = CachedRosterEntry(
  playerId: 'p1',
  displayName: 'Ana',
  isStarter: true,
);

/// F-07: cached reads are keyed by tenant (+ person for own events), not by
/// matchId alone, so a second academy / user on the same profile reads nothing.
void main() {
  test('roster cache is scoped by tenant and match', () async {
    final store = memoryStore();
    addTearDown(store.close);
    await store.saveRoster('m1', [_entry], tenantId: tenant);

    expect(await store.roster('m1', tenantId: tenant), hasLength(1));
    expect(await store.roster('m1', tenantId: otherTenant), isNull);
  });

  test('saving the same match roster for another tenant keeps both', () async {
    final store = memoryStore();
    addTearDown(store.close);
    await store.saveRoster('m1', [_entry], tenantId: tenant);
    await store.saveRoster('m1', [
      _entry,
      const CachedRosterEntry(
        playerId: 'p2',
        displayName: 'Bo',
        isStarter: false,
      ),
    ], tenantId: otherTenant);

    expect(await store.roster('m1', tenantId: tenant), hasLength(1));
    expect(await store.roster('m1', tenantId: otherTenant), hasLength(2));
  });

  test('match json is scoped by tenant', () async {
    final store = memoryStore();
    addTearDown(store.close);
    await store.saveMatchJson(
      tenantId: tenant,
      matchId: 'm1',
      teamId: 't',
      json: '{"id":"m1"}',
    );

    expect(await store.matchJson('m1', tenantId: tenant), '{"id":"m1"}');
    expect(await store.matchJson('m1', tenantId: otherTenant), isNull);
  });

  test('own events are scoped by tenant and person', () async {
    final store = memoryStore();
    addTearDown(store.close);
    await store.record(
      tenantId: tenant,
      personId: me,
      matchId: 'm1',
      period: 1,
      clockSecondsRemaining: 600,
      build: PeriodStart.new,
    );

    expect(
      await store.ownEvents('m1', tenantId: tenant, personId: me),
      hasLength(1),
    );
    expect(
      await store.ownEvents('m1', tenantId: otherTenant, personId: me),
      isEmpty,
    );
    expect(
      await store.ownEvents('m1', tenantId: tenant, personId: otherPerson),
      isEmpty,
    );
    expect(
      await store
          .watchOwnEvents('m1', tenantId: tenant, personId: otherPerson)
          .first,
      isEmpty,
    );
  });

  group('bindOwner (a different sub signs in)', () {
    Future<void> seed(MatchStore store) async {
      await store.record(
        tenantId: tenant,
        personId: me,
        matchId: 'm1',
        period: 1,
        clockSecondsRemaining: 600,
        build: PeriodStart.new,
      );
      await store.saveRoster('m1', [_entry], tenantId: tenant);
    }

    test('the same sub keeps everything', () async {
      final store = memoryStore();
      addTearDown(store.close);
      expect(await store.bindOwner('sub-a'), isFalse);
      await seed(store);
      final device = await store.deviceId();

      expect(await store.bindOwner('sub-a'), isFalse);
      expect(await store.unsyncedTotal(), 1);
      expect(await store.roster('m1', tenantId: tenant), isNotNull);
      expect(await store.deviceId(), device);
    });

    test('another sub wipes the DB and becomes the owner', () async {
      final store = memoryStore();
      addTearDown(store.close);
      await store.bindOwner('sub-a');
      await seed(store);
      final device = await store.deviceId();

      expect(await store.bindOwner('sub-b'), isTrue);
      expect(await store.unsyncedTotal(), 0);
      expect(await store.roster('m1', tenantId: tenant), isNull);
      expect(await store.deviceId(), isNot(device));
      expect(await store.bindOwner('sub-b'), isFalse, reason: 'now owned');
      expect(await store.bindOwner('sub-a'), isTrue);
    });

    test('a store without an owner adopts the first sub', () async {
      final store = memoryStore();
      addTearDown(store.close);
      await seed(store);

      expect(await store.bindOwner('sub-a'), isFalse);
      expect(await store.unsyncedTotal(), 1);
    });
  });
}
