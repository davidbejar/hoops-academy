import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/features/finance/data/finance_repository.dart';
import 'package:hoops_finance_api/hoops_finance_api.dart' as fin;

import '../../support/server_pages.dart';

/// The fee plans and a family's dues are shown whole (WEB-03, ADR-0061): the
/// repository reads every page of at most 200.
void main() {
  const count = 450;
  late ServerPagesAdapter server;
  late FinanceRepository repo;

  setUp(() {
    server = ServerPagesAdapter(
      count: count,
      inner: MockApiAdapter(roles: ['ADMIN']),
    );
    repo = ApiFinanceRepository(
      fin.HoopsFinanceApi(
        dio: Dio(
          BaseOptions(
            baseUrl: 'http://mock',
            headers: {'Authorization': 'Bearer x'},
          ),
        )..httpClientAdapter = server,
        interceptors: [],
      ),
      mockTenantAId,
    );
  });

  test('fee plans: every page', () async {
    expect(await repo.feePlans(), hasLength(count));
    expect(server.served.map((p) => (p.page, p.size)), [
      (0, 200),
      (1, 200),
      (2, 200),
    ]);
  });

  test('a player\'s dues: every page', () async {
    expect(await repo.playerDues('p-ana'), hasLength(count));
    expect(server.served.map((p) => (p.page, p.size)), [
      (0, 200),
      (1, 200),
      (2, 200),
    ]);
  });
}
