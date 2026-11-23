import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/platform/data/platform_repository.dart';

/// The demo mock's academy administrators follow the contract (core:
/// createTenant, addTenantAdmin, removeTenantAdmin), as the platform tests'
/// former fake did (ADR-0070).
void main() {
  late PlatformRepository repo;

  setUp(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://mock',
        headers: {'Authorization': 'Bearer x'},
      ),
    )..httpClientAdapter = MockApiAdapter(roles: ['ADMIN']);
    repo = ApiPlatformRepository(
      api.HoopsCoreApi(dio: dio, interceptors: const []),
    );
  });

  test('a new login gets a temporary password', () async {
    final added = await repo.addAdmin(
      mockTenantAId,
      api.AddTenantAdminRequest(
        (b) => b
          ..email = 'new.person@example.org'
          ..givenName = 'New'
          ..familyName = 'Person',
      ),
    );
    expect(added.temporaryPassword, isNotNull);
    expect(added.invitationStatus, api.InvitationStatus.PENDING);
  });

  test('an e-mail that already signs in elsewhere is linked: no password, '
      'the invitation accepted', () async {
    // Nora administers Club Norte: her login exists.
    final added = await repo.addAdmin(
      mockTenantAId,
      api.AddTenantAdminRequest(
        (b) => b
          ..email = 'nora@norte.example'
          ..givenName = 'Nora'
          ..familyName = 'Norte',
      ),
    );
    expect(added.temporaryPassword, isNull);
    expect(added.invitationStatus, api.InvitationStatus.ACCEPTED);

    final created = await repo.create(
      api.CreateTenantRequest(
        (b) => b
          ..slug = 'valle'
          ..name = 'Valle'
          ..timezone = 'Europe/Madrid'
          ..defaultLocale = api.ApiLocale.es
          ..firstAdmin.email = 'alicia@demo.example'
          ..firstAdmin.givenName = 'Alicia'
          ..firstAdmin.familyName = 'Admin',
      ),
    );
    expect(created.temporaryPassword, isNull);
  });

  test(
    "the academy's last administrator cannot be removed (409 LAST_ADMIN)",
    () async {
      final norte = await repo.admins(mockTenantBId);
      expect(norte, hasLength(1));
      await expectLater(
        repo.removeAdmin(mockTenantBId, norte.single.personId),
        throwsA(
          isA<DioException>().having(
            (e) => (e.response?.statusCode, (e.response?.data as Map)['code']),
            'status and code',
            (409, 'LAST_ADMIN'),
          ),
        ),
      );
      expect(await repo.admins(mockTenantBId), hasLength(1));
    },
  );
}
