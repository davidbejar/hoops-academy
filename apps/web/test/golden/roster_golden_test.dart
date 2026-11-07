import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/core_fixtures.dart';
import '../support/fake_repos.dart';
import '../support/pump_helpers.dart';

/// Teams list (light and dark), team detail and player detail of the roster
/// screens. Regenerate with
/// `flutter test --update-goldens test/golden/roster_golden_test.dart`.
FakeCore _core() => FakeCore(
  teams: FakeTeamsRepository(
    teams: [
      team('t1', 'Mini A', alias: 'Leones', players: 12),
      team(
        't2',
        'Infantil B',
        cat: u14,
        policy: api.GenderPolicy.FEMALE,
        players: 9,
      ),
      team('t3', 'Mini B', policy: api.GenderPolicy.MALE, players: 0),
    ],
    rosters: {
      't1': [
        teamPlayer('t1', 'p1', 'Ana Ruiz', jersey: '7'),
        teamPlayer('t1', 'p2', 'Leo Gil', jersey: '10', playUp: 1),
        teamPlayer('t1', 'p3', 'Mia Soto'),
      ],
    },
    staff: {
      't1': [
        api.TeamStaffMember(
          (b) => b
            ..person.replace(personRef('m1', 'Casey Coach'))
            ..role = api.StaffRole.COACH
            ..since = api.Date(2026, 9, 1),
        ),
      ],
    },
  ),
  players: FakePlayersRepository([
    player(
      'p1',
      'Ana Ruiz',
      cat: u12,
      teams: [
        assignment('t1', 'Mini A', jersey: '7'),
        assignment('t2', 'Infantil B', jersey: '11', playUp: 1),
      ],
    ),
  ]),
  members: FakeMembersRepository(
    [
      member('m2', 'Pat Parent', roles: {api.TenantRole.PARENT}),
    ],
    links: [
      api.GuardianLink(
        (b) => b
          ..id = 'l1'
          ..guardian.replace(personRef('m2', 'Pat Parent'))
          ..player.replace(playerRef('p1', 'Ana Ruiz'))
          ..createdAt = DateTime.utc(2026, 1, 1),
      ),
    ],
  ),
);

void main() {
  for (final (name, brightness) in [
    ('teams_list_360x780', Brightness.light),
    ('teams_list_360x780_dark', Brightness.dark),
  ]) {
    testWidgets('teams list, ADMIN, $name', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: _core(),
        location: '/teams',
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    });
  }

  testWidgets('team detail, ADMIN, 360x780', (tester) async {
    await pumpAs(
      tester,
      roles: {TenantRole.admin},
      core: _core(),
      location: '/teams/t1',
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/team_detail_360x780.png'),
    );
  });

  testWidgets('player detail, ADMIN, 360x780', (tester) async {
    await pumpAs(
      tester,
      roles: {TenantRole.admin},
      core: _core(),
      location: '/players/p1',
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/player_detail_360x780.png'),
    );
  });
}
