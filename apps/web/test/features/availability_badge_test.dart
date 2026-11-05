import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/core_fixtures.dart';
import '../support/fake_athlete.dart';
import '../support/fake_game.dart' show teamA;
import '../support/fake_repos.dart';
import '../support/pump_helpers.dart';
import 'match/presentation/match_screens_test.dart' show coreWithTeam, gameWith, sched;

FakeAthlete _withInjury() => FakeAthlete(
  health: FakeHealthRepository(
    injuries: [injury('inj-1', 'p1', part: 'Rodilla', expected: ath.Date(2026, 11, 30))],
  ),
);

void main() {
  testWidgets('team roster rows show who is injured', (tester) async {
    final core = FakeCore(
      teams: FakeTeamsRepository(
        teams: [team('t1', 'Mini A', players: 2)],
        rosters: {
          't1': [teamPlayer('t1', 'p1', 'Ana Ruiz', jersey: '7'), teamPlayer('t1', 'p2', 'Leo Gil', jersey: '10')],
        },
      ),
    );
    await pumpAs(tester, roles: {TenantRole.admin}, core: core, athlete: _withInjury(), location: '/teams/t1', size: const Size(360, 1400));
    expect(
      find.descendant(of: find.byKey(const Key('roster-p1')), matching: find.byKey(const Key('availability-injured'))),
      findsOneWidget,
    );
    expect(find.text('Lesionado: Rodilla'), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const Key('roster-p2')), matching: find.byKey(const Key('availability-injured'))),
      findsNothing,
    );
  });

  testWidgets('match setup rows show who is injured (the coach still decides)', (tester) async {
    await pumpAs(
      tester,
      roles: {TenantRole.coach},
      staffTeamIds: {teamA},
      core: coreWithTeam(),
      game: gameWith(),
      athlete: _withInjury(),
      location: '/matches/$sched/setup',
    );
    expect(
      find.descendant(of: find.byKey(const Key('setup-p1')), matching: find.byKey(const Key('availability-injured'))),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(const Key('setup-p2')), matching: find.byKey(const Key('availability-injured'))),
      findsNothing,
    );
    // Not blocked: the injured player can still be included.
    expect(tester.widget<Checkbox>(find.byKey(const Key('setup-include-p1'))).onChanged, isNotNull);
  });
}
