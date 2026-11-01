import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/errors/app_error.dart';
import 'package:hoops_app/core/http/interceptors.dart';

import '../support/fake_adapter.dart';

class _Tokens {
  String? token = 'tok-1';
  String? refreshedTo = 'tok-2';
  int refreshCalls = 0;
  int sessionExpired = 0;
}

(Dio, FakeAdapter, _Tokens) _build(
  List<FakeResponse> responses, {
  String? tenant = 'tenant-1',
  String locale = 'id',
}) {
  final tokens = _Tokens();
  final adapter = FakeAdapter(responses);
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.addAll(
    buildInterceptors(
      dio: dio,
      accessToken: () async => tokens.token,
      refresh: () async {
        tokens.refreshCalls++;
        if (tokens.refreshedTo == null) return false;
        tokens.token = tokens.refreshedTo;
        return true;
      },
      onSessionExpired: () => tokens.sessionExpired++,
      tenantId: () => tenant,
      languageCode: () => locale,
    ),
  );
  return (dio, adapter, tokens);
}

void main() {
  test('adds bearer, X-Tenant-Id and Accept-Language', () async {
    final (dio, adapter, _) = _build([const FakeResponse(200, '{}')]);

    await dio.get<Object>('/api/core/tenant');

    final headers = adapter.requests.single.headers;
    expect(headers['Authorization'], 'Bearer tok-1');
    expect(headers['X-Tenant-Id'], 'tenant-1');
    expect(headers['Accept-Language'], 'id');
  });

  test('does not send X-Tenant-Id to /me or /platform', () async {
    final (dio, adapter, _) = _build([const FakeResponse(200, '{}')]);

    await dio.get<Object>('/api/core/me');
    await dio.get<Object>('/platform/tenants');

    for (final r in adapter.requests) {
      expect(r.headers.containsKey('X-Tenant-Id'), isFalse, reason: r.path);
    }
  });

  test('keeps an explicit X-Tenant-Id set by the generated client', () async {
    final (dio, adapter, _) = _build([const FakeResponse(200, '{}')]);

    await dio.get<Object>(
      '/api/core/tenant',
      options: Options(headers: {'X-Tenant-Id': 'explicit'}),
    );

    expect(adapter.requests.single.headers['X-Tenant-Id'], 'explicit');
  });

  test('omits Authorization when there is no token', () async {
    final (dio, adapter, tokens) = _build([const FakeResponse(200, '{}')]);
    tokens.token = null;

    await dio.get<Object>('/api/core/tenant');

    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('on 401 refreshes once and retries with the new token', () async {
    final (dio, adapter, tokens) = _build([
      FakeResponse.problem(401, {'title': 'Unauthorized', 'status': 401}),
      const FakeResponse(200, '{"ok":true}'),
    ]);

    final response = await dio.get<Object>('/api/core/tenant');

    expect(response.statusCode, 200);
    expect(tokens.refreshCalls, 1);
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.headers['Authorization'], 'Bearer tok-2');
    expect(tokens.sessionExpired, 0);
  });

  test('on 401 with failed refresh signals session expiry', () async {
    final (dio, _, tokens) = _build([
      FakeResponse.problem(401, {'title': 'Unauthorized', 'status': 401}),
    ]);
    tokens.refreshedTo = null;

    await expectLater(
      dio.get<Object>('/api/core/tenant'),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          isA<AppError>().having((a) => a.kind, 'kind', AppErrorKind.unauthorized),
        ),
      ),
    );
    expect(tokens.sessionExpired, 1);
  });

  test('a second 401 after retry does not loop', () async {
    final (dio, adapter, tokens) = _build([
      FakeResponse.problem(401, {'title': 'Unauthorized', 'status': 401}),
    ]);

    await expectLater(dio.get<Object>('/x'), throwsA(isA<DioException>()));

    expect(adapter.requests, hasLength(2));
    expect(tokens.refreshCalls, 1);
  });

  test('errors surface as AppError with Problem fields', () async {
    final (dio, _, _) = _build([
      FakeResponse.problem(404, {
        'title': 'Not found',
        'status': 404,
        'traceId': 't-1',
      }),
    ]);

    try {
      await dio.get<Object>('/api/core/tenant');
      fail('expected error');
    } on DioException catch (e) {
      final error = e.error! as AppError;
      expect(error.kind, AppErrorKind.notFound);
      expect(error.traceId, 't-1');
    }
  });

  test('network failure surfaces as AppError.network', () async {
    final (dio, _, _) = _build([const FakeResponse.network()]);

    try {
      await dio.get<Object>('/x');
      fail('expected error');
    } on DioException catch (e) {
      expect((e.error! as AppError).kind, AppErrorKind.network);
    }
  });
}
