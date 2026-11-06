import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/core/mock/mock_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WP53 (decision 35): the demo core mock narrows its reads per role like core-service, the demo COACH is on the
/// staff of Mini A, `HOOPS_MOCK_ROLES` reaches every academy and the demo changes survive a reload.
void main() {
  const demo = mockTenantAId;
  const norte = mockTenantBId;
  const mini = 'team-mini-a';

  Dio dioFor(MockApiAdapter adapter, {String tenant = demo}) => Dio(
    BaseOptions(
      baseUrl: 'http://mock',
      headers: {'Authorization': 'Bearer x', 'X-Tenant-Id': tenant},
      validateStatus: (_) => true,
    ),
  )..httpClientAdapter = adapter;

  Dio asRoles(List<String> roles, {String tenant = demo}) =>
      dioFor(MockApiAdapter(roles: roles), tenant: tenant);

  Future<Response<dynamic>> get(Dio d, String path) => d.get<dynamic>(path);

  Set<String> ids(Response<dynamic> r, [String key = 'id']) => {
    for (final e in (r.data is Map ? (r.data as Map)['items'] : r.data) as List)
      (e as Map)[key] as String,
  };

  Future<Set<String>> teams(Dio d) async =>
      ids(await get(d, '/api/core/teams'));
  Future<Set<String>> players(Dio d) async =>
      ids(await get(d, '/api/core/players'));

  group('core reads per role', () {
    test('ADMIN reads everything', () async {
      final d = asRoles(['ADMIN']);
      expect(await teams(d), {mini, 'team-mini-b', 'team-inf-a'});
      expect((await players(d)).length, 10);
      expect((await get(d, '/api/core/members')).statusCode, 200);
      expect(ids(await get(d, '/api/core/guardian-links')), isNotEmpty);
    });

    for (final role in ['COACH', 'ASSISTANT_COACH']) {
      test('$role: staff team only, other teams and players are 404', () async {
        final d = asRoles([role]);
        expect(await teams(d), {mini});
        final seen = await players(d);
        expect(seen, containsAll(['p-ana', 'p-leo']));
        expect(seen, isNot(contains('p-dan')));
        expect(seen, isNot(contains('p-eva')));
        expect((await get(d, '/api/core/teams/team-inf-a')).statusCode, 404);
        expect((await get(d, '/api/core/players/p-dan')).statusCode, 404);
        expect((await get(d, '/api/core/players/p-ana')).statusCode, 200);
        expect(
          (await get(d, '/api/core/teams/team-inf-a/players')).statusCode,
          404,
        );
        expect(ids(await get(d, '/api/core/teams/$mini/players'), 'teamId'), {
          mini,
        });
        expect((await get(d, '/api/core/members')).statusCode, 403);
      });
    }

    test('COACH: cases of his team, approvals he asked for', () async {
      final d = asRoles(['COACH']);
      final admin = asRoles(['ADMIN']);
      expect(ids(await get(admin, '/api/core/approval-requests')).length, 3);
      expect(ids(await get(d, '/api/core/approval-requests')), {'ap-1', 'ap-2'});
      expect((await get(d, '/api/core/approval-requests/ap-3')).statusCode, 404);
      expect(ids(await get(d, '/api/core/eligibility-cases')), {'case-1'});
    });

    test('PARENT: the linked player, her team, her own links', () async {
      final d = asRoles(['PARENT']);
      expect(await teams(d), {mini});
      expect(await players(d), {'p-ana'});
      expect((await get(d, '/api/core/players/p-leo')).statusCode, 404);
      expect((await get(d, '/api/core/players/p-ana')).statusCode, 200);
      expect(
        ids(await get(d, '/api/core/teams/$mini/players'), 'teamId'),
        {mini},
        reason: 'the roster shows her child only',
      );
      expect(
        (((await get(d, '/api/core/teams/$mini/players')).data) as List).length,
        1,
      );
      expect((await get(d, '/api/core/teams/team-inf-a')).statusCode, 404);
      final links = await get(d, '/api/core/guardian-links');
      expect(ids(links), {'link-me'});
      expect((await get(d, '/api/core/approval-requests')).statusCode, 403);
      expect((await get(d, '/api/core/members')).statusCode, 403);
    });

    test('PLAYER: himself and his team', () async {
      final d = asRoles(['PLAYER']);
      expect(await teams(d), {mini});
      expect(await players(d), {'p-leo'});
      expect((await get(d, '/api/core/players/p-ana')).statusCode, 404);
      expect(
        (((await get(d, '/api/core/teams/$mini/players')).data) as List).length,
        1,
      );
      expect((await get(d, '/api/core/guardian-links')).statusCode, 403);
    });

    test('PARENT and PLAYER together see the union', () async {
      final d = asRoles(['PARENT', 'PLAYER']);
      expect(await teams(d), {mini});
      expect(await players(d), {'p-ana', 'p-leo'});
      expect((await get(d, '/api/core/players/p-sara')).statusCode, 404);
      final me = await get(d, '/api/core/me');
      expect(
        (((me.data as Map)['memberships'] as List).first as Map)['authz'],
        containsPair('linkedPlayerIds', ['p-ana']),
      );
    });
  });

  group('the demo COACH is on the staff', () {
    test('a row on Mini A, in the team staff list and in /me', () async {
      final d = asRoles(['COACH']);
      final staff = (await get(d, '/api/core/teams/$mini/staff')).data as List;
      final me = staff.cast<Map>().firstWhere(
        (s) => (s['person'] as Map)['personId'] == 'a1',
      );
      expect(me['role'], 'COACH');
      final authz =
          (((await get(d, '/api/core/me')).data as Map)['memberships']
                  as List)
              .first['authz'];
      expect(authz['staffTeamIds'], [mini]);
    });

    test('an assistant coach is listed as ASSISTANT_COACH', () async {
      final d = asRoles(['ASSISTANT_COACH']);
      final staff = (await get(d, '/api/core/teams/$mini/staff')).data as List;
      expect(
        staff.cast<Map>().map((s) => s['role']),
        contains('ASSISTANT_COACH'),
      );
    });

    test('an admin who is not on the staff has no staff team', () async {
      final d = asRoles(['ADMIN']);
      final staff = (await get(d, '/api/core/teams/$mini/staff')).data as List;
      expect(
        staff.cast<Map>().map((s) => (s['person'] as Map)['personId']),
        isNot(contains('a1')),
      );
    });

    test('taking the coach off the staff takes the team away', () async {
      final d = asRoles(['ADMIN', 'COACH']);
      expect(
        (((await get(d, '/api/core/me')).data as Map)['memberships'] as List)
            .first['authz']['staffTeamIds'],
        [mini],
      );
      expect(
        (await d.delete<dynamic>('/api/core/teams/$mini/staff/a1')).statusCode,
        204,
      );
      expect(
        (((await get(d, '/api/core/me')).data as Map)['memberships'] as List)
            .first['authz']['staffTeamIds'],
        isEmpty,
      );
    });
  });

  group('roles reach every academy', () {
    test('Club Norte keeps PARENT unless told otherwise', () async {
      final d = asRoles(['COACH'], tenant: norte);
      expect(await players(d), {'p-nora'});
    });

    test('norteRoles switches the second academy too', () async {
      final adapter = MockApiAdapter(
        roles: ['COACH'],
        norteRoles: ['COACH'],
      );
      final d = dioFor(adapter, tenant: norte);
      expect((await players(d)).length, 5);
      final staff =
          (await get(d, '/api/core/teams/team-norte-a/staff')).data as List;
      expect(
        staff.cast<Map>().map((s) => (s['person'] as Map)['personId']),
        contains('a1'),
      );
      final me = (await get(d, '/api/core/me')).data as Map;
      expect(
        (me['memberships'] as List).map((m) => (m as Map)['roles']),
        [
          ['COACH'],
          ['COACH'],
        ],
      );
    });

    test('a PLAYER in Club Norte is Nico', () async {
      final d = dioFor(
        MockApiAdapter(roles: ['ADMIN'], norteRoles: ['PLAYER']),
        tenant: norte,
      );
      expect(await players(d), {'p-nico'});
    });
  });

  group('persistence', () {
    Map<String, Object?> newPlayer(String given) => {
      'givenName': given,
      'familyName': 'Persistido',
      'birthDate': '2015-02-01',
      'gender': 'MALE',
      'teamId': mini,
    };

    test('a change survives a new adapter on the same store', () async {
      final store = MemoryMockStore();
      final first = dioFor(MockApiAdapter(roles: ['ADMIN'], store: store));
      final created = await first.post<dynamic>(
        '/api/core/players',
        data: newPlayer('Nuevo'),
      );
      expect(created.statusCode, 201);
      final id = (created.data as Map)['player']['id'] as String;
      await first.post<dynamic>(
        '/api/athlete/injuries',
        data: {
          'playerId': id,
          'occurredOn': '2026-11-01',
          'bodyPart': 'muñeca',
          'severity': 'MINOR',
        },
      );

      final second = dioFor(MockApiAdapter(roles: ['ADMIN'], store: store));
      expect(await players(second), contains(id));
      final injuries = await get(second, '/api/athlete/injuries');
      expect(ids(injuries, 'playerId'), contains(id));
      // ids keep counting from where they were
      final next = await second.post<dynamic>(
        '/api/core/players',
        data: newPlayer('Otro'),
      );
      expect(
        (next.data as Map)['player']['id'],
        isNot(equals(id)),
      );
    });

    test('failed requests and reads are not stored', () async {
      final store = MemoryMockStore();
      final first = dioFor(MockApiAdapter(roles: ['COACH'], store: store));
      await get(first, '/api/core/players');
      await first.post<dynamic>('/api/core/seasons', data: {'name': 'x'});
      final second = dioFor(MockApiAdapter(roles: ['ADMIN'], store: store));
      expect(ids(await get(second, '/api/core/seasons')).length, 2);
    });

    test('the logo bytes and the other academy are kept apart', () async {
      final store = MemoryMockStore();
      final a = MockApiAdapter(roles: ['ADMIN'], store: store);
      final d = dioFor(a);
      final bytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 7, 7, 7]);
      expect(
        (await d.put<dynamic>(
          '/api/core/tenant/logo',
          data: Stream.fromIterable([bytes]),
          options: Options(
            contentType: 'image/png',
            headers: {Headers.contentLengthHeader: bytes.length},
          ),
        )).statusCode,
        200,
      );
      await dioFor(a, tenant: norte).patch<dynamic>(
        '/api/core/tenant',
        data: {'name': 'Norte 2'},
      );
      final b = MockApiAdapter(roles: ['ADMIN'], store: store);
      final logo = await dioFor(b).get<List<int>>(
        '/api/core/tenant/logo',
        options: Options(responseType: ResponseType.bytes),
      );
      expect(logo.data, bytes);
      expect(
        (await get(dioFor(b, tenant: norte), '/api/core/tenant')).data['name'],
        'Norte 2',
      );
      expect(
        (await get(dioFor(b), '/api/core/tenant')).data['name'],
        'Academia Demo',
      );
    });

    test('other roles start from the seed (the key carries the roles)', () async {
      final store = MemoryMockStore();
      await dioFor(
        MockApiAdapter(roles: ['ADMIN'], store: store),
      ).post<dynamic>('/api/core/players', data: newPlayer('Nuevo'));
      final coach = dioFor(MockApiAdapter(roles: ['COACH'], store: store));
      expect((await players(coach)).length, 7);
    });

    test('reset clears the store and the running mock', () async {
      final store = MemoryMockStore();
      final adapter = MockApiAdapter(roles: ['ADMIN'], store: store);
      final d = dioFor(adapter);
      await d.post<dynamic>('/api/core/players', data: newPlayer('Nuevo'));
      expect((await players(d)).length, 11);
      await adapter.reset();
      expect((await players(d)).length, 10);
      final fresh = dioFor(MockApiAdapter(roles: ['ADMIN'], store: store));
      expect((await players(fresh)).length, 10);
    });

    test('SharedPreferences backend round trip and clear', () async {
      SharedPreferences.setMockInitialValues({'unrelated': 'keep'});
      final prefs = await SharedPreferences.getInstance();
      final first = dioFor(
        MockApiAdapter(roles: ['ADMIN'], store: PrefsMockStore(prefs)),
      );
      await first.post<dynamic>('/api/core/players', data: newPlayer('Nuevo'));
      final second = MockApiAdapter(
        roles: ['ADMIN'],
        store: PrefsMockStore(prefs),
      );
      expect((await players(dioFor(second))).length, 11);
      await second.reset();
      expect(prefs.getString('unrelated'), 'keep');
      expect(
        prefs.getKeys().where((k) => k.startsWith('hoops.mock.')),
        isEmpty,
      );
      expect(jsonEncode(prefs.getKeys().toList()), contains('unrelated'));
    });

    test('a corrupt stored log falls back to the seed', () async {
      final store = MemoryMockStore()..write('hoops.mock.v1.$demo.ADMIN', '{');
      final d = dioFor(MockApiAdapter(roles: ['ADMIN'], store: store));
      expect((await players(d)).length, 10);
    });
  });
}
