import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/roster/data/teams_repository.dart';

/// WP80 / ADR-0042 in the demo backend: a coach has an ended team in the history, never in the current teams.
void main() {
  const t = mockTenantAId;
  const past = 'team-mini-a-2025';

  api.HoopsCoreApi client(List<String> roles) => api.HoopsCoreApi(
    dio: Dio(
      BaseOptions(
        baseUrl: 'http://mock',
        headers: {'Authorization': 'Bearer x'},
      ),
    )..httpClientAdapter = MockApiAdapter(roles: roles),
    interceptors: const [],
  );

  test(
    '`/me` of a coach lists the past team apart from the current ones',
    () async {
      final me = (await client(['COACH']).getMeApi().getMe()).data!;
      final authz = me.memberships.first.authz;
      expect(authz.historicStaffTeamIds.toList(), [past]);
      expect(authz.staffTeamIds.toList(), isNot(contains(past)));
    },
  );

  test('`/me` of an admin or a parent has no history', () async {
    for (final role in ['ADMIN', 'PARENT']) {
      final me = (await client([role]).getMeApi().getMe()).data!;
      expect(
        me.memberships.first.authz.historicStaffTeamIds,
        isEmpty,
        reason: role,
      );
    }
  });

  test('staffedByMe with includeEnded adds the ended teams, flagged', () async {
    final repo = ApiTeamsRepository(client(['COACH']), t);
    final history = await repo.historicStaffTeams();
    expect(history.map((x) => x.id), [past]);
    expect(history.single.seasonEnded, isTrue);
    final current = (await client([
      'COACH',
    ]).getTeamsApi().listTeams(xTenantId: t, staffedByMe: true)).data!.items;
    expect(current.map((x) => x.id), isNot(contains(past)));
    expect(current.every((x) => !x.seasonEnded), isTrue);
  });

  test(
    'every team of the academy includes the ended one for the admin',
    () async {
      final all = await ApiTeamsRepository(client(['ADMIN']), t).list();
      expect(all.where((x) => x.seasonEnded).map((x) => x.id), [past]);
      final lastSeason = await ApiTeamsRepository(
        client(['ADMIN']),
        t,
      ).list(seasonId: 'season-2025');
      expect(lastSeason.map((x) => x.id), [past]);
    },
  );
}
