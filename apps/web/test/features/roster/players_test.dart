import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart';
import '../../support/fake_repos.dart';
import '../../support/pump_helpers.dart';

FakeCore coreWithPlayers({bool coachRequests = false}) => FakeCore(
  teams: FakeTeamsRepository(teams: [team('t1', 'Mini A', players: 1), team('t2', 'Infantil B', cat: u14)]),
  players: FakePlayersRepository(
    [
      player('p1', 'Ana Ruiz', cat: u12, teams: [assignment('t1', 'Mini A', jersey: '7')]),
      player('p2', 'Leo Gil', cat: u14, status: api.PlayerStatus.ORPHAN),
      player('p3', 'Mia Soto', cat: u12, status: api.PlayerStatus.PENDING_APPROVAL),
      player('p4', 'Dan Lopez',
          cat: u12, teams: [assignment('t1', 'Mini A', playUp: 1, valid: false)]),
    ],
    eligible: {
      'p2': [
        api.EligibleTeam(
          (b) => b
            ..team.replace(team('t2', 'Infantil B', cat: u14))
            ..eligibility.replace(check('t2', 'p2', api.EligibilityResult.PLAY_UP, playUp: 1)),
        ),
      ],
    },
    createdPending: coachRequests,
  ),
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
  group('players list', () {
    testWidgets('loading', (tester) async {
      final core = coreWithPlayers()..players.hang = true;
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/players', settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      final core = coreWithPlayers()..players.failWith = const AppError(kind: AppErrorKind.network);
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/players');
      core.players.failWith = null;
      await tester.tap(find.byKey(const Key('retry-button')));
      await tester.pumpAndSettle();
      expect(find.text('Ana Ruiz'), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: FakeCore(), location: '/players');
      expect(find.text('No hay jugadores con estos filtros'), findsOneWidget);
    });

    testWidgets('populated with status chips incl. orphan and pending approval', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: coreWithPlayers(), location: '/players');
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('Sin equipo válido'), findsOneWidget);
      expect(find.text('Pendiente de aprobación'), findsOneWidget);
    });

    testWidgets('status filter queries the API; clear restores', (tester) async {
      final core = coreWithPlayers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/players');
      await tapKey(tester, 'filter-status');
      await tester.tap(find.text('Sin equipo válido').last);
      await tester.pumpAndSettle();
      expect(core.players.lastStatus, api.PlayerStatus.ORPHAN);
      expect(find.text('Leo Gil'), findsOneWidget);
      expect(find.text('Ana Ruiz'), findsNothing);

      await tapKey(tester, 'filter-clear');
      expect(find.text('Ana Ruiz'), findsOneWidget);
    });

    testWidgets('team filter is sent to the API, category filter applies on the result', (tester) async {
      final core = coreWithPlayers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/players');
      await tapKey(tester, 'filter-team');
      await tester.tap(find.text('Mini A').last);
      await tester.pumpAndSettle();
      expect(core.players.lastTeamId, 't1');

      await tapKey(tester, 'filter-category');
      await tester.tap(find.text('Infantil').last);
      await tester.pumpAndSettle();
      expect(find.text('Ana Ruiz'), findsNothing); // category Mini
      expect(find.text('Dan Lopez'), findsNothing);
    });

    testWidgets('search sends the query', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: coreWithPlayers(), location: '/players');
      await tester.enterText(find.byKey(const Key('player-search')), 'leo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Leo Gil'), findsOneWidget);
      expect(find.text('Ana Ruiz'), findsNothing);
    });

    testWidgets('create button per role: admin "new", coach "request", assistant none', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: coreWithPlayers(), location: '/players');
      expect(find.text('Nuevo jugador'), findsOneWidget);
    });

    testWidgets('coach sees the request button', (tester) async {
      await pumpAs(tester, roles: {TenantRole.coach}, core: coreWithPlayers(), location: '/players');
      expect(find.text('Solicitar nuevo jugador'), findsOneWidget);
      expect(find.byKey(const Key('open-requests')), findsOneWidget);
    });

    testWidgets('assistant: read-only list, no create, no requests inbox', (tester) async {
      await pumpAs(tester, roles: {TenantRole.assistantCoach}, core: coreWithPlayers(), location: '/players');
      expect(find.byKey(const Key('player-new')), findsNothing);
      expect(find.byKey(const Key('open-requests')), findsNothing);
      expect(find.text('Ana Ruiz'), findsOneWidget);
    });
  });

  group('player detail', () {
    testWidgets('admin: basics, teams with play-up and invalid markers, guardians', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: coreWithPlayers(), location: '/players/p1');
      expect(find.text('Datos básicos'), findsOneWidget);
      expect(find.text('2015-03-04'), findsOneWidget);
      expect(find.text('Mini A'), findsWidgets);
      expect(find.text('Pat Parent'), findsOneWidget);
    });

    testWidgets('play-up and ineligible markers on the team assignment', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: coreWithPlayers(), location: '/players/p4');
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('Ya no es elegible'), findsOneWidget);
    });

    testWidgets('coach does not request guardians (admin only)', (tester) async {
      final core = coreWithPlayers();
      await pumpAs(tester, roles: {TenantRole.coach}, core: core, location: '/players/p1');
      expect(find.text('Pat Parent'), findsNothing);
      expect(core.members.calls, isNot(contains('links')));
    });

    testWidgets('error state', (tester) async {
      final core = coreWithPlayers()..players.failWith = const AppError(kind: AppErrorKind.notFound, status: 404);
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/players/p1');
      expect(find.text('No hemos encontrado lo que buscas.'), findsOneWidget);
    });

    testWidgets('assistant has no actions', (tester) async {
      await pumpAs(tester, roles: {TenantRole.assistantCoach}, core: coreWithPlayers(), location: '/players/p1');
      expect(find.byKey(const Key('player-withdraw')), findsNothing);
      expect(find.byKey(const Key('player-assign')), findsNothing);
    });

    testWidgets('orphan: assign from eligible teams shows play-up badge and assigns', (tester) async {
      final core = coreWithPlayers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/players/p2');
      await tapKey(tester, 'player-assign');
      expect(find.text('Juega en categoría superior (+1)'), findsOneWidget);
      await tapKey(tester, 'eligible-t2');
      expect(core.teams.calls, contains('assign'));
      expect(core.teams.rosters['t2']!.single.player.id, 'p2');
    });

    testWidgets('orphan with no eligible team', (tester) async {
      final core = coreWithPlayers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/players/p4');
      await tapKey(tester, 'player-assign');
      expect(find.byKey(const Key('no-eligible-teams')), findsOneWidget);
    });

    testWidgets('admin withdraw: confirm with reason, player becomes withdrawn', (tester) async {
      final core = coreWithPlayers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/players/p1');
      await tapKey(tester, 'player-withdraw');
      await tester.enterText(find.byKey(const Key('note-field')), 'moved away');
      await tapKey(tester, 'dialog-confirm');
      expect(core.players.withdrawn, 'p1');
      expect(find.text('Jugador dado de baja'), findsOneWidget);
      expect(find.byKey(const Key('player-withdraw')), findsNothing);
    });

    testWidgets('coach withdraw only files a request', (tester) async {
      final core = coreWithPlayers(coachRequests: true);
      await pumpAs(tester, roles: {TenantRole.coach}, core: core, location: '/players/p1');
      await tapKey(tester, 'player-withdraw');
      await tapKey(tester, 'dialog-confirm');
      expect(find.text('Solicitud de baja enviada'), findsOneWidget);
    });
  });

  group('create player', () {
    Future<void> fill(WidgetTester tester) async {
      await enter(tester, 'player-given', 'Noa');
      await enter(tester, 'player-family', 'Prieto');
      await tapKey(tester, 'player-birth');
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
    }

    testWidgets('validation: names and birth date required', (tester) async {
      final core = coreWithPlayers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/players/new');
      await tapKey(tester, 'player-submit');
      expect(find.text('Campo obligatorio'), findsNWidgets(2));
      expect(find.byKey(const Key('player-birth-error')), findsOneWidget);
      expect(core.players.lastCreate, isNull);
    });

    testWidgets('admin creates directly and returns to the list', (tester) async {
      final core = coreWithPlayers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/players/new');
      await fill(tester);
      await tapKey(tester, 'player-submit');
      final sent = core.players.lastCreate!;
      expect(sent.givenName, 'Noa');
      expect(sent.familyName, 'Prieto');
      expect(sent.note, isNull);
      expect(find.text('Jugador creado'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Noa Prieto'), 100, scrollable: find.byType(Scrollable).last);
      expect(find.text('Noa Prieto'), findsOneWidget);
    });

    testWidgets('coach files a request with an initial own team and a note', (tester) async {
      final core = coreWithPlayers(coachRequests: true);
      await pumpAs(tester, roles: {TenantRole.coach}, core: core, location: '/players/new', staffTeamIds: {'t1'});
      expect(find.text('Solicitar nuevo jugador'), findsWidgets);
      await fill(tester);
      await tester.tap(find.byKey(const Key('player-team')));
      await tester.pumpAndSettle();
      expect(find.text('Infantil B'), findsNothing); // only own teams are offered
      await tester.tap(find.text('Mini A').last);
      await tester.pumpAndSettle();
      await enter(tester, 'player-note', 'Visto en el torneo');
      await tapKey(tester, 'player-submit');

      final sent = core.players.lastCreate!;
      expect(sent.teamId, 't1');
      expect(sent.note, 'Visto en el torneo');
      expect(find.text('Solicitud enviada al administrador'), findsOneWidget);
    });

    testWidgets('a server rejection (422) stays on the form with a localized message', (tester) async {
      final core = coreWithPlayers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/players/new');
      await fill(tester);
      core.players.failWith = const AppError(kind: AppErrorKind.validation, status: 422);
      await tapKey(tester, 'player-submit');
      expect(find.text('Revisa los datos introducidos.'), findsOneWidget);
      expect(find.byKey(const Key('player-submit')), findsOneWidget);
    });
  });
}
