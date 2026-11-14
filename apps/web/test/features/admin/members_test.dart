import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
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
    member(
      'm4',
      'Nina Nueva',
      roles: {api.TenantRole.COACH},
      invitation: api.InvitationStatus.PENDING,
    ),
  ]),
  players: FakePlayersRepository([
    player('p1', 'Ana Ruiz'),
    player('p2', 'Leo Gil'),
  ]),
);

DioException _problem(int status, String code) {
  final request = RequestOptions(path: '/members');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: request,
      statusCode: status,
      data: {
        'status': status,
        'code': code,
        'detail': 'English server detail that must never be shown',
      },
    ),
  );
}

void main() {
  const path = '/admin/members';

  group('members list', () {
    testWidgets('loading', (tester) async {
      final core = coreWithMembers()..members.hang = true;
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: path,
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      final core = coreWithMembers()
        ..members.failWith = const AppError(kind: AppErrorKind.server);
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: path,
      );
      expect(find.byKey(const Key('retry-button')), findsOneWidget);
      core.members.failWith = null;
      await tester.tap(find.byKey(const Key('retry-button')));
      await tester.pumpAndSettle();
      expect(find.text('Casey Coach'), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: FakeCore(),
        location: path,
      );
      expect(find.text('Aún no hay miembros'), findsOneWidget);
    });

    testWidgets('populated: roles, inactive marker, search by name', (
      tester,
    ) async {
      final core = coreWithMembers();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: path,
      );
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

    testWidgets(
      'a coach cannot open the members admin page (guard sends them home)',
      (tester) async {
        await pumpAs(
          tester,
          roles: {TenantRole.coach},
          core: coreWithMembers(),
          location: path,
        );
        expect(find.byKey(const Key('member-invite')), findsNothing);
        expect(find.byKey(const Key('season-select')), findsOneWidget); // Teams
      },
    );
  });

  group('invite', () {
    testWidgets('validates names, email and roles', (tester) async {
      final core = coreWithMembers();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: path,
      );
      await tapKey(tester, 'member-invite');
      await enter(tester, 'invite-email', 'nope');
      await tapKey(tester, 'form-submit');
      expect(find.text('Campo obligatorio'), findsNWidgets(2));
      expect(find.text('Introduce un correo válido'), findsOneWidget);
      expect(find.byKey(const Key('roles-error')), findsOneWidget);
      expect(core.members.invited, isNull);
    });

    testWidgets(
      'sends the invitation with the chosen roles and refreshes the list',
      (tester) async {
        final core = coreWithMembers();
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: core,
          location: path,
          size: const Size(360, 1400),
        );
        await tapKey(tester, 'member-invite');
        await enter(tester, 'invite-given', 'Nora');
        await enter(tester, 'invite-family', 'Vega');
        await enter(tester, 'invite-email', 'nora@hoops-academy.com');
        await tapKey(tester, 'role-COACH');
        await tapKey(tester, 'role-ASSISTANT_COACH');
        await tapKey(tester, 'form-submit');

        final sent = core.members.invited!;
        expect(sent.email, 'nora@hoops-academy.com');
        expect(sent.roles.toSet(), {
          api.TenantRole.COACH,
          api.TenantRole.ASSISTANT_COACH,
        });
        expect(sent.sendInvitation, isTrue);
        // The new login's temporary password is shown once (no e-mail is sent); the list never holds it.
        expect(find.byKey(const Key('temp-password-dialog')), findsOneWidget);
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const Key('temp-password-value')),
              )
              .data,
          core.members.newLoginPassword,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('temp-password-dialog')),
            matching: find.textContaining('nora@hoops-academy.com'),
          ),
          findsOneWidget,
        );
        await tapKey(tester, 'temp-password-done');
        expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
        expect(find.text(core.members.newLoginPassword!), findsNothing);
        expect(find.text('Invitación enviada'), findsNothing);
        expect(find.text('Nora Vega'), findsOneWidget);
        expect(
          find.text('Invitación pendiente'),
          findsNWidgets(2),
        ); // Nina (seeded) and Nora
      },
    );

    testWidgets(
      'a person who already has a login gets no dialog: they use their current password',
      (tester) async {
        final core = coreWithMembers();
        core.members.newLoginPassword = null;
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: core,
          location: path,
          size: const Size(360, 1400),
        );
        await tapKey(tester, 'member-invite');
        await enter(tester, 'invite-given', 'Nora');
        await enter(tester, 'invite-family', 'Vega');
        await enter(tester, 'invite-email', 'nora@hoops-academy.com');
        await tapKey(tester, 'role-COACH');
        await tapKey(tester, 'form-submit');
        expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
        expect(find.textContaining('contraseña actual'), findsOneWidget);
        expect(find.text('Nora Vega'), findsOneWidget);
      },
    );

    testWidgets('the invite dialog promises no e-mail', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: coreWithMembers(),
        location: path,
      );
      await tapKey(tester, 'member-invite');
      expect(find.textContaining('contraseña temporal'), findsOneWidget);
      expect(find.textContaining('correo con'), findsNothing);
    });

    testWidgets(
      'a server conflict keeps the dialog open with a localized message',
      (tester) async {
        final core = coreWithMembers();
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: core,
          location: path,
        );
        core.members.failWith = const AppError(
          kind: AppErrorKind.conflict,
          status: 409,
        );
        await tapKey(tester, 'member-invite');
        await enter(tester, 'invite-given', 'Nora');
        await enter(tester, 'invite-family', 'Vega');
        await enter(tester, 'invite-email', 'nora@hoops-academy.com');
        await tapKey(tester, 'role-COACH');
        await tapKey(tester, 'form-submit');
        expect(find.textContaining('Los datos han cambiado'), findsOneWidget);
        expect(find.byKey(const Key('invite-given')), findsOneWidget);
      },
    );
  });

  group('member detail', () {
    testWidgets('edit roles', (tester) async {
      final core = coreWithMembers();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: '$path/m1',
      );
      await tapKey(tester, 'role-ASSISTANT_COACH');
      await tapKey(tester, 'member-save-roles');
      expect(core.members.members.first.roles.toSet(), {
        api.TenantRole.COACH,
        api.TenantRole.ASSISTANT_COACH,
      });
    });

    testWidgets(
      'a guardian without a login gets a first temporary password from the '
      'member page',
      (tester) async {
        final core = coreWithMembers();
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: core,
          location: '$path/m2',
        );
        expect(find.byKey(const Key('member-issue-password')), findsOneWidget);
        await tapKey(tester, 'member-issue-password');
        expect(core.members.reissuedFor, ['m2']);
        expect(find.byKey(const Key('temp-password-dialog')), findsOneWidget);
      },
    );

    testWidgets('a guardian who already signs in gets no password action', (
      tester,
    ) async {
      final core = FakeCore(
        members: FakeMembersRepository([
          member(
            'm9',
            'Gus Guardian',
            roles: {api.TenantRole.PARENT},
            userId: 'u-9',
          ),
        ]),
      );
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: '$path/m9',
      );
      expect(find.byKey(const Key('member-issue-password')), findsNothing);
    });

    testWidgets('re-issue is offered for a pending active member only', (
      tester,
    ) async {
      final core = coreWithMembers();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: '$path/m1',
      );
      expect(find.byKey(const Key('member-issue-password')), findsNothing);
    });

    testWidgets(
      're-issue: a new temporary password is shown once for a pending member',
      (tester) async {
        final core = coreWithMembers();
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: core,
          location: '$path/m4',
        );
        expect(find.text('Invitación pendiente'), findsOneWidget);
        await tapKey(tester, 'member-issue-password');
        expect(core.members.reissuedFor, ['m4']);
        expect(find.byKey(const Key('temp-password-dialog')), findsOneWidget);
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const Key('temp-password-value')),
              )
              .data,
          'Reissued-1',
        );
        expect(find.textContaining('Nina Nueva'), findsWidgets);
        expect(
          find.descendant(
            of: find.byKey(const Key('temp-password-dialog')),
            matching: find.textContaining('nina@hoops-academy.com'),
          ),
          findsOneWidget,
        );
        await tapKey(tester, 'temp-password-done');
        expect(find.text('Reissued-1'), findsNothing);
      },
    );

    testWidgets(
      'an expired temporary password is labelled in the list and next to the re-issue button',
      (tester) async {
        final core = FakeCore(
          members: FakeMembersRepository([
            member(
              'm6',
              'Eva Expirada',
              invitation: api.InvitationStatus.PENDING,
              temporaryPassword: api.TemporaryPasswordStatus.EXPIRED,
            ),
            member(
              'm7',
              'Ivo Vigente',
              invitation: api.InvitationStatus.PENDING,
              temporaryPassword: api.TemporaryPasswordStatus.ACTIVE,
            ),
          ]),
        );
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: core,
          location: path,
        );
        expect(
          find.byKey(const Key('member-password-expired-m6')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('member-password-expired-m7')),
          findsNothing,
        );
        expect(find.text('Contraseña temporal caducada'), findsOneWidget);

        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: core,
          location: '$path/m6',
        );
        expect(
          find.byKey(const Key('member-password-expired')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('member-issue-password')), findsOneWidget);
        await tapKey(tester, 'member-issue-password');
        await tapKey(tester, 'temp-password-done');
        expect(core.members.reissuedFor, ['m6']);
        expect(find.byKey(const Key('member-password-expired')), findsNothing);
      },
    );

    testWidgets(
      'a pending member whose temporary password is still valid shows no expiry label',
      (tester) async {
        final core = FakeCore(
          members: FakeMembersRepository([
            member(
              'm7',
              'Ivo Vigente',
              invitation: api.InvitationStatus.PENDING,
              temporaryPassword: api.TemporaryPasswordStatus.ACTIVE,
            ),
          ]),
        );
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: core,
          location: '$path/m7',
        );
        expect(find.byKey(const Key('member-password-expired')), findsNothing);
        expect(find.text('Invitación pendiente'), findsOneWidget);
      },
    );

    testWidgets('re-issue is not offered for an inactive pending member', (
      tester,
    ) async {
      final core = FakeCore(
        members: FakeMembersRepository([
          member(
            'm5',
            'Ines Inactiva',
            active: false,
            invitation: api.InvitationStatus.PENDING,
          ),
        ]),
      );
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: '$path/m5',
      );
      expect(find.byKey(const Key('member-issue-password')), findsNothing);
    });

    testWidgets(
      're-issue: 409 INVITATION_NOT_PENDING is reported in plain words, no dialog',
      (tester) async {
        final core = coreWithMembers();
        core.members.issueFails = _problem(409, 'INVITATION_NOT_PENDING');
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: core,
          location: '$path/m4',
        );
        await tapKey(tester, 'member-issue-password');
        expect(
          find.text(
            'Esta persona ya entró o la invitación ya no está pendiente',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('English server detail'), findsNothing);
        expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
      },
    );

    testWidgets(
      're-issue: 409 LOGIN_SHARED says only the platform administration can do it',
      (tester) async {
        final core = coreWithMembers();
        core.members.issueFails = _problem(409, 'LOGIN_SHARED');
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: core,
          location: '$path/m4',
        );
        await tapKey(tester, 'member-issue-password');
        expect(
          find.textContaining('se usa también en otra academia'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
      },
    );

    testWidgets(
      're-issue: a generic failure uses the localized per-kind message',
      (tester) async {
        final core = coreWithMembers();
        core.members.issueFails = const AppError(kind: AppErrorKind.server);
        await pumpAs(
          tester,
          roles: {TenantRole.admin},
          core: core,
          location: '$path/m4',
        );
        await tapKey(tester, 'member-issue-password');
        expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets('deactivate asks for confirmation', (tester) async {
      final core = coreWithMembers();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: '$path/m1',
      );
      await tapKeyScrolling(tester, 'member-deactivate');
      expect(find.textContaining('¿Desactivar a Casey Coach?'), findsOneWidget);
      await tapKey(tester, 'dialog-confirm');
      expect(core.members.members.first.active, isFalse);
    });

    testWidgets('guardian links: parent sees links, can add and remove', (
      tester,
    ) async {
      final core = coreWithMembers();
      core.members.links.add(
        api.GuardianLink(
          (b) => b
            ..id = 'link-a'
            ..guardian.replace(personRef('m2', 'Pat Parent'))
            ..player.replace(playerRef('p1', 'Ana Ruiz'))
            ..createdAt = DateTime.utc(2026, 1, 1),
        ),
      );
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: '$path/m2',
        size: const Size(360, 1100),
      );
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
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: coreWithMembers(),
        location: '$path/m1',
      );
      expect(find.textContaining('rol Familia'), findsOneWidget);
    });
  });

  group('member personal data', () {
    Future<FakeCore> openEdit(WidgetTester tester) async {
      final core = coreWithMembers();
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: '$path/m1',
      );
      await tapKey(tester, 'member-edit');
      return core;
    }

    String text(WidgetTester tester, String key) =>
        tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;

    testWidgets('opens with the current values', (tester) async {
      await openEdit(tester);
      expect(text(tester, 'member-edit-given'), 'Casey');
      expect(text(tester, 'member-edit-family'), 'Coach');
      expect(text(tester, 'member-edit-email'), 'casey@hoops-academy.com');
      expect(text(tester, 'member-edit-phone'), '');
    });

    testWidgets('saves a phone and a gender; the rest is sent as it was', (
      tester,
    ) async {
      final core = await openEdit(tester);
      await tester.enterText(
        find.byKey(const Key('member-edit-phone')),
        '+34 600 111 222',
      );
      await tester.tap(find.byKey(const Key('member-edit-gender')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Femenino').last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'form-submit');

      final u = core.members.updates.single;
      expect(u.personId, 'm1');
      expect(u.givenName, 'Casey');
      expect(u.email, 'casey@hoops-academy.com');
      expect(u.phone, '+34 600 111 222');
      expect(u.gender, api.Gender.FEMALE);
      expect(u.birthDate, isNull);
      expect(find.byKey(const Key('member-edit-phone')), findsNothing);
    });

    testWidgets('emptied optional fields are sent as null (clear)', (
      tester,
    ) async {
      final core = await openEdit(tester);
      await tester.enterText(find.byKey(const Key('member-edit-email')), ' ');
      await tapKey(tester, 'form-submit');
      final u = core.members.updates.single;
      expect(u.email, isNull);
      expect(u.phone, isNull);
    });

    testWidgets('422 LOGIN_REQUIRES_EMAIL keeps the dialog open with a '
        'localized message', (tester) async {
      final core = await openEdit(tester);
      core.members.failWith = _problem(422, 'LOGIN_REQUIRES_EMAIL');
      await tester.enterText(find.byKey(const Key('member-edit-email')), '');
      await tapKey(tester, 'form-submit');
      expect(find.byKey(const Key('member-edit-email')), findsOneWidget);
      expect(find.textContaining('correo'), findsWidgets);
      expect(find.textContaining('English server detail'), findsNothing);
    });

    testWidgets('409 EMAIL_TAKEN keeps the dialog open', (tester) async {
      final core = await openEdit(tester);
      core.members.failWith = _problem(409, 'EMAIL_TAKEN');
      await tapKey(tester, 'form-submit');
      expect(find.byKey(const Key('member-edit-email')), findsOneWidget);
      expect(find.textContaining('English server detail'), findsNothing);
    });

    testWidgets('clearing the e-mail of a member with a login is blocked '
        'before the request', (tester) async {
      final core = FakeCore(
        members: FakeMembersRepository([
          member('m8', 'Lia Login', userId: 'u-8'),
        ]),
      );
      await pumpAs(
        tester,
        roles: {TenantRole.admin},
        core: core,
        location: '$path/m8',
      );
      await tapKey(tester, 'member-edit');
      await tester.enterText(find.byKey(const Key('member-edit-email')), '');
      await tapKey(tester, 'form-submit');
      expect(core.members.updates, isEmpty);
      expect(find.byKey(const Key('member-edit-email')), findsOneWidget);
      expect(find.textContaining('correo'), findsWidgets);
    });

    testWidgets('a member without a login may still lose the e-mail', (
      tester,
    ) async {
      final core = await openEdit(tester);
      await tester.enterText(find.byKey(const Key('member-edit-email')), '');
      await tapKey(tester, 'form-submit');
      expect(core.members.updates.single.email, isNull);
    });

    testWidgets('a coach has no member screen to edit from', (tester) async {
      await pumpAs(
        tester,
        roles: {TenantRole.coach},
        core: coreWithMembers(),
        location: '$path/m1',
      );
      expect(find.byKey(const Key('member-edit')), findsNothing);
    });
  });
}

/// The detail page is a lazy list of cards: scroll the target into the tree first.
Future<void> tapKeyScrolling(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(
    find.byKey(Key(key)),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tapKey(tester, key);
}
