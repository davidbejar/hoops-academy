import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/me/data/me_repository.dart';
import 'package:hoops_app/features/platform/data/platform_repository.dart';

/// WP99 mock parity for the two core 3.4.0 changes: `GET /platform/users` and
/// `PATCH /me` with a name. The generated clients parse every answer, so a
/// response that does not match the contract fails here.
void main() {
  late MockApiAdapter adapter;

  Dio dio() => Dio(
    BaseOptions(baseUrl: 'http://mock', headers: {'Authorization': 'Bearer x'}),
  )..httpClientAdapter = adapter;

  api.HoopsCoreApi client() =>
      api.HoopsCoreApi(dio: dio(), interceptors: const []);

  setUp(() => adapter = MockApiAdapter(roles: ['ADMIN']));

  group('GET /platform/users', () {
    test('groups the logins; one in two academies is one user', () async {
      final page = await ApiPlatformRepository(client()).users();

      final casey = page.items.singleWhere(
        (u) => u.email == 'coach1@hoops-academy.com',
      );
      expect(
        casey.memberships.map((m) => m.tenantName),
        containsAll(['Academia Demo', 'Club Norte']),
      );
      expect(page.page.totalElements, page.items.length);
      expect(
        page.items.any((u) => u.email == 'alicia@demo.example'),
        isTrue,
        reason: 'academy administrators are users too',
      );
    });

    test('q is a case-insensitive substring of e-mail or name', () async {
      final repo = ApiPlatformRepository(client());
      final byMail = await repo.users(query: 'CASEY');
      expect(byMail.items.map((u) => u.email), ['coach1@hoops-academy.com']);
      final byName = await repo.users(query: 'bruno nuevo');
      expect(byName.items.single.email, 'bruno@demo.example');
    });

    test('q of one character or over 100 is a 400', () async {
      final repo = ApiPlatformRepository(client());
      for (final q in ['a', 'x' * 101]) {
        await expectLater(
          repo.users(query: q),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              400,
            ),
          ),
        );
      }
    });

    test('pages like the other lists', () async {
      final repo = ApiPlatformRepository(client());
      final second = await repo.users(page: 1, size: 2);
      expect(second.page.page, 1);
      expect(second.items, hasLength(2));
      expect(second.page.totalPages, greaterThan(1));
    });

    test('a plain member gets 403', () async {
      adapter = MockApiAdapter(roles: ['ADMIN'], superAdmin: false);
      await expectLater(
        ApiPlatformRepository(client()).users(),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            403,
          ),
        ),
      );
    });
  });

  group('PATCH /me with a name', () {
    Future<List<api.Member>> members() async =>
        (await client().getMembersApi().listMembers(xTenantId: mockTenantAId))
            .data!
            .items
            .toList();

    test('renames the caller in that academy; /me and the member list '
        'show it', () async {
      final me = ApiMeRepository(dio());
      await me.updateName(
        tenantId: mockTenantAId,
        givenName: 'Carlos',
        familyName: 'Cano',
      );

      expect((await me.fetch()).displayName, 'Carlos Cano');
      final own = (await members()).singleWhere((m) => m.personId == 'a1');
      expect(own.givenName, 'Carlos');
      expect(own.familyName, 'Cano');
    });

    test('only the sent part changes', () async {
      final me = ApiMeRepository(dio());
      await me.updateName(tenantId: mockTenantAId, familyName: 'Cano');
      expect((await me.fetch()).displayName, 'Casey Cano');
    });

    test('a name without tenantId is a 400', () async {
      await expectLater(
        dio().patch<Object?>('/api/core/me', data: {'givenName': 'X'}),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            400,
          ),
        ),
      );
    });

    test('e-mail is refused with a 400', () async {
      await expectLater(
        dio().patch<Object?>(
          '/api/core/me',
          data: {'tenantId': mockTenantAId, 'email': 'x@y.org'},
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            400,
          ),
        ),
      );
    });

    test('an academy the caller does not belong to is a 404', () async {
      await expectLater(
        ApiMeRepository(dio()).updateName(
          tenantId: '99999999-9999-4999-8999-999999999999',
          givenName: 'X',
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            404,
          ),
        ),
      );
    });

    test('the language alone still works without an academy', () async {
      await ApiMeRepository(dio()).updateLocale('id');
      expect((await ApiMeRepository(dio()).fetch()).localeCode, 'id');
    });
  });
}
