import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/roster/data/teams_repository.dart';

import '../support/core_fixtures.dart';
import '../support/core_seed.dart';
import '../support/fixtures.dart';
import '../support/mock_backend.dart';

/// The demo mock's teams follow core (ADR-0070: the teams fake did, the mock
/// did not).
void main() {
  test('any member reads any team and its roster (getTeam, listTeamPlayers: '
      'any member)', () async {
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
  });
}
