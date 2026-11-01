import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart';
import '../../support/fake_repos.dart';
import '../../support/pump_helpers.dart';

FakeCore coreWithApprovals() => FakeCore(
  approvals: FakeApprovalsRepository([
    approval('a1', note: 'Visto en el torneo'),
    approval('a2', playerName: 'Eva Mar', by: 'person-other', byName: 'Otto Otro'),
    approval('a3', status: api.ApprovalStatus.APPROVED, playerName: 'Old One'),
    approval('a4', action: api.ApprovalAction.WITHDRAW_PLAYER, playerName: 'Bye Bye'),
  ]),
);

void main() {
  guardTests();
  const path = '/players/requests';

  group('approvals inbox', () {
    testWidgets('loading', (tester) async {
      final core = coreWithApprovals()..approvals.hang = true;
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: path, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      final core = coreWithApprovals()..approvals.failWith = const AppError(kind: AppErrorKind.server);
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: path);
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: FakeCore(), location: path);
      expect(find.text('No hay solicitudes'), findsOneWidget);
    });

    testWidgets('admin: pending by default, "all" reveals decided ones', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: coreWithApprovals(), location: path);
      expect(find.text('Solicitudes'), findsOneWidget);
      expect(find.text('Luca Mora'), findsOneWidget);
      expect(find.text('Old One'), findsNothing);
      expect(find.text('Baja de jugador'), findsOneWidget);
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(find.text('Old One'), findsOneWidget);
    });

    testWidgets('admin approves with an optional note', (tester) async {
      final core = coreWithApprovals();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: path);
      await tapKey(tester, 'approve-a1');
      await tester.enterText(find.byKey(const Key('note-field')), 'ok');
      await tapKey(tester, 'dialog-confirm');
      expect(core.approvals.requests.first.status, api.ApprovalStatus.APPROVED);
      expect(core.approvals.lastNote, 'ok');
      expect(find.text('Solicitud aprobada'), findsOneWidget);
      expect(find.byKey(const Key('approve-a1')), findsNothing); // left the pending view
    });

    testWidgets('rejecting needs a note', (tester) async {
      final core = coreWithApprovals();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: path);
      await tapKey(tester, 'reject-a1');
      await tapKey(tester, 'dialog-confirm');
      expect(find.text('Campo obligatorio'), findsOneWidget);
      expect(core.approvals.calls, isNot(contains('reject')));
      await tester.enterText(find.byKey(const Key('note-field')), 'duplicado');
      await tapKey(tester, 'dialog-confirm');
      expect(core.approvals.requests.first.status, api.ApprovalStatus.REJECTED);
      expect(core.approvals.lastNote, 'duplicado');
    });

    testWidgets('coach: "my requests", no approve/reject, cancel only on own pending', (tester) async {
      final core = coreWithApprovals();
      await pumpAs(tester, roles: {TenantRole.coach}, core: core, location: path);
      expect(find.text('Mis solicitudes'), findsOneWidget);
      expect(find.byKey(const Key('approve-a1')), findsNothing);
      expect(find.byKey(const Key('reject-a1')), findsNothing);
      expect(find.byKey(const Key('cancel-a1')), findsOneWidget); // requested by person-me
      expect(find.byKey(const Key('cancel-a2')), findsNothing); // someone else's

      await tapKey(tester, 'cancel-a1');
      await tapKey(tester, 'dialog-confirm');
      expect(core.approvals.requests.first.status, api.ApprovalStatus.CANCELLED);
      expect(find.text('Solicitud cancelada'), findsOneWidget);
    });

    testWidgets('a conflict while approving shows a localized error and keeps the item', (tester) async {
      final core = coreWithApprovals();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: path);
      core.approvals.failWith = const AppError(kind: AppErrorKind.conflict, status: 409);
      await tapKey(tester, 'approve-a1');
      await tapKey(tester, 'dialog-confirm');
      expect(find.textContaining('Los datos han cambiado'), findsOneWidget);
      expect(find.byKey(const Key('approve-a1')), findsOneWidget);
    });
  });

  group('eligibility cases dashboard', () {
    FakeCore coreWithCases() => FakeCore(
      cases: FakeCasesRepository([
        eligibilityCase('c1', 'p1', 'Ana Ruiz', 't1', 'Mini A'),
        eligibilityCase('c2', 'p2', 'Leo Gil', 't2', 'Infantil B'),
      ]),
      players: FakePlayersRepository(
        [player('p1', 'Ana Ruiz'), player('p2', 'Leo Gil')],
        eligible: {
          'p1': [
            api.EligibleTeam(
              (b) => b
                ..team.replace(team('t1', 'Mini A'))
                ..eligibility.replace(check('t1', 'p1', api.EligibilityResult.ELIGIBLE)),
            ),
            api.EligibleTeam(
              (b) => b
                ..team.replace(team('t2', 'Infantil B', cat: u14))
                ..eligibility.replace(check('t2', 'p1', api.EligibilityResult.PLAY_UP, playUp: 1)),
            ),
            api.EligibleTeam(
              (b) => b
                ..team.replace(team('t3', 'Cadete C', cat: u14))
                ..eligibility.replace(check('t3', 'p1', api.EligibilityResult.INELIGIBLE,
                    reasons: [api.EligibilityReason.GENDER_POLICY])),
            ),
          ],
        },
      ),
    );

    testWidgets('loading / error / empty', (tester) async {
      final loading = coreWithCases()..cases.hang = true;
      await pumpAs(tester, roles: {TenantRole.admin}, core: loading, location: '/teams/cases', settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error', (tester) async {
      final core = coreWithCases()..cases.failWith = const AppError(kind: AppErrorKind.network);
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/teams/cases');
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: FakeCore(), location: '/teams/cases');
      expect(find.text('No hay casos abiertos'), findsOneWidget);
    });

    testWidgets('admin: reason, player, invalidated team; reassign offers only eligible teams then resolves', (tester) async {
      final core = coreWithCases();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/teams/cases');
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('Equipo invalidado: Mini A'), findsOneWidget);
      expect(find.text('Es demasiado mayor para esta categoría'), findsWidgets);

      await tapKey(tester, 'reassign-c1');
      expect(find.byKey(const Key('reassign-to-t2')), findsOneWidget);
      expect(find.text('Juega en categoría superior (+1)'), findsOneWidget);
      expect(find.byKey(const Key('reassign-to-t1')), findsNothing); // the invalidated team itself
      expect(find.byKey(const Key('reassign-to-t3')), findsNothing); // ineligible

      await tapKey(tester, 'reassign-to-t2');
      expect(core.cases.resolvedId, 'c1');
      expect(core.cases.resolution, api.EligibilityCaseResolution.REASSIGNED);
      expect(core.cases.target, 't2');
      expect(find.text('Caso resuelto'), findsOneWidget);
      expect(find.byKey(const Key('case-c1')), findsNothing);
    });

    testWidgets('remove from team and dismiss resolve with the matching resolution', (tester) async {
      final core = coreWithCases();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/teams/cases');
      await tapKey(tester, 'remove-c1');
      expect(core.cases.resolution, api.EligibilityCaseResolution.REMOVED_FROM_TEAM);
      await tapKey(tester, 'dismiss-c2');
      expect(core.cases.resolution, api.EligibilityCaseResolution.DISMISSED);
    });

    testWidgets('coach resolves only cases of own teams; assistant none', (tester) async {
      final core = coreWithCases();
      await pumpAs(tester, roles: {TenantRole.coach}, core: core, location: '/teams/cases', staffTeamIds: {'t1'});
      expect(find.byKey(const Key('reassign-c1')), findsOneWidget);
      expect(find.byKey(const Key('reassign-c2')), findsNothing);
    });

    testWidgets('assistant sees the cases but has no actions', (tester) async {
      await pumpAs(tester, roles: {TenantRole.assistantCoach}, core: coreWithCases(), location: '/teams/cases', staffTeamIds: {'t1'});
      expect(find.byKey(const Key('case-c1')), findsOneWidget);
      expect(find.byKey(const Key('reassign-c1')), findsNothing);
    });

    testWidgets('no eligible team: the dialog says so', (tester) async {
      final core = coreWithCases();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '/teams/cases');
      await tapKey(tester, 'reassign-c2'); // p2 has no eligible teams
      expect(find.byKey(const Key('no-eligible-teams')), findsOneWidget);
    });
  });
}

void guardTests() {
  testWidgets('assistant opening the inbox or the new-player form by URL gets "not allowed"', (tester) async {
    final h = await pumpAs(tester, roles: {TenantRole.assistantCoach}, core: FakeCore(), location: '/players/requests');
    expect(find.byKey(const Key('forbidden')), findsOneWidget);
    await h.go(tester, '/players/new');
    expect(find.byKey(const Key('forbidden')), findsOneWidget);
    expect(find.byKey(const Key('player-submit')), findsNothing);
  });
}
