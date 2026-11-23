import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';

/// The demo mock pages every list like the services (`Size` and `Page` in
/// common.yaml, `PageOffset`): `size` 1..200 with 50 by default, anything else
/// a 400, and the items of the asked page only. Otherwise a first-page-only
/// read (WEB-03) cannot show in the demo.
void main() {
  const lists = {
    '/api/core/players': <String, Object>{},
    '/api/core/members': <String, Object>{},
    '/api/core/teams': <String, Object>{},
    '/api/core/approval-requests': <String, Object>{},
    '/api/core/eligibility-cases': <String, Object>{},
    '/api/core/guardian-links': <String, Object>{},
    '/api/core/audit-events': <String, Object>{},
    '/api/game/matches': <String, Object>{},
    '/api/athlete/exercises': <String, Object>{},
    '/api/athlete/injuries': <String, Object>{},
    '/api/athlete/physical-test-results': <String, Object>{},
    '/api/athlete/plan-assignments': <String, Object>{},
    '/api/athlete/plan-completions': <String, Object>{},
    '/api/athlete/planned-absences': <String, Object>{},
    '/api/athlete/training-plans': <String, Object>{},
    '/api/athlete/training-sessions': {
      'from': '2000-01-01',
      'to': '2100-01-01',
    },
    '/api/finance/fee-plans': <String, Object>{},
    '/api/finance/dues': <String, Object>{},
    '/api/finance/expenses': <String, Object>{},
    '/api/finance/players/p-ana/dues': <String, Object>{},
    '/platform/tenants': <String, Object>{},
    '/platform/users': <String, Object>{},
    '/platform/audit-events': <String, Object>{},
    '/platform/tenants/$mockTenantAId/admins': <String, Object>{},
    '/platform/academy-requests': {'status': 'PENDING'},
  };

  late Dio dio;
  setUp(() {
    dio =
        Dio(
            BaseOptions(
              baseUrl: 'http://mock',
              headers: {
                'Authorization': 'Bearer x',
                'X-Tenant-Id': mockTenantAId,
              },
              validateStatus: (_) => true,
            ),
          )
          ..httpClientAdapter = MockApiAdapter(
            roles: ['ADMIN', 'COACH'],
            superAdmin: true,
          );
  });

  Future<Response<dynamic>> get(String path, Map<String, Object> q) =>
      dio.get<dynamic>(path, queryParameters: q);

  for (final MapEntry(key: path, value: filter) in lists.entries) {
    test('$path pages like the server', () async {
      final whole = await get(path, {...filter, 'size': 200});
      expect(whole.statusCode, 200, reason: '${whole.data}');
      final total = (whole.data['page'] as Map)['totalElements'] as int;
      final items = whole.data['items'] as List;
      expect(items, hasLength(total));
      expect(total, greaterThan(0), reason: 'the demo has some');

      for (var page = 0; page < total; page++) {
        final one = await get(path, {...filter, 'page': page, 'size': 1});
        expect(one.data['page'], {
          'page': page,
          'size': 1,
          'totalElements': total,
          'totalPages': total,
        });
        expect(one.data['items'], hasLength(1));
        expect(_identity(one.data['items'][0]), _identity(items[page]));
      }

      final byDefault = await get(path, filter);
      expect((byDefault.data['page'] as Map)['size'], 50);

      for (final size in [0, 201]) {
        final refused = await get(path, {...filter, 'size': size});
        expect(refused.statusCode, 400, reason: 'size $size');
      }
      final negative = await get(path, {...filter, 'page': -1});
      expect(negative.statusCode, 400, reason: 'page -1');
    });
  }
}

/// What tells two items apart (some carry a time the mock takes at each call).
Object? _identity(Object? item) {
  final m = item! as Map;
  return m['id'] ?? m['personId'] ?? m;
}
