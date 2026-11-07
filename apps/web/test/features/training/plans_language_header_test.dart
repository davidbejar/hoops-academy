import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/training/data/plans_repository.dart';

import '../../support/fake_adapter.dart';

/// The repository names the language itself: a switch refetches before the app root has published it (WP61).
void main() {
  test('the plan list carries the explicit Accept-Language', () async {
    final adapter = FakeAdapter([
      const FakeResponse(
        200,
        '{"items":[],"page":{"page":0,"size":100,"totalElements":0,"totalPages":0}}',
      ),
    ]);
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    final repo = ApiPlansRepository(
      ath.HoopsAthleteApi(dio: dio, interceptors: const []),
      'tenant-1',
    );

    await repo.plans(templates: true, language: 'id');
    expect(adapter.requests.single.headers['Accept-Language'], 'id');
    expect(adapter.requests.single.headers['X-Tenant-Id'], 'tenant-1');
  });
}
