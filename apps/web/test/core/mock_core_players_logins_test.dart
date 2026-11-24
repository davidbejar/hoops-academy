import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/roster/data/approvals_repository.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';
import 'package:hoops_app/features/roster/data/players_repository.dart';

import '../support/core_fixtures.dart';
import '../support/core_seed.dart';
import '../support/mock_backend.dart';

/// The demo mock gives a player's login a temporary password like core does
/// (createPlayer, approveApprovalRequest) and words a decided request's 409
/// (ADR-0070: the roster fakes did, the mock did not).
void main() {
  const t = MockBackend.testTenantId;

  api.CreatePlayerRequest request({String? email}) => api.CreatePlayerRequest(
    (b) => b
      ..givenName = 'Luca'
      ..familyName = 'Mora'
      ..birthDate = api.Date(2015, 3, 4)
      ..gender = api.Gender.MALE
      ..email = email,
  );

  test('an admin creating a player with a new e-mail gets its password; '
      'without an e-mail or with one that signs in, none', () async {
    final backend = MockBackend()
      ..seedMembers([member('m1', 'Ada Admin', email: 'ada@x.org')]);
    final players = ApiPlayersRepository(backend.coreApi(), t);
    expect(
      (await players.create(request(email: 'luca@x.org'))).temporaryPassword,
      isNotNull,
    );
    expect((await players.create(request())).temporaryPassword, isNull);
    expect(
      (await players.create(request(email: 'ada@x.org'))).temporaryPassword,
      isNull,
      reason: 'an existing login is linked',
    );
  });

  test("a coach's request with an e-mail waits for the approval, which "
      'creates the login and returns its password once', () async {
    final coach = MockBackend(roles: {TenantRole.coach});
    final requested = await ApiPlayersRepository(
      coach.coreApi(),
      t,
    ).create(request(email: 'luca@x.org'));
    expect(requested.temporaryPassword, isNull);

    // The admin approves a request whose player asked for that login.
    final admin = MockBackend()..seedApprovals([approval('a1')]);
    admin.core.requestedLogins['p-a1'] = 'luca@x.org';
    final approvals = ApiApprovalsRepository(admin.coreApi(), t);
    expect((await approvals.approve('a1')).temporaryPassword, isNotNull);
  });

  test('deciding a decided request is 409 NOT_PENDING', () async {
    final admin = MockBackend()
      ..seedApprovals([approval('a1', status: api.ApprovalStatus.APPROVED)]);
    final approvals = ApiApprovalsRepository(admin.coreApi(), t);
    await expectLater(
      approvals.approve('a1'),
      throwsA(
        isA<DioException>().having(
          (e) => (e.response?.statusCode, (e.response?.data as Map)['code']),
          'status and code',
          (409, 'NOT_PENDING'),
        ),
      ),
    );
  });
}
