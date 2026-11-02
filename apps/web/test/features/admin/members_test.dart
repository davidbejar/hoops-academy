import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../../support/core_fixtures.dart';
import '../../support/fake_repos.dart';
import '../../support/pump_helpers.dart';

FakeCore coreWithMembers() => FakeCore(
  members: FakeMembersRepository([
    member('m1', 'Casey Coach', roles: {api.TenantRole.COACH}),
    member('m2', 'Pat Parent', roles: {api.TenantRole.PARENT}),
    member('m3', 'Old Admin', roles: {api.TenantRole.ADMIN}, active: false),
  ]),
  players: FakePlayersRepository([player('p1', 'Ana Ruiz'), player('p2', 'Leo Gil')]),
);

void main() {
  const path = '/admin/members';

  group('members list', () {
    testWidgets('loading', (tester) async {
      final core = coreWithMembers()..members.hang = true;
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: path, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      final core = coreWithMembers()..members.failWith = const AppError(kind: AppErrorKind.server);
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: path);
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
      core.members.failWith = null;
      await tester.tap(find.byKey(const Key('retry-button')));
      await tester.pumpAndSettle();
      expect(find.text('Casey Coach'), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: FakeCore(), location: path);
      expect(find.text('Aún no hay miembros'), findsOneWidget);
    });

    testWidgets('populated: roles, inactive marker, search by name', (tester) async {
      final core = coreWithMembers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: path);
      expect(find.text('Casey Coach'), findsOneWidget);
      expect(find.textContaining('Entrenador'), findsWidgets);
      expect(find.text('Inactivo'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('member-search')), 'pat');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(core.members.lastQuery, 'pat');
      expect(find.text('Pat Parent'), findsOneWidget);
      expect(find.text('Casey Coach'), findsNothing);
    });

    testWidgets('a coach cannot open the members admin page (guard sends them home)', (tester) async {
      await pumpAs(tester, roles: {TenantRole.coach}, core: coreWithMembers(), location: path);
      expect(find.byKey(const Key('member-invite')), findsNothing);
      expect(find.byKey(const Key('season-select')), findsOneWidget); // Teams
    });
  });

  group('invite', () {
    testWidgets('validates names, email and roles', (tester) async {
      final core = coreWithMembers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: path);
      await tapKey(tester, 'member-invite');
      await enter(tester, 'invite-email', 'nope');
      await tapKey(tester, 'form-submit');
      expect(find.text('Campo obligatorio'), findsNWidgets(2));
      expect(find.text('Introduce un correo válido'), findsOneWidget);
      expect(find.byKey(const Key('roles-error')), findsOneWidget);
      expect(core.members.invited, isNull);
    });

    testWidgets('sends the invitation with the chosen roles and refreshes the list', (tester) async {
      final core = coreWithMembers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: path);
      await tapKey(tester, 'member-invite');
      await enter(tester, 'invite-given', 'Nora');
      await enter(tester, 'invite-family', 'Vega');
      await enter(tester, 'invite-email', 'nora@hoops-academy.com');
      await tapKey(tester, 'role-COACH');
      await tapKey(tester, 'role-ASSISTANT_COACH');
      await tapKey(tester, 'form-submit');

      final sent = core.members.invited!;
      expect(sent.email, 'nora@hoops-academy.com');
      expect(sent.roles.toSet(), {api.TenantRole.COACH, api.TenantRole.ASSISTANT_COACH});
      expect(sent.sendInvitation, isTrue);
      expect(find.text('Invitación enviada'), findsOneWidget);
      expect(find.text('Nora Vega'), findsOneWidget);
      expect(find.text('Invitación pendiente'), findsOneWidget);
    });

    testWidgets('a server conflict keeps the dialog open with a localized message', (tester) async {
      final core = coreWithMembers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: path);
      core.members.failWith = const AppError(kind: AppErrorKind.conflict, status: 409);
      await tapKey(tester, 'member-invite');
      await enter(tester, 'invite-given', 'Nora');
      await enter(tester, 'invite-family', 'Vega');
      await enter(tester, 'invite-email', 'nora@hoops-academy.com');
      await tapKey(tester, 'role-COACH');
      await tapKey(tester, 'form-submit');
      expect(find.textContaining('Los datos han cambiado'), findsOneWidget);
      expect(find.byKey(const Key('invite-given')), findsOneWidget);
    });
  });

  group('member detail', () {
    testWidgets('edit roles', (tester) async {
      final core = coreWithMembers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '$path/m1');
      await tapKey(tester, 'role-ASSISTANT_COACH');
      await tapKey(tester, 'member-save-roles');
      expect(core.members.members.first.roles.toSet(), {api.TenantRole.COACH, api.TenantRole.ASSISTANT_COACH});
    });

    testWidgets('deactivate asks for confirmation', (tester) async {
      final core = coreWithMembers();
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '$path/m1');
      await tapKey(tester, 'member-deactivate');
      expect(find.textContaining('¿Desactivar a Casey Coach?'), findsOneWidget);
      await tapKey(tester, 'dialog-confirm');
      expect(core.members.members.first.active, isFalse);
    });

    testWidgets('guardian links: parent sees links, can add and remove', (tester) async {
      final core = coreWithMembers();
      core.members.links.add(api.GuardianLink(
        (b) => b
          ..id = 'link-a'
          ..guardian.replace(personRef('m2', 'Pat Parent'))
          ..player.replace(playerRef('p1', 'Ana Ruiz'))
          ..createdAt = DateTime.utc(2026, 1, 1),
      ));
      await pumpAs(tester, roles: {TenantRole.admin}, core: core, location: '$path/m2');
      expect(find.text('Ana Ruiz'), findsOneWidget);

      await tapKey(tester, 'guardian-add');
      await tapKey(tester, 'pick-player-p2');
      expect(core.members.calls, contains('addLink'));
      expect(find.text('Player p2'), findsOneWidget);

      await tester.tap(find.byTooltip('Quitar').first);
      await tester.pumpAndSettle();
      await tapKey(tester, 'dialog-confirm');
      expect(core.members.calls, contains('removeLink'));
    });

    testWidgets('non-parents show why links are unavailable', (tester) async {
      await pumpAs(tester, roles: {TenantRole.admin}, core: coreWithMembers(), location: '$path/m1');
      expect(find.textContaining('rol Familia'), findsOneWidget);
    });
  });
}
