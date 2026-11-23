import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/core/api/api.dart' as api;
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
    super.selfId = testPersonId,
  }) : super(
         demo: false,
         latency: Duration.zero,
         roles: [for (final r in roles) wireRole(r)],
         norteRoles: [for (final r in roles) wireRole(r)],
       );

  /// The academy of `membershipWithRoles` (fixtures.dart).
  static const testTenantId = '33333333-3333-4333-8333-333333333333';

  /// The test user's person there (`membershipWithRoles`).
  static const testPersonId = 'person-me';

  /// Every request the app sent, in order (failed and hung ones too).
  final List<RequestOptions> requests = [];

  final List<_Fault> _faults = [];

  /// The core mock of the test academy (the athlete, game and finance mocks of
  /// [academyApis] read its roster).
  MockCoreApi get core => academyApis.core;

  MockAcademyApis get academyApis => academy(tenantAId)!;

  /// A Dio on this backend that signs its requests (no interceptors), for
  /// tests of providers without the app.
  Dio dio() => Dio(
    BaseOptions(
      baseUrl: 'http://mock',
      headers: {'Authorization': 'Bearer test'},
    ),
  )..httpClientAdapter = this;

  /// The generated core client on [dio].
  api.HoopsCoreApi coreApi() =>
      api.HoopsCoreApi(dio: dio(), interceptors: const []);

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

  /// Holds the matching requests (the loading state) until the returned
  /// release is called; then they and later ones reach the mock.
  void Function() hang(Pattern path, {String? method}) {
    final fault = _Fault(path, method, false, gate: Completer<void>());
    _faults.add(fault);
    return () {
      _faults.remove(fault);
      if (!fault.gate!.isCompleted) fault.gate!.complete();
    };
  }

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
  ) {
    requests.add(options);
    return _answer(options, requestStream, cancelFuture);
  }

  Future<ResponseBody> _answer(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final fault = _faults
        .where(
          (f) =>
              _matches(f.path, options.path) &&
              (f.method == null || f.method == options.method.toUpperCase()),
        )
        .firstOrNull;
    if (fault != null) {
      if (fault.once) _faults.remove(fault);
      if (fault.gate != null) {
        await fault.gate!.future;
        return _answer(options, requestStream, cancelFuture);
      }
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
    final answer = await super.fetch(options, requestStream, cancelFuture);
    final type = answer.headers[Headers.contentTypeHeader]?.firstOrNull ?? '';
    if (!type.contains('json')) return answer;
    final bytes = await answer.stream.fold<List<int>>(
      [],
      (a, b) => a..addAll(b),
    );
    _answers.add((
      request: options,
      status: answer.statusCode,
      json: bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes)),
    ));
    return ResponseBody.fromBytes(
      Uint8List.fromList(bytes),
      answer.statusCode,
      headers: answer.headers,
    );
  }

  final List<({RequestOptions request, int status, Object? json})> _answers =
      [];

  /// The JSON the mock answered the last request to [path] with (a map: an
  /// object; a list: an array).
  Object? lastAnswer(Pattern path, {String? method = 'GET'}) => _answers
      .where(
        (a) =>
            _matches(path, a.request.path) &&
            (method == null || a.request.method.toUpperCase() == method),
      )
      .last
      .json;

  /// The JSON body of [request] as the app sent it.
  static Map<String, Object?> bodyOf(RequestOptions request) {
    final data = request.data;
    final decoded = data is String ? jsonDecode(data) : data;
    return (decoded! as Map).cast<String, Object?>();
  }

  /// The JSON body of the last request to [path] with [method].
  Map<String, Object?> lastBody(Pattern path, {String method = 'POST'}) =>
      bodyOf(requestsTo(path, method: method).last);

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
    this.gate,
    this.network = false,
  }) : method = method?.toUpperCase();

  final Pattern path;
  final String? method;
  final bool once;
  final ({int status, String? code})? problem;
  final Completer<void>? gate;
  final bool network;
}

/// [value] (a core model) as the service sends it, for seeding the mock.
Map<String, Object?> coreJson<T>(T value) =>
    (api.standardSerializers.serialize(value, specifiedType: FullType(T))!
            as Map)
        .cast<String, Object?>();
