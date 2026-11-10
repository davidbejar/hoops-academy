import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart';
import '../../support/fake_repos.dart';
import '../../support/pump_helpers.dart';

FakeCore _core({String? preferred}) => FakeCore(
  teams: FakeTeamsRepository(
    teams: [team('t1', 'Mini A', players: 1)],
    rosters: {
      't1': [teamPlayer('t1', 'p1', 'Ana Ruiz', jersey: '7')],
    },
  ),
  players: FakePlayersRepository([
    player(
      'p1',
      'Ana Ruiz',
      teams: [assignment('t1', 'Mini A', jersey: '7')],
    ).rebuild((b) => b.preferredJerseyNumber = preferred),
  ]),
);

const _card = Key('preferred-jersey');
const _edit = Key('preferred-jersey-edit');

Future<void> _pump(
  WidgetTester tester,
  FakeCore core, {
  required Set<TenantRole> roles,
  required String location,
  Set<String> staffTeamIds = const {'t1'},
  Set<String> linkedPlayerIds = const {},
  String? ownPlayerId,
}) => pumpAs(
  tester,
  roles: roles,
  core: core,
  location: location,
  staffTeamIds: staffTeamIds,
  linkedPlayerIds: linkedPlayerIds,
  ownPlayerId: ownPlayerId,
);

void main() {
  group('staff on the player screen', () {
    testWidgets('the number is shown', (tester) async {
      await _pump(
        tester,
        _core(preferred: '11'),
        roles: {TenantRole.admin},
        location: '/players/p1',
      );
      expect(
        find.descendant(of: find.byKey(_card), matching: find.text('11')),
        findsOneWidget,
      );
      expect(find.text('Dorsal preferido'), findsOneWidget);
    });

    testWidgets('no number says so', (tester) async {
      await _pump(
        tester,
        _core(),
        roles: {TenantRole.admin},
        location: '/players/p1',
      );
      expect(find.text('Sin dorsal preferido'), findsOneWidget);
    });

    for (final role in [TenantRole.admin, TenantRole.coach]) {
      testWidgets('${role.name} sets it', (tester) async {
        final core = _core();
        await _pump(tester, core, roles: {role}, location: '/players/p1');
        await tapKey(tester, 'preferred-jersey-edit');
        await tester.enterText(
          find.byKey(const Key('preferred-jersey-field')),
          '23',
        );
        await tapKey(tester, 'form-submit');

        expect(core.players.lastPreferred, ('p1', '23'));
        expect(
          find.descendant(of: find.byKey(_card), matching: find.text('23')),
          findsOneWidget,
        );
      });
    }

    testWidgets('an empty value clears it', (tester) async {
      final core = _core(preferred: '11');
      await _pump(
        tester,
        core,
        roles: {TenantRole.admin},
        location: '/players/p1',
      );
      await tapKey(tester, 'preferred-jersey-edit');
      await tester.enterText(find.byKey(const Key('preferred-jersey-field')), '');
      await tapKey(tester, 'form-submit');

      expect(core.players.lastPreferred, ('p1', null));
    });

    testWidgets('more than two digits or letters are refused', (tester) async {
      final core = _core();
      await _pump(
        tester,
        core,
        roles: {TenantRole.admin},
        location: '/players/p1',
      );
      await tapKey(tester, 'preferred-jersey-edit');
      for (final bad in ['123', 'ab']) {
        await tester.enterText(
          find.byKey(const Key('preferred-jersey-field')),
          bad,
        );
        await tapKey(tester, 'form-submit');
        expect(core.players.lastPreferred, isNull, reason: bad);
      }
    });

    testWidgets('an assistant coach sees it but has no edit button', (
      tester,
    ) async {
      await _pump(
        tester,
        _core(preferred: '11'),
        roles: {TenantRole.assistantCoach},
        location: '/players/p1',
      );
      expect(find.byKey(_card), findsOneWidget);
      expect(find.byKey(_edit), findsNothing);
    });
  });

  group('a wish of the family', () {
    testWidgets('a parent edits it for a linked player, labelled as a wish', (
      tester,
    ) async {
      final core = _core();
      await _pump(
        tester,
        core,
        roles: {TenantRole.parent},
        location: '/my-players',
        staffTeamIds: const {},
        linkedPlayerIds: const {'p1'},
      );
      expect(find.text('Dorsal deseado'), findsOneWidget);
      expect(find.byKey(const Key('preferred-jersey-wish-hint')), findsOneWidget);

      await tapKey(tester, 'preferred-jersey-edit');
      await tester.enterText(find.byKey(const Key('preferred-jersey-field')), '5');
      await tapKey(tester, 'form-submit');
      expect(core.players.lastPreferred, ('p1', '5'));
    });

    testWidgets('a player edits his own, labelled as a wish', (tester) async {
      final core = _core(preferred: '4');
      await _pump(
        tester,
        core,
        roles: {TenantRole.player},
        location: '/me',
        staffTeamIds: const {},
        ownPlayerId: 'p1',
      );
      expect(find.text('Dorsal deseado'), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(_card), matching: find.text('4')),
        findsOneWidget,
      );
      await tapKey(tester, 'preferred-jersey-edit');
      await tester.enterText(find.byKey(const Key('preferred-jersey-field')), '');
      await tapKey(tester, 'form-submit');
      expect(core.players.lastPreferred, ('p1', null));
    });
  });
}
