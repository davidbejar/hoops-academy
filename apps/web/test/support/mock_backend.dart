import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/core/http/dio_provider.dart';
import 'package:hoops_app/core/http/mock_api_adapter.dart';
import 'package:hoops_app/core/mock/mock_core_api.dart';
import 'package:hoops_app/core/mock/mock_query.dart';
import 'package:hoops_app/features/me/domain/current_user.dart';

/// The backend of the widget tests (ADR-0070): the demo mock with nothing in
/// it (no demo data), answering at once, behind the app's real repositories,
/// generated clients and interceptors. A test seeds what it needs through
/// [academy] and [platform], injects the failures the server can produce
/// ([fail], [hang], [networkDown]) and reads what the app asked in
/// [requests].
class MockBackend extends MockApiAdapter {
  MockBackend({
    Set<TenantRole> roles = const {TenantRole.admin},
    super.superAdmin = true,
    super.tenantAId = testTenantId,
  }) : super(
         demo: false,
         latency: Duration.zero,
         roles: [for (final r in roles) wireRole(r)],
         norteRoles: [for (final r in roles) wireRole(r)],
       );

  /// The academy of `membershipWithRoles` (fixtures.dart).
  static const testTenantId = '33333333-3333-4333-8333-333333333333';

  /// Every request the app sent, in order (failed and hung ones too).
  final List<RequestOptions> requests = [];

  final List<_Fault> _faults = [];

  /// The core mock of the test academy (the athlete, game and finance mocks of
  /// [academyApis] read its roster).
  MockCoreApi get core => academyApis.core;

  MockAcademyApis get academyApis => academy(tenantAId)!;

  /// Points the app's one Dio at this backend.
  List<Override> get overrides => [apiAdapterProvider.overrideWithValue(this)];

  /// Answers the matching requests with a Problem+JSON of [status] (and the
  /// business [code]) until [heal]. [path] is the exact path, or a [RegExp];
  /// a null [method] matches every method.
  void fail(
    Pattern path, {
    String? method,
    int status = 500,
    String? code,
    bool once = false,
  }) => _faults.add(
    _Fault(path, method, once, problem: (status: status, code: code)),
  );

  /// Never answers the matching requests (the loading state) until [heal].
  void hang(Pattern path, {String? method}) =>
      _faults.add(_Fault(path, method, false, hang: true));

  /// The matching requests fail like a dropped connection until [heal].
  void networkDown(Pattern path, {String? method}) =>
      _faults.add(_Fault(path, method, false, network: true));

  /// Every path of the backend.
  static final anyPath = RegExp('');

  /// Forgets every injected failure: the next requests reach the mock again.
  void heal() => _faults.clear();

  /// The requests to [path] (exact, or a [RegExp]) with [method] (any: null).
  List<RequestOptions> requestsTo(Pattern path, {String? method = 'GET'}) => [
    for (final r in requests)
      if (_matches(path, r.path) &&
          (method == null || r.method.toUpperCase() == method))
        r,
  ];

  /// The query of the last request to [path], read like the mock reads it.
  MockQuery lastQuery(Pattern path, {String? method = 'GET'}) =>
      MockQuery(requestsTo(path, method: method).last.queryParameters);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final fault = _faults
        .where(
          (f) =>
              _matches(f.path, options.path) &&
              (f.method == null || f.method == options.method.toUpperCase()),
        )
        .firstOrNull;
    if (fault != null) {
      if (fault.once) _faults.remove(fault);
      if (fault.hang) await Completer<void>().future;
      if (fault.network) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline (test)',
        );
      }
      final p = fault.problem!;
      return ResponseBody.fromString(
        jsonEncode({
          'type': 'urn:hoops:problem:test',
          'title': 'Injected by the test',
          'status': p.status,
          'code': ?p.code,
          'detail': 'English server detail that must never be shown',
        }),
        p.status,
        headers: {
          Headers.contentTypeHeader: ['application/problem+json'],
        },
      );
    }
    return super.fetch(options, requestStream, cancelFuture);
  }

  static bool _matches(Pattern pattern, String path) =>
      pattern is String ? pattern == path : pattern.allMatches(path).isNotEmpty;

  /// The role as the API spells it (`ASSISTANT_COACH`).
  static String wireRole(TenantRole r) => switch (r) {
    TenantRole.admin => 'ADMIN',
    TenantRole.coach => 'COACH',
    TenantRole.assistantCoach => 'ASSISTANT_COACH',
    TenantRole.parent => 'PARENT',
    TenantRole.player => 'PLAYER',
  };
}

class _Fault {
  _Fault(
    this.path,
    String? method,
    this.once, {
    this.problem,
    this.hang = false,
    this.network = false,
  }) : method = method?.toUpperCase();

  final Pattern path;
  final String? method;
  final bool once;
  final ({int status, String? code})? problem;
  final bool hang;
  final bool network;
}
