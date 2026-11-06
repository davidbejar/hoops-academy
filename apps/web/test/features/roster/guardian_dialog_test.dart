import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/roster/data/guardians_repository.dart';

import '../../support/core_fixtures.dart';
import '../../support/fake_repos.dart';
import '../../support/pump_helpers.dart';
import 'players_test.dart' show coreWithPlayers;

/// What `POST /api/core/guardians` and the guardian's first login return (WP58, core 2.8.0).
class FakeGuardiansRepository implements GuardiansRepository {
  FakeGuardiansRepository(this.members);
  final FakeMembersRepository members;
  final List<Map<String, String?>> created = [];
  final List<String> issuedFor = [];

  /// The password of a login the server creates; null: the e-mail already signs in elsewhere.
  String? newLoginPassword = 'Guardian-temp-1';
  Object? failWith;

  @override
  Future<api.GuardianLinkWithPassword> create({
    required String playerId,
    required String givenName,
    required String familyName,
    String? email,
  }) async {
    if (failWith != null) throw failWith!;
    created.add({
      'playerId': playerId,
      'givenName': givenName,
      'familyName': familyName,
      'email': email,
    });
    final link = api.GuardianLink(
      (b) => b
        ..id = 'l-new-${created.length}'
        ..guardian.replace(
          personRef('g${created.length}', '$givenName $familyName'),
        )
        ..player.replace(playerRef(playerId, 'Ana Ruiz'))
        ..createdAt = DateTime.utc(2026, 11, 6),
    );
    members.links.add(link);
    return api.GuardianLinkWithPassword(
      (b) => b
        ..id = link.id
        ..guardian.replace(link.guardian)
        ..player.replace(link.player)
        ..createdAt = link.createdAt
        ..temporaryPassword = email == null ? null : newLoginPassword,
    );
  }

  @override
  Future<api.MemberWithPassword> issueTemporaryPassword(String personId) async {
    issuedFor.add(personId);
    final m = members.members.firstWhere((m) => m.personId == personId);
    final linked = m.rebuild(
      (b) => b
        ..userId = 'u-$personId'
        ..invitationStatus = api.InvitationStatus.PENDING
        ..temporaryPasswordStatus = api.TemporaryPasswordStatus.ACTIVE,
    );
    members.members[members.members.indexOf(m)] = linked;
    return FakeMembersRepository.withPassword(linked, 'First-login-1');
  }
}

DioException emailTaken() => DioException(
  requestOptions: RequestOptions(path: '/guardians'),
  type: DioExceptionType.badResponse,
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/guardians'),
    statusCode: 409,
    data: {'status': 409, 'code': 'EMAIL_TAKEN', 'title': 'Conflict'},
  ),
);

void main() {
  late FakeCore core;
  late FakeGuardiansRepository guardians;

  setUp(() {
    core = coreWithPlayers();
    guardians = FakeGuardiansRepository(core.members);
  });

  Future<void> openPlayer(WidgetTester tester, {Set<TenantRole>? roles}) =>
      pumpAs(
        tester,
        roles: roles ?? {TenantRole.admin},
        core: core,
        location: '/players/p1',
        overrides: [guardiansRepositoryProvider.overrideWithValue(guardians)],
      );

  Future<void> fillGuardian(WidgetTester tester, {String? email}) async {
    await tapKey(tester, 'player-guardian-add');
    await enter(tester, 'guardian-given', 'Gala');
    await enter(tester, 'guardian-family', 'Ruiz');
    if (email != null) await enter(tester, 'guardian-email', email);
    await tapKey(tester, 'form-submit');
  }

  group('add a guardian from the player', () {
    testWidgets('with an e-mail: the temporary password is shown once', (
      tester,
    ) async {
      await openPlayer(tester);
      await fillGuardian(tester, email: 'gala@example.org');

      expect(guardians.created.single, {
        'playerId': 'p1',
        'givenName': 'Gala',
        'familyName': 'Ruiz',
        'email': 'gala@example.org',
      });
      final dialog = find.byKey(const Key('temp-password-dialog'));
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('Guardian-temp-1')),
        findsOneWidget,
      );
      await tapKey(tester, 'temp-password-done');
      expect(find.text('Guardian-temp-1'), findsNothing);
      expect(find.text('Gala Ruiz'), findsOneWidget); // the list was reloaded
      expect(find.text('Tutor añadido'), findsOneWidget);
    });

    testWidgets('an e-mail that already signs in: no dialog, only the note', (
      tester,
    ) async {
      guardians.newLoginPassword = null;
      await openPlayer(tester);
      await fillGuardian(tester, email: 'known@example.org');

      expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
      expect(find.textContaining('contraseña actual'), findsOneWidget);
    });

    testWidgets('without an e-mail: no login, no dialog', (tester) async {
      await openPlayer(tester);
      await fillGuardian(tester);

      expect(guardians.created.single['email'], isNull);
      expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
      expect(find.text('Tutor añadido'), findsOneWidget);
      expect(find.textContaining('contraseña actual'), findsNothing);
    });

    testWidgets('names are required and a bad e-mail is refused', (
      tester,
    ) async {
      await openPlayer(tester);
      await tapKey(tester, 'player-guardian-add');
      await enter(tester, 'guardian-email', 'not-an-email');
      await tapKey(tester, 'form-submit');

      expect(guardians.created, isEmpty);
      expect(find.byKey(const Key('guardian-given')), findsOneWidget);
    });

    testWidgets('a server error keeps the dialog open', (tester) async {
      guardians.failWith = emailTaken();
      await openPlayer(tester);
      await fillGuardian(tester, email: 'taken@example.org');

      expect(find.byKey(const Key('guardian-given')), findsOneWidget);
      expect(find.byKey(const Key('temp-password-dialog')), findsNothing);
    });

    testWidgets('a coach cannot add guardians', (tester) async {
      await openPlayer(tester, roles: {TenantRole.coach});
      expect(find.byKey(const Key('player-guardian-add')), findsNothing);
    });
  });

  group("a guardian's login", () {
    testWidgets('a guardian without a login gets a first one, shown once', (
      tester,
    ) async {
      await openPlayer(tester);
      await tapKey(tester, 'guardian-login-m2');

      expect(guardians.issuedFor, ['m2']);
      final dialog = find.byKey(const Key('temp-password-dialog'));
      expect(
        find.descendant(of: dialog, matching: find.text('First-login-1')),
        findsOneWidget,
      );
      await tapKey(tester, 'temp-password-done');
      expect(find.text('First-login-1'), findsNothing);
    });

    testWidgets('a guardian who signs in already has no login action', (
      tester,
    ) async {
      core.members.members[0] = core.members.members[0].rebuild(
        (b) => b..userId = 'u-m2',
      );
      await openPlayer(tester);
      expect(find.text('Pat Parent'), findsOneWidget);
      expect(find.byKey(const Key('guardian-login-m2')), findsNothing);
    });

    testWidgets('a guardian without an e-mail has no login action', (
      tester,
    ) async {
      core.members.members[0] = member(
        'm2',
        'Pat Parent',
        roles: {api.TenantRole.PARENT},
      ).rebuild((b) => b..email = null);
      await openPlayer(tester);
      expect(find.byKey(const Key('guardian-login-m2')), findsNothing);
    });
  });
}
