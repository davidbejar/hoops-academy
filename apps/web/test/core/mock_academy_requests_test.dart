import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/landing/data/invitation_repository.dart';
import 'package:hoops_app/features/landing/domain/invitation_request.dart';
import 'package:hoops_app/features/platform/data/academy_request_repository.dart';

/// WP90 mock parity: the demo backend serves the public request (no sign-in) and the super admin's workbench through
/// the generated clients, so a response that does not match the contract fails the parse.
void main() {
  late MockApiAdapter adapter;

  api.HoopsCoreApi client({String? token = 'x'}) => api.HoopsCoreApi(
    dio: Dio(
      BaseOptions(
        baseUrl: 'http://mock',
        headers: {'Authorization': ?(token == null ? null : 'Bearer $token')},
      ),
    )..httpClientAdapter = adapter,
    interceptors: const [],
  );

  setUp(() => adapter = MockApiAdapter(roles: ['ADMIN']));

  InvitationRequest request(String academy, {String website = ''}) =>
      InvitationRequest(
        name: 'Ana Ruiz',
        email: 'ana@club.example',
        role: InvitationRole.parent,
        academy: academy,
        languageCode: 'en',
        website: website,
      );

  test('the seed has pending, accepted and rejected requests', () async {
    final repo = ApiAcademyRequestRepository(client());
    expect(await repo.list(api.AcademyRequestStatus.PENDING), hasLength(2));
    final accepted = await repo.list(api.AcademyRequestStatus.ACCEPTED);
    expect(accepted.single.tenantId, mockTenantBId);
    final rejected = await repo.list(api.AcademyRequestStatus.REJECTED);
    expect(rejected.single.reason, isNotEmpty);
    expect(rejected.single.notifiedAt, isNull, reason: 'an unsent e-mail');
  });

  test(
    'anyone may submit without signing in; it shows up as pending',
    () async {
      final outcome = await ApiInvitationRepository(client(token: null))
          .send(request('Canasta Club'));
      expect(outcome, InvitationOutcome.sent);
      final pending = await ApiAcademyRequestRepository(client())
          .list(api.AcademyRequestStatus.PENDING);
      expect(pending.first.academyName, 'Canasta Club');
      expect(pending.first.role, api.AcademyRequestRole.PARENT);
      expect(pending.first.locale, api.ApiLocale.en);
    },
  );

  test('a taken name is 409, a honeypot is dropped silently', () async {
    final public = ApiInvitationRepository(client(token: null));
    expect(
      await public.send(request('  club   NORTE ')),
      InvitationOutcome.academyTaken,
    );
    expect(
      await public.send(request('hoops bali')),
      InvitationOutcome.academyTaken,
      reason: 'a pending request holds its name',
    );
    expect(
      await public.send(request('Bot Club', website: 'x')),
      InvitationOutcome.sent,
    );
    final pending = await ApiAcademyRequestRepository(client())
        .list(api.AcademyRequestStatus.PENDING);
    expect(pending.map((r) => r.academyName), isNot(contains('Bot Club')));
  });

  test('the workbench is for the super admin only', () async {
    adapter = MockApiAdapter(roles: ['ADMIN'], superAdmin: false);
    expect(
      await ApiInvitationRepository(client(token: null))
          .send(request('Still Public')),
      InvitationOutcome.sent,
    );
    await expectLater(
      ApiAcademyRequestRepository(client())
          .list(api.AcademyRequestStatus.PENDING),
      throwsA(isA<DioException>()),
    );
  });

  test('accept creates the academy once; reject records the reason', () async {
    final repo = ApiAcademyRequestRepository(client());
    final pending = await repo.list(api.AcademyRequestStatus.PENDING);
    final first = pending.firstWhere((r) => r.academyName == 'Hoops Bali');
    final accepted = await repo.accept(
      first.id,
      api.AcceptAcademyRequest(
        (b) => b
          ..slug = 'hoops-bali'
          ..timezone = 'Asia/Makassar'
          ..defaultLocale = api.ApiLocale.id
          ..firstAdmin.replace(
            api.AcceptedAdmin(
              (a) => a
                ..givenName = 'Made'
                ..familyName = 'Wira',
            ),
          ),
      ),
    );
    expect(accepted.request.status, api.AcademyRequestStatus.ACCEPTED);
    expect(accepted.tenant.name, 'Hoops Bali');
    expect(accepted.request.tenantId, accepted.tenant.id);
    expect(accepted.temporaryPassword, isNotNull);
    final tenants = (await client().getPlatformApi().listTenants()).data!;
    expect(tenants.items.map((t) => t.slug), contains('hoops-bali'));

    await expectLater(
      repo.reject(first.id, 'late'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.data['code'],
          'code',
          'REQUEST_NOT_PENDING',
        ),
      ),
    );

    final other = pending.firstWhere((r) => r.id != first.id);
    final rejected = await repo.reject(other.id, 'Solo baloncesto');
    expect(rejected.status, api.AcademyRequestStatus.REJECTED);
    expect(rejected.reason, 'Solo baloncesto');
    expect(await repo.list(api.AcademyRequestStatus.PENDING), isEmpty);
  });
}
