import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/core_fixtures.dart';
import '../support/fake_repos.dart';
import '../support/pump_helpers.dart';

/// Regenerate with `flutter test --update-goldens test/golden`.
FakeCore _core() => FakeCore(
  teams: FakeTeamsRepository(
    teams: [
      team('t1', 'Mini A', alias: 'Leones', players: 12),
      team('t2', 'Infantil B', cat: u14, policy: api.GenderPolicy.FEMALE, players: 9),
      team('t3', 'Mini B', policy: api.GenderPolicy.MALE, players: 0),
    ],
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
    [member('m2', 'Pat Parent', roles: {api.TenantRole.PARENT})],
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
  testWidgets('teams list, ADMIN, 360x780', (tester) async {
    await pumpAs(tester, roles: {TenantRole.admin}, core: _core(), location: '/teams');
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/teams_list_360x780.png'));
  });

  testWidgets('player detail, ADMIN, 360x780', (tester) async {
    await pumpAs(tester, roles: {TenantRole.admin}, core: _core(), location: '/players/p1');
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/player_detail_360x780.png'));
  });
}
