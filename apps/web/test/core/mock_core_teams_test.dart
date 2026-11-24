import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/roster/data/players_repository.dart';
import 'package:hoops_app/features/roster/data/teams_repository.dart';

import '../support/core_fixtures.dart';
import '../support/core_seed.dart';
import '../support/fixtures.dart';
import '../support/mock_backend.dart';

/// The demo mock's teams follow core (ADR-0070: the teams fake did, the mock
/// did not).
void main() {
  test('any member reads any team, its roster, staff and taken numbers '
      '(getTeam, listTeamPlayers, listTeamStaff, listTeamJerseyNumbers: any '
      'member)', () async {
    final coach = MockBackend(roles: {TenantRole.coach})
      ..seedTeams([team('t1', 'Mini A'), team('t2', 'Mini B')])
      ..seedPlayers([player('p1', 'Ana Ruiz')])
      ..seedRoster('t1', [teamPlayer('t1', 'p1', 'Ana Ruiz')]);
    coach.seedMembership(
      membershipWithRoles({TenantRole.coach}, staffTeamIds: {'t2'}),
    );
    final teams = ApiTeamsRepository(coach.coreApi(), MockBackend.testTenantId);
    expect((await teams.get('t1')).name, 'Mini A');
    expect((await teams.roster('t1')).single.player.id, 'p1');
    expect(await teams.staff('t1'), isEmpty);
    expect(await teams.jerseyNumbers('t1'), isEmpty);
  });

  test('a jersey number taken in the team is 409 (updateTeamPlayer)', () async {
    final admin = MockBackend()
      ..seedTeams([team('t1', 'Mini A')])
      ..seedPlayers([player('p1', 'Ana Ruiz'), player('p2', 'Leo Gil')])
      ..seedRoster('t1', [
        teamPlayer('t1', 'p1', 'Ana Ruiz', jersey: '7'),
        teamPlayer('t1', 'p2', 'Leo Gil', jersey: '10'),
      ]);
    final teams = ApiTeamsRepository(admin.coreApi(), MockBackend.testTenantId);
    await expectLater(
      teams.setJersey('t1', 'p1', '10'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          409,
        ),
      ),
    );
    expect((await teams.setJersey('t1', 'p1', '11')).jerseyNumber, '11');
  });

  test('the eligible teams are only those the player may join '
      '(listEligibleTeams)', () async {
    final admin = MockBackend()
      ..seedCategories([u12, u14])
      ..seedTeams([team('t1', 'Mini A'), team('t2', 'Infantil', cat: u14)])
      ..seedPlayers([
        // 2013: an Infantil, too old for Mini A
        player(
          'p1',
          'Leo Gil',
        ).rebuild((b) => b.birthDate = api.Date(2013, 3, 4)),
      ]);
    final players = ApiPlayersRepository(
      admin.coreApi(),
      MockBackend.testTenantId,
    );
    final teams = await players.eligibleTeams('p1', seasonId);
    expect(teams.map((e) => e.team.id), ['t2']);
  });

  test('team staff list and read every player (listPlayers, getPlayer), '
      'also an assistant without a team yet', () async {
    final assistant = MockBackend(roles: {TenantRole.assistantCoach})
      ..seedTeams([team('t1', 'Mini A')])
      ..seedPlayers([
        player('p1', 'Ana Ruiz', teams: [assignment('t1', 'Mini A')]),
        player('p2', 'Leo Gil'),
      ]);
    final players = ApiPlayersRepository(
      assistant.coreApi(),
      MockBackend.testTenantId,
    );
    expect((await players.list()).map((p) => p.id), ['p1', 'p2']);
    expect((await players.get('p2')).displayName, 'Leo Gil');
  });
}
