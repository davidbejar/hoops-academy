import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/ui/kit.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;
import 'package:material_ui/material_ui.dart';

import '../../support/core_fixtures.dart';
import '../../support/finance_seed.dart';
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
      FinanceData finance, {
      Set<TenantRole> roles = const {TenantRole.coach},
      Set<String> staffTeamIds = const {'team-mini-a'},
      api.StaffRole role = api.StaffRole.COACH,
      bool settle = true,
      bool roster = true,
    }) => pumpFinance(
      tester,
      finance: finance,
      roles: roles,
      location: path,
      staffTeamIds: staffTeamIds,
      settle: settle,
      core: financeCore(
        staff: {
          'team-mini-a': [staff('person-me', role)],
        },
        roster: roster,
      ),
    );

    bool askedStatus(FinanceData finance) =>
        finance.requests(FinanceData.teamStatusPath).isNotEmpty;

    testWidgets('a marker per player, no amounts', (tester) async {
      final finance = FinanceData();
      await pumpCoach(tester, finance);
      final status = finance.answered<fin.TeamDueStatus>(
        FinanceData.teamStatusPath,
      );
      expect(finance.lastId(FinanceData.teamStatusPath), 'team-mini-a');
      expect(status.players, hasLength(miniAPlayers.length));
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
      final finance = FinanceData();
      await pumpCoach(
        tester,
        finance,
        roles: {TenantRole.assistantCoach},
        role: api.StaffRole.ASSISTANT_COACH,
      );
      expect(find.byKey(const Key('due-status')), findsNothing);
      expect(askedStatus(finance), isFalse);
    });

    testWidgets('a COACH who is only the assistant of this team does not', (
      tester,
    ) async {
      final finance = FinanceData();
      await pumpCoach(tester, finance, role: api.StaffRole.ASSISTANT_COACH);
      expect(find.byKey(const Key('due-status')), findsNothing);
      expect(askedStatus(finance), isFalse);
    });

    testWidgets('a COACH of another team does not', (tester) async {
      final finance = FinanceData();
      await pumpCoach(tester, finance, staffTeamIds: {'team-mini-b'});
      expect(find.byKey(const Key('due-status')), findsNothing);
      expect(askedStatus(finance), isFalse);
    });

    testWidgets('a parent, a player and a plain admin do not', (tester) async {
      for (final role in [
        TenantRole.parent,
        TenantRole.player,
        TenantRole.admin,
      ]) {
        final finance = FinanceData();
        await pumpCoach(tester, finance, roles: {role}, staffTeamIds: const {});
        expect(
          find.byKey(const Key('due-status')),
          findsNothing,
          reason: '$role',
        );
        expect(askedStatus(finance), isFalse, reason: '$role');
      }
    });

    testWidgets('a team without players says so', (tester) async {
      await pumpCoach(
        tester,
        FinanceData.empty(currency: 'EUR'),
        roster: false,
      );
      expect(find.text('El equipo no tiene jugadores'), findsOneWidget);
    });

    testWidgets('loading', (tester) async {
      final finance = FinanceData()..hang();
      await pumpCoach(tester, finance, settle: false);
      await tester.pump();
      expect(find.byKey(const Key('due-status')), findsOneWidget);
    });

    testWidgets('a failure of this part leaves the team screen intact', (
      tester,
    ) async {
      final finance = FinanceData()
        ..fail(path: FinanceData.teamStatusPath, status: 500);
      await pumpCoach(tester, finance);
      expect(find.byKey(const Key('due-status')), findsOneWidget);
      expect(find.byKey(const Key('due-status-retry')), findsOneWidget);
      expect(find.byKey(const Key('roster-assign')), findsOneWidget);
    });

    testWidgets('a service that does not answer yet says so (501)', (
      tester,
    ) async {
      final finance = FinanceData()..notYetServed();
      await pumpCoach(tester, finance);
      expect(find.text(notYet), findsOneWidget);
    });

    testWidgets('a refusal (403) hides the part instead of failing', (
      tester,
    ) async {
      // The app shows the part only to the team's COACH, so the service's
      // refusal (a coach removed meanwhile) is injected.
      final finance = FinanceData()
        ..fail(path: FinanceData.teamStatusPath, status: 403);
      await pumpCoach(tester, finance);
      expect(find.byKey(const Key('due-status')), findsNothing);
      expect(find.byKey(const Key('due-status-retry')), findsNothing);
    });
  });

  group("the family's dues in the player's hub", () {
    /// The dues the mock answered the hub with (one page: three at most).
    List<fin.PlayerDue> playerDues(FinanceData finance) => finance
        .answered<fin.PlayerDuePage>(FinanceData.playerDuesPath)
        .items
        .toList();

    Future<void> pumpFamily(
      WidgetTester tester,
      FinanceData finance, {
      required Set<TenantRole> roles,
      Set<String> linked = const {},
      String? own,
      String location = '/my-players',
    }) => pumpFinance(
      tester,
      finance: finance,
      roles: roles,
      location: location,
      linkedPlayerIds: linked,
      ownPlayerId: own,
    );

    testWidgets('a parent reads the dues of the linked player', (tester) async {
      final finance = FinanceData();
      await pumpFamily(
        tester,
        finance,
        roles: {TenantRole.parent},
        linked: {'p-ana'},
      );
      await tapKey(tester, 'hub-tab-dues');
      expect(finance.lastId(FinanceData.playerDuesPath), 'p-ana');
      final dues = playerDues(finance);
      expect(dues, hasLength(3));
      for (final d in dues) {
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
      final finance = FinanceData();
      await pumpFamily(
        tester,
        finance,
        roles: {TenantRole.parent},
        linked: {'p-ana'},
      );
      await tapKey(tester, 'hub-tab-dues');
      final dues = playerDues(finance);
      final paid = dues.firstWhere((d) => d.status == fin.DueStatus.PAID);
      final row = find.byKey(Key('family-due-${paid.id}'));
      expect(
        find.descendant(of: row, matching: find.text('Pagada')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.textContaining('Pagada el ')),
        findsOneWidget,
      );
      final open = dues.where((d) => d.status == fin.DueStatus.OPEN);
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
      final finance = FinanceData();
      await pumpFamily(
        tester,
        finance,
        roles: {TenantRole.player},
        own: 'p-leo',
        location: '/me',
      );
      await tapKey(tester, 'hub-tab-dues');
      expect(finance.lastId(FinanceData.playerDuesPath), 'p-leo');
      expect(find.byType(ListRow), findsWidgets);
    });

    testWidgets('a player without dues gets an empty state', (tester) async {
      // No plan charges Mini B: its player has no dues.
      final finance = FinanceData();
      await pumpFamily(
        tester,
        finance,
        roles: {TenantRole.parent},
        linked: {'p-mia'},
      );
      await tapKey(tester, 'hub-tab-dues');
      expect(finance.lastId(FinanceData.playerDuesPath), 'p-mia');
      expect(find.text('Aún no hay cuotas'), findsOneWidget);
    });

    testWidgets('the child switcher changes whose dues are shown', (
      tester,
    ) async {
      final finance = FinanceData();
      await pumpFamily(
        tester,
        finance,
        roles: {TenantRole.parent},
        linked: {'p-ana', 'p-mia'},
      );
      await tapKey(tester, 'hub-tab-dues');
      expect(finance.lastId(FinanceData.playerDuesPath), 'p-ana');
      // Another child is another hub: it opens on its first tab.
      await tapKey(tester, 'child-p-mia');
      await tapKey(tester, 'hub-tab-dues');
      expect(finance.lastId(FinanceData.playerDuesPath), 'p-mia');
    });

    testWidgets('a refusal (403) is worded', (tester) async {
      // The app asks only for a linked player, so the service's refusal (a
      // link removed meanwhile) is injected.
      final finance = FinanceData()
        ..fail(path: FinanceData.playerDuesPath, status: 403);
      await pumpFamily(
        tester,
        finance,
        roles: {TenantRole.parent},
        linked: {'p-ana'},
      );
      await tapKey(tester, 'hub-tab-dues');
      expect(find.text('No tienes permiso para hacer esto.'), findsOneWidget);
    });

    testWidgets('a service that does not answer yet says so (501)', (
      tester,
    ) async {
      final finance = FinanceData()..notYetServed();
      await pumpFamily(
        tester,
        finance,
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
      final finance = FinanceData();
      await pumpFamily(
        tester,
        finance,
        roles: {TenantRole.parent},
        linked: {'p-ana'},
      );
      expect(find.byKey(const Key('hub-tab-training')), findsOneWidget);
      expect(find.byKey(const Key('hub-tab-plans')), findsOneWidget);
      expect(find.byKey(const Key('hub-tab-health')), findsOneWidget);
      expect(find.byKey(const Key('hub-tab-dues')), findsOneWidget);
      expect(finance.requests(FinanceData.playerDuesPath), isEmpty);
    });
  });
}
