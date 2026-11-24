import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/admin/data/members_repository.dart';
import 'package:hoops_app/features/roster/data/guardians_repository.dart';

import '../support/core_fixtures.dart';
import '../support/core_seed.dart';
import '../support/mock_backend.dart';

/// Members' logins in the demo mock follow core (inviteMember,
/// issueMemberTemporaryPassword): an e-mail that already signs in elsewhere is
/// linked without a password, and its password is not reset from here
/// (ADR-0070: the members fake did this, the mock did not).
void main() {
  late MockBackend backend;
  late MembersRepository members;

  setUp(() {
    backend = MockBackend()..core.loginsElsewhere.add('ines@x.org');
    members = ApiMembersRepository(backend.coreApi(), MockBackend.testTenantId);
  });

  api.InviteMemberRequest invite(String email) => api.InviteMemberRequest(
    (b) => b
      ..givenName = 'Inés'
      ..familyName = 'Ibáñez'
      ..email = email
      ..roles.replace({api.TenantRole.COACH}),
  );

  test('a new e-mail gets a login with a temporary password', () async {
    final m = await members.invite(invite('nuevo@x.org'));
    expect(m.temporaryPassword, isNotNull);
    expect(m.invitationStatus, api.InvitationStatus.PENDING);
  });

  test('an e-mail that signs in elsewhere is linked: ACCEPTED, '
      'no password', () async {
    final m = await members.invite(invite('ines@x.org'));
    expect(m.temporaryPassword, isNull);
    expect(m.invitationStatus, api.InvitationStatus.ACCEPTED);
  });

  test("a guardian's first login with such an e-mail is linked too", () async {
    backend.seedMembers([
      member(
        'g1',
        'Inés Ibáñez',
        roles: {api.TenantRole.PARENT},
        email: 'ines@x.org',
      ),
    ]);
    final m = await members.issueTemporaryPassword('g1');
    expect(m.temporaryPassword, isNull);
    expect(m.invitationStatus, api.InvitationStatus.ACCEPTED);
  });

  test('a pending login shared with another academy is 409 '
      'LOGIN_SHARED', () async {
    backend.seedMembers([
      member(
        'm4',
        'Nina Nueva',
        email: 'ines@x.org',
        userId: 'u-nina',
        invitation: api.InvitationStatus.PENDING,
      ),
    ]);
    await expectLater(
      members.issueTemporaryPassword('m4'),
      throwsA(
        isA<DioException>().having(
          (e) => (e.response?.statusCode, (e.response?.data as Map)['code']),
          'status and code',
          (409, 'LOGIN_SHARED'),
        ),
      ),
    );
  });

  test('a guardian added with such an e-mail is linked without a '
      'password (createGuardian)', () async {
    backend.seedPlayers([player('p1', 'Ana Ruiz')]);
    final link =
        await ApiGuardiansRepository(
          backend.coreApi(),
          MockBackend.testTenantId,
        ).create(
          playerId: 'p1',
          givenName: 'Inés',
          familyName: 'Ibáñez',
          email: 'ines@x.org',
        );
    expect(link.temporaryPassword, isNull);
  });
}
