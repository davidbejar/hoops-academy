import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart';
import '../../support/fake_repos.dart';
import '../../support/pump_helpers.dart';

FakeCore coreWithTeams() => FakeCore(
  teams: FakeTeamsRepository(
    teams: [
      team('t1', 'Mini A', alias: 'Leones', players: 2),
      team('t2', 'Infantil B', cat: u14, policy: api.GenderPolicy.FEMALE, players: 0),
    ],
    rosters: {
      't1': [
        teamPlayer('t1', 'p1', 'Ana Ruiz', jersey: '7'),
        teamPlayer('t1', 'p2', 'Leo Gil', jersey: '10', playUp: 1),
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
    checks: {
      't1/p3': check('t1', 'p3', api.EligibilityResult.PLAY_UP, playUp: 1),
      't1/p4': check('t1', 'p4', api.EligibilityResult.INELIGIBLE,
          reasons: [api.EligibilityReason.CATEGORY_TOO_LOW, api.EligibilityReason.GENDER_POLICY]),
    },
  ),
  players: FakePlayersRepository([
    player('p1', 'Ana Ruiz'),
    player('p2', 'Leo Gil'),
    player('p3', 'Mia Soto'),
    player('p4', 'Dan Lopez', status: api.PlayerStatus.ORPHAN),
    player('p5', 'Withdrawn One', status: api.PlayerStatus.WITHDRAWN),
  ]),
  members: FakeMembersRepository([
    member('m1', 'Casey Coach', roles: {api.TenantRole.COACH}),
    member('m2', 'Ally Assist', roles: {api.TenantRole.ASSISTANT_COACH}),
    member('m3', 'Pat Parent', roles: {api.TenantRole.PARENT}),
  ]),
);

void main() {
  group('teams list', () {
    testWidgets('loading', (tester) async {
      final core = coreWithTeams()..teams.hang = true;
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/teams', settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      final core = coreWithTeams()..teams.failWith = const AppError(kind: AppErrorKind.server);
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/teams');
      core.teams.failWith = null;
      await tester.tap(find.byKey(const Key('retry-button')));
      await tester.pumpAndSettle();
      expect(find.text('Mini A (Leones)'), findsOneWidget);
    });

    testWidgets('empty season and no season at all', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: FakeCore(), location: '/teams');
      expect(find.text('No hay equipos en esta temporada'), findsOneWidget);
    });

    testWidgets('no season yet asks to create one first', (tester) async {
      final core = FakeCore(seasons: FakeSeasonsRepository([]));
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/teams');
      expect(find.text('Crea primero una temporada'), findsOneWidget);
    });

    testWidgets('populated: name, category, gender policy, player count', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: coreWithTeams(), location: '/teams');
      expect(find.text('Mini A (Leones)'), findsOneWidget);
      expect(find.text('Femenino'), findsOneWidget);
      expect(find.text('2 jugadores'), findsOneWidget);
    });

    testWidgets('only ADMIN can create teams', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: coreWithTeams(), location: '/teams');
      expect(find.byKey(const Key('team-new')), findsOneWidget);
    });

    testWidgets('COACH and ASSISTANT do not get the create button; coach sees own team marker', (tester) async {
      await pumpAs(tester, roles: {TenantRole.coach}, core: coreWithTeams(), location: '/teams', staffTeamIds: {'t1'});
      expect(find.byKey(const Key('team-new')), findsNothing);
      expect(find.text('Entrenador'), findsOneWidget); // marker on t1 only
    });

    testWidgets('assistant: no create', (tester) async {
      await pumpAs(tester, roles: {TenantRole.assistantCoach}, core: coreWithTeams(), location: '/teams');
      expect(find.byKey(const Key('team-new')), findsNothing);
    });

    testWidgets('create team: validation then saved with category and gender policy', (tester) async {
      final core = coreWithTeams();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/teams');
      await tapKey(tester, 'team-new');
      await tapKey(tester, 'form-submit');
      expect(find.text('Campo obligatorio'), findsWidgets);
      expect(core.teams.lastCreate, isNull);

      await enter(tester, 'team-name', 'Cadete A');
      await tester.tap(find.byKey(const Key('team-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('U14 · Infantil').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('team-policy')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Masculino').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'form-submit');

      final sent = core.teams.lastCreate!;
      expect(sent.name, 'Cadete A');
      expect(sent.ageCategoryId, catU14Id);
      expect(sent.genderPolicy, api.GenderPolicy.MALE);
      expect(sent.seasonId, seasonId);
      expect(find.text('Cadete A'), findsOneWidget);
    });
  });

  group('team detail', () {
    const path = '/teams/t1';

    testWidgets('admin sees roster, play-up badge, staff, and all actions', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: coreWithTeams(), location: path);
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('Leo Gil'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('Casey Coach'), findsOneWidget);
      expect(find.byKey(const Key('roster-assign')), findsOneWidget);
      expect(find.byKey(const Key('staff-add')), findsOneWidget);
      expect(find.byKey(const Key('team-edit')), findsOneWidget);
      expect(find.byKey(const Key('read-only')), findsNothing);
    });

    testWidgets('coach on own team: can assign, cannot manage staff or edit the team', (tester) async {
      await pumpAs(tester, roles: {TenantRole.coach}, core: coreWithTeams(), location: path, staffTeamIds: {'t1'});
      expect(find.byKey(const Key('roster-assign')), findsOneWidget);
      expect(find.byKey(const Key('staff-add')), findsNothing);
      expect(find.byKey(const Key('team-edit')), findsNothing);
    });

    testWidgets('coach on another team: read-only', (tester) async {
      await pumpAs(tester, roles: {TenantRole.coach}, core: coreWithTeams(), location: path, staffTeamIds: {'t2'});
      expect(find.byKey(const Key('roster-assign')), findsNothing);
      expect(find.byKey(const Key('roster-menu-p1')), findsNothing);
      expect(find.byKey(const Key('read-only')), findsOneWidget);
    });

    testWidgets('assistant is read-only even on own team', (tester) async {
      await pumpAs(tester, roles: {TenantRole.assistantCoach}, core: coreWithTeams(), location: path, staffTeamIds: {'t1'});
      expect(find.byKey(const Key('roster-assign')), findsNothing);
      expect(find.byKey(const Key('read-only')), findsOneWidget);
    });

    testWidgets('error and loading', (tester) async {
      final failing = coreWithTeams()..teams.failWith = const AppError(kind: AppErrorKind.notFound, status: 404);
      await pumpAs(tester, roles: {TenantRole.admin}, core: failing, location: path);
      expect(find.text('No hemos encontrado lo que buscas.'), findsOneWidget);
    });

    testWidgets('unassign asks for confirmation; jersey change saves', (tester) async {
      final core = coreWithTeams();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: path);

      await tapKey(tester, 'roster-menu-p1');
      await tester.tap(find.text('Cambiar dorsal'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('note-field')), '12');
      await tapKey(tester, 'dialog-confirm');
      expect(core.teams.rosters['t1']!.first.jerseyNumber, '12');

      await tapKey(tester, 'roster-menu-p1');
      await tester.tap(find.text('Quitar de la plantilla'));
      await tester.pumpAndSettle();
      expect(find.textContaining('¿Quitar a Ana Ruiz de la plantilla?'), findsOneWidget);
      await tapKey(tester, 'dialog-confirm');
      expect(core.teams.calls, contains('unassign'));
      expect(find.text('Ana Ruiz'), findsNothing);
    });

    testWidgets('add and remove team staff (admin)', (tester) async {
      final core = coreWithTeams();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: path);
      await tapKey(tester, 'staff-add');
      await tester.tap(find.byKey(const Key('staff-person')));
      await tester.pumpAndSettle();
      expect(find.text('Pat Parent'), findsNothing); // only coaches / assistants are offered
      await tester.tap(find.text('Ally Assist').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'form-submit');
      expect(core.teams.calls, contains('putStaff'));
      expect(core.teams.staffByTeam['t1']!.length, 2);
    });
  });

  group('assign player (eligibility)', () {
    Future<void> openDialog(WidgetTester tester, FakeCore core) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/teams/t1');
      await tapKey(tester, 'roster-assign');
    }

    testWidgets('lists only assignable players (not already on the team, not withdrawn)', (tester) async {
      await openDialog(tester, coreWithTeams());
      expect(find.byKey(const Key('assign-candidate-p3')), findsOneWidget);
      expect(find.byKey(const Key('assign-candidate-p4')), findsOneWidget);
      expect(find.byKey(const Key('assign-candidate-p1')), findsNothing); // on roster
      expect(find.byKey(const Key('assign-candidate-p5')), findsNothing); // withdrawn
    });

    testWidgets('play-up verdict shows the badge and allows assigning with a jersey', (tester) async {
      final core = coreWithTeams();
      await openDialog(tester, core);
      await tapKey(tester, 'assign-candidate-p3');
      expect(find.text('Juega en categoría superior (+1)'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('assign-jersey')), '9');
      await tapKey(tester, 'assign-confirm');
      final added = core.teams.rosters['t1']!.last;
      expect(added.player.id, 'p3');
      expect(added.jerseyNumber, '9');
      expect(find.text('Jugador asignado'), findsOneWidget);
    });

    testWidgets('ineligible verdict lists the reasons and blocks the assignment', (tester) async {
      final core = coreWithTeams();
      await openDialog(tester, core);
      await tapKey(tester, 'assign-candidate-p4');
      expect(find.text('No elegible'), findsOneWidget);
      expect(find.text('Es demasiado mayor para esta categoría'), findsOneWidget);
      expect(find.text('No cumple la política de género del equipo'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byKey(const Key('assign-confirm')));
      expect(button.onPressed, isNull);
      expect(core.teams.calls, isNot(contains('assign')));
    });

    testWidgets('a plainly eligible player is shown as eligible', (tester) async {
      final core = coreWithTeams();
      core.players.players.add(player('p6', 'Zoe Mar'));
      await openDialog(tester, core);
      await tapKey(tester, 'assign-candidate-p6');
      expect(find.text('Elegible'), findsOneWidget);
    });
  });
}
