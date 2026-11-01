import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/match/domain/match_event.dart';

import 'match_store_test.dart' show memoryStore, tenant, me;

void main() {
  test('wipe removes every table, unsyncedTotal counts all scopes', () async {
    final store = memoryStore();
    addTearDown(store.close);
    for (final (t, p) in [(tenant, me), ('other-tenant', 'other-person')]) {
      await store.record(
        tenantId: t, personId: p, matchId: 'm1', period: 1, clockSecondsRemaining: 600, build: PeriodStart.new,
      );
    }
    await store.saveMatchJson(tenantId: tenant, matchId: 'm1', teamId: 't', json: '{}');
    expect(await store.unsyncedTotal(), 2);
    final device = await store.deviceId();

    await store.wipe();

    expect(await store.unsyncedTotal(), 0);
    expect(await store.matchJson('m1'), isNull);
    expect(await store.ownEvents('m1'), isEmpty);
    expect(await store.lastServerSeq('m1'), 0);
    expect(await store.roster('m1'), isNull);
    expect(await store.deviceId(), isNot(device), reason: 'a new user on this browser gets a new device identity');
  });
}
