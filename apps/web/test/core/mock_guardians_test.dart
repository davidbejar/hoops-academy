import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/admin/data/members_repository.dart';
import 'package:hoops_app/features/roster/data/guardians_repository.dart';

/// The demo backend's guardian logins (core 2.8.0) deserialise through the generated client like the server's.
void main() {
  const t = mockTenantAId;

  api.HoopsCoreApi clientAs(List<String> roles) => api.HoopsCoreApi(
    dio: Dio(
      BaseOptions(
        baseUrl: 'http://mock',
        headers: {'Authorization': 'Bearer x'},
      ),
    )..httpClientAdapter = MockApiAdapter(roles: roles),
    interceptors: const [],
  );

  test('a new guardian with an e-mail gets a login shown once', () async {
    final client = clientAs(['ADMIN']);
    final guardians = ApiGuardiansRepository(client, t);
    final members = ApiMembersRepository(client, t);

    final added = await guardians.create(
      playerId: 'p-leo',
      givenName: 'Gala',
      familyName: 'Vega',
      email: 'gala@x.io',
    );
    expect(added.temporaryPassword, isNotEmpty);
    expect(added.player.id, 'p-leo');
    final links = await members.guardianLinks(playerId: 'p-leo');
    expect(links.map((l) => l.guardian.displayName), contains('Gala Vega'));
    final gala = (await members.list(query: 'gala')).single;
    expect(gala.roles, contains(api.TenantRole.PARENT));
    expect(gala.invitationStatus, api.InvitationStatus.PENDING);
    expect(gala.userId, isNotNull);

    final noEmail = await guardians.create(
      playerId: 'p-leo',
      givenName: 'Nil',
      familyName: 'Mail',
    );
    expect(noEmail.temporaryPassword, isNull);
  });

  test('a guardian without an e-mail gets no login; the seed signs in', () async {
    final client = clientAs(['ADMIN']);
    final guardians = ApiGuardiansRepository(client, t);
    final members = ApiMembersRepository(client, t);
    final noLogin = await guardians.create(
      playerId: 'p-leo',
      givenName: 'Olga',
      familyName: 'Late',
    );
    final olga = (await members.list(query: 'olga')).single;
    expect(olga.userId, isNull);
    expect(noLogin.guardian.personId, olga.personId);

    // Without an e-mail there is no login to give (409); seed members sign in.
    await expectLater(
      guardians.issueTemporaryPassword(olga.personId),
      throwsA(isA<DioException>()),
    );
    final pat = (await members.list(query: 'pat')).single;
    expect(pat.userId, isNotNull);
  });

  test('only admins add guardians', () async {
    final guardians = ApiGuardiansRepository(clientAs(['COACH']), t);
    await expectLater(
      guardians.create(playerId: 'p-leo', givenName: 'X', familyName: 'Y'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          403,
        ),
      ),
    );
  });
}
