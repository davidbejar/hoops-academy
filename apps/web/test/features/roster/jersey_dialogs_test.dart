import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart';
import '../../support/core_seed.dart';
import '../../support/harness.dart';
import '../../support/pump_helpers.dart';

/// Ana wears 7 and Leo 10 in Mini A; Mia (p3) and Dan (p4, born 2013: an
/// Infantil) can be assigned. Without a requested, preferred or previous
/// number the mock assigns none; [miaPreferred], [miaPrevious] (her number in
/// Infantil) and [danPreferred] give the other rules something to apply.
FakeCore _core({
  String? miaPreferred,
  String? miaPrevious,
  String? danPreferred,
}) => FakeCore(
  teams: TeamsData(
    teams: [
      team('t1', 'Mini A', players: 2),
      team('t2', 'Infantil', cat: u14),
    ],
    rosters: {
      't1': [
        teamPlayer('t1', 'p1', 'Ana Ruiz', jersey: '7'),
        teamPlayer('t1', 'p2', 'Leo Gil', jersey: '10'),
      ],
      if (miaPrevious != null)
        't2': [teamPlayer('t2', 'p3', 'Mia Soto', jersey: miaPrevious)],
    },
  ),
  players: PlayersData([
    player('p1', 'Ana Ruiz'),
    player('p2', 'Leo Gil'),
    player(
      'p3',
      'Mia Soto',
    ).rebuild((b) => b.preferredJerseyNumber = miaPreferred),
    player('p4', 'Dan Lopez', status: api.PlayerStatus.ORPHAN).rebuild(
      (b) => b
        ..birthDate = api.Date(2013, 3, 4)
        ..preferredJerseyNumber = danPreferred,
    ),
  ]),
);

Future<void> _assignMia(WidgetTester tester, FakeCore core) async {
  await pumpAs(
    tester,
    roles: {TenantRole.admin},
    core: core,
    location: '/teams/t1',
  );
  await tapKey(tester, 'roster-assign');
  await tapKey(tester, 'assign-candidate-p3');
}

void main() {
  group('after an assignment the dialog tells which rule applied', () {
    testWidgets('the requested number', (tester) async {
      final core = _core();
      await _assignMia(tester, core);
      await tester.enterText(find.byKey(const Key('assign-jersey')), '9');
      await tapKey(tester, 'assign-confirm');

      expect(find.byKey(const Key('assignment-outcome')), findsOneWidget);
      expect(find.text('Dorsal 9 asignado, el que se pidió.'), findsOneWidget);
      expect(find.text('Jugador asignado'), findsOneWidget);
    });

    testWidgets('the preferred number', (tester) async {
      final core = _core(miaPreferred: '5');
      await _assignMia(tester, core);
      await tapKey(tester, 'assign-confirm');

      expect(
        find.text('Dorsal 5 asignado: es el que el jugador prefería.'),
        findsOneWidget,
      );
    });

    testWidgets('the number of the previous team', (tester) async {
      final core = _core(miaPrevious: '12');
      await _assignMia(tester, core);
      await tapKey(tester, 'assign-confirm');

      expect(
        find.text('Dorsal 12 asignado: es el que tenía en su equipo anterior.'),
        findsOneWidget,
      );
    });

    testWidgets('none free: says so and offers the jersey dialog at once', (
      tester,
    ) async {
      final core = _core(); // no preferred or previous number
      await _assignMia(tester, core);
      await tapKey(tester, 'assign-confirm');

      expect(find.byKey(const Key('jersey-field')), findsOneWidget);
      expect(find.byKey(const Key('jersey-notice')), findsOneWidget);
      expect(find.textContaining('No se asignó dorsal'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('jersey-field')), '12');
      await tapKey(tester, 'form-submit');
      expect(
        core.teams.rosters['t1']!
            .firstWhere((p) => p.player.id == 'p3')
            .jerseyNumber,
        '12',
      );
    });

    testWidgets('assigning from the player screen tells the rule too', (
      tester,
    ) async {
      final core = _core(danPreferred: '3');
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: '/players/p4',
      );
      await tapKey(tester, 'player-assign');
      await tapKey(tester, 'eligible-t2');

      expect(find.byKey(const Key('assignment-outcome')), findsOneWidget);
      expect(
        find.text('Dorsal 3 asignado: es el que el jugador prefería.'),
        findsOneWidget,
      );
    });
  });

  group('jersey dialog', () {
    Future<Harness> open(
      WidgetTester tester,
      FakeCore core,
      String playerId,
    ) async {
      final h = await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: '/teams/t1',
      );
      await tapKey(tester, 'roster-menu-$playerId');
      await tester.tap(find.text('Cambiar dorsal'));
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets('shows the taken numbers with their players and the free '
        'ones', (tester) async {
      await open(tester, _core(), 'p1');

      expect(find.byKey(const Key('jersey-taken-p2')), findsOneWidget);
      expect(find.text('10 · Leo Gil'), findsOneWidget);
      // its own number is not "taken" for the player
      expect(find.byKey(const Key('jersey-taken-p1')), findsNothing);
      expect(find.byKey(const Key('jersey-free-3')), findsOneWidget);
      expect(find.byKey(const Key('jersey-free-10')), findsNothing);
    });

    testWidgets('a free number fills the field', (tester) async {
      await open(tester, _core(), 'p1');
      await tester.tap(find.byKey(const Key('jersey-free-3')));
      await tester.pump();

      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('jersey-field')))
            .controller!
            .text,
        '3',
      );
    });

    testWidgets('a taken number names the player and blocks the save', (
      tester,
    ) async {
      final core = _core();
      await open(tester, core, 'p1');
      await tester.enterText(find.byKey(const Key('jersey-field')), '10');
      await tapKey(tester, 'form-submit');

      expect(find.text('El 10 lo tiene Leo Gil'), findsOneWidget);
      expect(core.teams.rosters['t1']!.first.jerseyNumber, '7');
    });

    testWidgets('a 409 from the server reloads the numbers and names the '
        'holder', (tester) async {
      final h = await open(tester, _core(), 'p1');
      // somebody gave Leo the 9 after the dialog loaded the list: the mock
      // answers 409
      final leo = h.backend.core.players.firstWhere((p) => p['id'] == 'p2');
      ((leo['teams']! as List).single as Map)['jerseyNumber'] = '9';
      await tester.enterText(find.byKey(const Key('jersey-field')), '9');
      await tapKey(tester, 'form-submit');

      expect(find.byKey(const Key('jersey-field')), findsOneWidget);
      expect(find.text('El 9 lo tiene Leo Gil'), findsOneWidget);
    });
  });
}
