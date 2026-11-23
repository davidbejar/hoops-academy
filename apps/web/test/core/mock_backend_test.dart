import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/http/mock_api_adapter.dart';

import '../support/mock_backend.dart';

/// The backend of the widget tests (ADR-0070): the demo mock without its demo
/// data, seeded per test, with failures injected in front of it.
void main() {
  late MockBackend backend;
  late api.HoopsCoreApi client;
  const t = MockBackend.testTenantId;

  setUp(() {
    backend = MockBackend();
    client = api.HoopsCoreApi(
      dio: Dio(
        BaseOptions(
          baseUrl: 'http://mock',
          headers: {'Authorization': 'Bearer x'},
        ),
      )..httpClientAdapter = backend,
      interceptors: const [],
    );
  });

  test('starts empty: no demo academy, roster or platform data', () async {
    expect(
      (await client.getSeasonsApi().listSeasons(xTenantId: t)).data,
      isEmpty,
    );
    expect(
      (await client.getTeamsApi().listTeams(xTenantId: t)).data!.items,
      isEmpty,
    );
    expect(
      (await client.getAuditApi().listAuditEvents(xTenantId: t)).data!.items,
      isEmpty,
    );
    expect((await client.getPlatformApi().listTenants()).data!.items, isEmpty);
    expect(
      backend.academy(mockTenantAId),
      isNull,
      reason: 'the test academy replaces the demo one',
    );
  });

  test('a seeded row is served through the generated client', () async {
    backend.core.auditEvents.add({
      'id': 'e1',
      'at': '2026-11-03T09:30:00Z',
      'action': 'member.invited',
      'actor': {'kind': 'SYSTEM', 'subject': 'system'},
      'target': {'type': 'person', 'id': 'p1', 'displayName': 'Leo Gil'},
      'metadata': <String, Object?>{},
    });
    final page = (await client.getAuditApi().listAuditEvents(xTenantId: t))
        .data!;
    expect(page.items.single.target.displayName, 'Leo Gil');
  });

  test('fail answers a Problem+JSON until heal; once only once', () async {
    backend.fail('/api/core/seasons', status: 409, code: 'SEASON_OVERLAP');
    Future<int?> status() => client
        .getSeasonsApi()
        .listSeasons(xTenantId: t)
        .then<int?>((r) => r.statusCode)
        .catchError((Object e) => (e as DioException).response!.statusCode);
    expect(await status(), 409);
    expect(await status(), 409);
    backend.heal();
    expect(await status(), 200);
    backend.fail(RegExp('^/api/core/'), method: 'get', once: true);
    expect(await status(), 500);
    expect(await status(), 200);
  });

  test('the injected problem carries the business code', () async {
    backend.fail('/api/core/seasons', status: 422, code: 'EXPORT_TOO_LARGE');
    final e = await client
        .getSeasonsApi()
        .listSeasons(xTenantId: t)
        .then<Object?>((_) => null, onError: (Object e) => e);
    expect(
      ((e! as DioException).response!.data as Map)['code'],
      'EXPORT_TOO_LARGE',
    );
  });

  test('networkDown fails like a dropped connection', () async {
    backend.networkDown('/api/core/seasons');
    final e = await client
        .getSeasonsApi()
        .listSeasons(xTenantId: t)
        .then<Object?>((_) => null, onError: (Object e) => e);
    expect((e! as DioException).type, DioExceptionType.connectionError);
  });

  test('hang never answers', () async {
    backend.hang('/api/core/seasons');
    var answered = false;
    unawaited(
      client.getSeasonsApi().listSeasons(xTenantId: t).then((_) {
        answered = true;
      }),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(answered, isFalse);
  });

  test('records every request with its query', () async {
    await client.getAuditApi().listAuditEvents(xTenantId: t, page: 2);
    final r = backend.requestsTo('/api/core/audit-events').single;
    expect(r.headers['X-Tenant-Id'], t);
    expect(backend.lastQuery('/api/core/audit-events').integer('page', 0), 2);
  });
}
