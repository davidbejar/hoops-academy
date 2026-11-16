import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/ui/kit.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../support/core_fixtures.dart';
import '../../support/fake_finance.dart';
import '../../support/finance_pump.dart';
import '../../support/pump_helpers.dart';

/// What the coach and the family see of the dues (decision 96): the coach a
/// marker per player on the team's screen, the family the dues of each
/// linked player (or their own) in the player's hub.
void main() {
  const notYet =
      'Esta parte de las finanzas todavía no está disponible en el '
      'servidor. Inténtalo más tarde.';

  api.TeamStaffMember staff(String id, api.StaffRole role) =>
      api.TeamStaffMember(
        (b) => b
          ..person.replace(personRef(id, 'Staff $id'))
          ..role = role
          ..since = api.Date(2026, 9, 1),
      );

  group("the coach's view on the team screen", () {
    const path = '/teams/team-mini-a';

    Future<void> pumpCoach(
      WidgetTester tester,
      FakeFinanceRepository repo, {
      Set<TenantRole> roles = const {TenantRole.coach},
      Set<String> staffTeamIds = const {'team-mini-a'},
      api.StaffRole role = api.StaffRole.COACH,
      bool settle = true,
    }) => pumpFinance(
      tester,
      repo: repo,
      roles: roles,
      location: path,
      staffTeamIds: staffTeamIds,
      settle: settle,
      core: financeCore(
        staff: {
          'team-mini-a': [staff('person-me', role)],
        },
      ),
    );

    Future<fin.TeamDueStatus> seed(WidgetTester tester) async =>
        (await tester.runAsync(
          () =>
              FakeFinanceRepository(roles: ['COACH'])
                  .teamDueStatus('team-mini-a'),
        ))!;

    testWidgets('a marker per player, no amounts', (tester) async {
      final repo = FakeFinanceRepository(roles: ['COACH']);
      await pumpCoach(tester, repo);
      final status = await seed(tester);
      expect(repo.last['teamDueStatus'], 'team-mini-a');
      expect(find.byKey(const Key('due-status')), findsOneWidget);
      for (final p in status.players) {
        final row = find.byKey(Key('due-status-${p.playerId}'));
        expect(row, findsOneWidget, reason: p.playerName);
        expect(
          find.descendant(
            of: row,
            matching: find.text(
              p.upToDate ? 'Al día' : 'Con cuotas pendientes',
            ),
          ),
          findsOneWidget,
          reason: p.playerName,
        );
      }
      final behind = status.players.where((p) => !p.upToDate).length;
      expect(
        find.text('$behind de ${status.players.length} con cuotas pendientes'),
        findsOneWidget,
      );
      expect(find.textContaining('€'), findsNothing);
    });

    testWidgets('an ASSISTANT_COACH does not see it', (tester) async {
      final repo = FakeFinanceRepository(roles: ['ASSISTANT_COACH']);
      await pumpCoach(
        tester,
        repo,
        roles: {TenantRole.assistantCoach},
        role: api.StaffRole.ASSISTANT_COACH,
      );
      expect(find.byKey(const Key('due-status')), findsNothing);
      expect(repo.calls, isNot(contains('teamDueStatus')));
    });

    testWidgets('a COACH who is only the assistant of this team does not', (
      tester,
    ) async {
      final repo = FakeFinanceRepository(roles: ['COACH']);
      await pumpCoach(tester, repo, role: api.StaffRole.ASSISTANT_COACH);
      expect(find.byKey(const Key('due-status')), findsNothing);
      expect(repo.calls, isNot(contains('teamDueStatus')));
    });

    testWidgets('a COACH of another team does not', (tester) async {
      final repo = FakeFinanceRepository(roles: ['COACH']);
      await pumpCoach(tester, repo, staffTeamIds: {'team-mini-b'});
      expect(find.byKey(const Key('due-status')), findsNothing);
      expect(repo.calls, isNot(contains('teamDueStatus')));
    });

    testWidgets('a parent, a player and a plain admin do not', (tester) async {
      for (final role in [
        TenantRole.parent,
        TenantRole.player,
        TenantRole.admin,
      ]) {
        final repo = FakeFinanceRepository(roles: [role.name.toUpperCase()]);
        await pumpCoach(tester, repo, roles: {role}, staffTeamIds: const {});
        expect(
          find.byKey(const Key('due-status')),
          findsNothing,
          reason: '$role',
        );
        expect(repo.calls, isNot(contains('teamDueStatus')));
      }
    });

    testWidgets('a team without players says so', (tester) async {
      final repo = FakeFinanceRepository(roles: ['COACH'])
        ..teamStatus = fin.TeamDueStatus(
          (b) => b
            ..teamId = 'team-mini-a'
            ..players.replace([]),
        );
      await pumpCoach(tester, repo);
      expect(find.text('El equipo no tiene jugadores'), findsOneWidget);
    });

    testWidgets('loading', (tester) async {
      final repo = FakeFinanceRepository(roles: ['COACH'])..hang = true;
      await pumpCoach(tester, repo, settle: false);
      await tester.pump();
      expect(find.byKey(const Key('due-status')), findsOneWidget);
    });

    testWidgets('a failure of this part leaves the team screen intact', (
      tester,
    ) async {
      final repo = FakeFinanceRepository(roles: ['COACH'])
        ..failOn['teamDueStatus'] = const AppError(
          kind: AppErrorKind.server,
          status: 500,
        );
      await pumpCoach(tester, repo);
      expect(find.byKey(const Key('due-status')), findsOneWidget);
      expect(find.byKey(const Key('due-status-retry')), findsOneWidget);
      expect(find.byKey(const Key('roster-assign')), findsOneWidget);
    });

    testWidgets('a service that does not answer yet says so (501)', (
      tester,
    ) async {
      final repo = FakeFinanceRepository(roles: ['COACH'])..notYetServed();
      await pumpCoach(tester, repo);
      expect(find.text(notYet), findsOneWidget);
    });

    testWidgets('a refusal (403) hides the part instead of failing', (
      tester,
    ) async {
      final repo = FakeFinanceRepository(roles: ['COACH'])
        ..failOn['teamDueStatus'] = const AppError(
          kind: AppErrorKind.forbidden,
          status: 403,
        );
      await pumpCoach(tester, repo);
      expect(find.byKey(const Key('due-status')), findsNothing);
      expect(find.byKey(const Key('due-status-retry')), findsNothing);
    });
  });

  group("the family's dues in the player's hub", () {
    Future<void> pumpFamily(
      WidgetTester tester,
      FakeFinanceRepository repo, {
      required Set<TenantRole> roles,
      Set<String> linked = const {},
      String? own,
      String location = '/my-players',
    }) => pumpFinance(
      tester,
      repo: repo,
      roles: roles,
      location: location,
      linkedPlayerIds: linked,
      ownPlayerId: own,
    );

    testWidgets('a parent reads the dues of the linked player', (tester) async {
      final repo = FakeFinanceRepository(roles: ['PARENT']);
      await pumpFamily(
        tester,
        repo,
        roles: {TenantRole.parent},
        linked: {'p-ana'},
      );
      await tapKey(tester, 'hub-tab-dues');
      expect(repo.last['playerDues'], 'p-ana');
      final page = (await tester.runAsync(() => repo.playerDues('p-ana')))!;
      expect(page.items, hasLength(3));
      for (final d in page.items) {
        expect(find.byKey(Key('family-due-${d.id}')), findsOneWidget);
      }
      // Newest period first: November, then October, then September.
      final rows = tester
          .widgetList<ListRow>(find.byType(ListRow))
          .map((r) => r.subtitle ?? '')
          .where((t) => t.contains('de 2026'))
          .toList();
      expect(rows.first, contains('noviembre de 2026'));
      expect(rows.last, contains('septiembre de 2026'));
      expect(find.text('45,00 €'), findsWidgets);
    });

    testWidgets('state and payment date of a paid due, none of an open one', (
      tester,
    ) async {
      final repo = FakeFinanceRepository(roles: ['PARENT']);
      await pumpFamily(
        tester,
        repo,
        roles: {TenantRole.parent},
        linked: {'p-ana'},
      );
      await tapKey(tester, 'hub-tab-dues');
      final page = (await tester.runAsync(() => repo.playerDues('p-ana')))!;
      final paid = page.items.firstWhere((d) => d.status == fin.DueStatus.PAID);
      final row = find.byKey(Key('family-due-${paid.id}'));
      expect(
        find.descendant(of: row, matching: find.text('Pagada')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.textContaining('Pagada el ')),
        findsOneWidget,
      );
      final open = page.items.where((d) => d.status == fin.DueStatus.OPEN);
      for (final d in open) {
        final r = find.byKey(Key('family-due-${d.id}'));
        expect(
          find.descendant(of: r, matching: find.text('Pendiente')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: r, matching: find.textContaining('Pagada el ')),
          findsNothing,
        );
      }
    });

    testWidgets('a player reads their own', (tester) async {
      final repo = FakeFinanceRepository(roles: ['PLAYER']);
      await pumpFamily(
        tester,
        repo,
        roles: {TenantRole.player},
        own: 'p-leo',
        location: '/me',
      );
      await tapKey(tester, 'hub-tab-dues');
      expect(repo.last['playerDues'], 'p-leo');
      expect(find.byType(ListRow), findsWidgets);
    });

    testWidgets('a player without dues gets an empty state', (tester) async {
      final repo = FakeFinanceRepository(roles: ['PARENT']);
      await pumpFamily(
        tester,
        repo,
        roles: {TenantRole.parent},
        linked: {'p-mia'},
      );
      await tapKey(tester, 'hub-tab-dues');
      expect(find.text('Aún no hay cuotas'), findsOneWidget);
    });

    testWidgets('the child switcher changes whose dues are shown', (
      tester,
    ) async {
      final repo = FakeFinanceRepository(roles: ['PARENT']);
      await pumpFamily(
        tester,
        repo,
        roles: {TenantRole.parent},
        linked: {'p-ana', 'p-mia'},
      );
      await tapKey(tester, 'hub-tab-dues');
      expect(repo.last['playerDues'], 'p-ana');
      await tapKey(tester, 'child-p-mia');
      expect(repo.last['playerDues'], 'p-mia');
    });

    testWidgets('a refusal (403) is worded', (tester) async {
      final repo = FakeFinanceRepository(roles: ['PARENT'])
        ..failOn['playerDues'] = const AppError(
          kind: AppErrorKind.forbidden,
          status: 403,
        );
      await pumpFamily(
        tester,
        repo,
        roles: {TenantRole.parent},
        linked: {'p-ana'},
      );
      await tapKey(tester, 'hub-tab-dues');
      expect(find.text('No tienes permiso para hacer esto.'), findsOneWidget);
    });

    testWidgets('a service that does not answer yet says so (501)', (
      tester,
    ) async {
      final repo = FakeFinanceRepository(roles: ['PARENT'])..notYetServed();
      await pumpFamily(
        tester,
        repo,
        roles: {TenantRole.parent},
        linked: {'p-ana'},
      );
      await tapKey(tester, 'hub-tab-dues');
      expect(find.byKey(const Key('finance-not-yet')), findsOneWidget);
      expect(find.text(notYet), findsOneWidget);
    });

    testWidgets('the rest of the hub is untouched, and the tab is added', (
      tester,
    ) async {
      final repo = FakeFinanceRepository(roles: ['PARENT']);
      await pumpFamily(
        tester,
        repo,
        roles: {TenantRole.parent},
        linked: {'p-ana'},
      );
      expect(find.byKey(const Key('hub-tab-training')), findsOneWidget);
      expect(find.byKey(const Key('hub-tab-plans')), findsOneWidget);
      expect(find.byKey(const Key('hub-tab-health')), findsOneWidget);
      expect(find.byKey(const Key('hub-tab-dues')), findsOneWidget);
      expect(repo.calls, isNot(contains('playerDues')));
    });
  });
}
