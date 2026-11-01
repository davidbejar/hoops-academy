import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/core/api/athlete_api.dart' as ath;
import 'package:hoops_app/features/health/data/fitness_repository.dart';
import 'package:hoops_app/features/health/data/health_repository.dart';
import 'package:hoops_app/features/platform/data/platform_repository.dart';
import 'package:hoops_app/features/training/data/plans_repository.dart';
import 'package:hoops_app/features/training/data/training_repository.dart';

/// Records every request (with its JSON body) and answers canned JSON.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final Object? Function(RequestOptions) respond;
  RequestOptions? last;
  Object? body;
  int status = 200;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    last = options;
    final chunks = <int>[];
    if (requestStream != null) {
      await for (final c in requestStream) {
        chunks.addAll(c);
      }
    }
    body = chunks.isEmpty ? null : jsonDecode(utf8.decode(chunks));
    return ResponseBody.fromString(
      jsonEncode(respond(options)),
      status,
      headers: {
        Headers.contentTypeHeader: [status >= 400 ? 'application/problem+json' : 'application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const tenant = '11111111-1111-4111-8111-111111111111';
const uuid = '22222222-2222-4222-8222-222222222222';

Dio _dio(_Adapter a) => Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = a;
ath.HoopsAthleteApi _athlete(_Adapter a) => ath.HoopsAthleteApi(dio: _dio(a), interceptors: const []);
api.HoopsCoreApi _core(_Adapter a) => api.HoopsCoreApi(dio: _dio(a), interceptors: const []);

Map<String, Object?> _session() => {
  'id': uuid,
  'teamId': uuid,
  'startsAt': '2026-11-03T17:00:00Z',
  'durationMinutes': 90,
  'status': 'PLANNED',
};

Map<String, Object?> _audit() => {
  'recordedBy': {'personId': uuid, 'displayName': 'Casey'},
  'recordedAt': '2026-11-01T10:00:00Z',
};

void main() {
  group('training', () {
    test('sessions: tenant header, team and date range as query parameters', () async {
      final a = _Adapter((_) => {'items': [_session()], 'page': {'page': 0, 'size': 200, 'totalElements': 1, 'totalPages': 1}});
      final repo = ApiTrainingRepository(_athlete(a), tenant);
      final list = await repo.sessions(teamId: uuid, from: ath.Date(2026, 11, 2), to: ath.Date(2026, 11, 8));
      expect(list.single.durationMinutes, 90);
      expect(a.last!.path, '/api/athlete/training-sessions');
      expect(a.last!.headers['X-Tenant-Id'], tenant);
      expect(a.last!.queryParameters, containsPair('from', '2026-11-02'));
      expect(a.last!.queryParameters, containsPair('to', '2026-11-08'));
      expect(a.last!.queryParameters, containsPair('teamId', uuid));
    });

    test('attendance: entries with LATE minutes are sent as the contract body; overlay fields parsed', () async {
      final a = _Adapter((o) => {
        'sessionId': uuid,
        'entries': [
          {'playerId': uuid, 'status': null, 'expectedAbsent': true, 'plannedAbsenceId': uuid, 'unavailableInjuryId': uuid},
        ],
      });
      final repo = ApiTrainingRepository(_athlete(a), tenant);
      final r = await repo.recordAttendance(uuid, [
        ath.AttendanceInput((b) => b
          ..playerId = uuid
          ..status = ath.AttendanceStatus.LATE
          ..minutesLate = 7),
      ]);
      expect(a.last!.method, 'PUT');
      expect(a.body, {
        'entries': [
          {'playerId': uuid, 'status': 'LATE', 'minutesLate': 7},
        ],
      });
      expect(r.entries.single.expectedAbsent, isTrue);
      expect(r.entries.single.status, isNull);
      expect(r.entries.single.unavailableInjuryId, uuid);
    });

    test('cancel sends the reason', () async {
      final a = _Adapter((_) => {..._session(), 'status': 'CANCELLED', 'cancelReason': 'Lluvia'});
      final s = await ApiTrainingRepository(_athlete(a), tenant).cancelSession(uuid, 'Lluvia');
      expect(a.body, {'reason': 'Lluvia'});
      expect(s.status, ath.TrainingSessionStatus.CANCELLED);
    });

    test('schedule input serialises weekday, HH:MM and dates', () async {
      final a = _Adapter((_) => {'id': uuid, 'teamId': uuid, 'dayOfWeek': 'TUESDAY', 'startTime': '18:00:00', 'durationMinutes': 90, 'validFrom': '2026-09-01'});
      await ApiTrainingRepository(_athlete(a), tenant).createSchedule(
        ath.$TrainingScheduleInput((b) => b
          ..teamId = uuid
          ..dayOfWeek = ath.DayOfWeek.TUESDAY
          ..startTime = '18:00'
          ..durationMinutes = 90
          ..validFrom = ath.Date(2026, 9, 1)),
      );
      expect(a.body, containsPair('dayOfWeek', 'TUESDAY'));
      expect(a.body, containsPair('startTime', '18:00'));
      expect(a.body, containsPair('validFrom', '2026-09-01'));
    });

    test('planned absence round trip', () async {
      final a = _Adapter((_) => {'id': uuid, 'playerId': uuid, 'fromDate': '2026-11-10', 'toDate': '2026-11-12', ..._audit()});
      final r = await ApiTrainingRepository(_athlete(a), tenant).createAbsence(
        ath.$PlannedAbsenceInput((b) => b
          ..playerId = uuid
          ..fromDate = ath.Date(2026, 11, 10)
          ..toDate = ath.Date(2026, 11, 12)),
      );
      expect(a.body, containsPair('fromDate', '2026-11-10'));
      expect(r.toDate, ath.Date(2026, 11, 12));
    });
  });

  group('plans', () {
    test('library: template flag and search text', () async {
      final a = _Adapter((_) => {'items': [], 'page': {'page': 0, 'size': 100, 'totalElements': 0, 'totalPages': 0}});
      await ApiPlansRepository(_athlete(a), tenant).plans(templates: true, query: 'tiro');
      expect(a.last!.queryParameters, containsPair('template', true));
      expect(a.last!.queryParameters, containsPair('q', 'tiro'));
    });

    test('copy-on-use POSTs to :copy and parses the new plan', () async {
      final a = _Adapter((_) => {'id': uuid, 'name': 'Copia', 'template': false, 'itemCount': 0, 'totalDurationMinutes': 0, 'items': []});
      final p = await ApiPlansRepository(_athlete(a), tenant).copyPlan(uuid, name: 'Copia');
      expect(a.last!.path, endsWith(':copy'));
      expect(a.body, {'name': 'Copia'});
      expect(p.template, isFalse);
    });

    test('reorder sends the full permutation of item ids', () async {
      final a = _Adapter((_) => <Object?>[]);
      await ApiPlansRepository(_athlete(a), tenant).reorder(uuid, ['b', 'a']);
      expect(a.body, {'itemIds': ['b', 'a']});
    });

    test('assignment has exactly one target; completion posts status and comment', () async {
      final a = _Adapter((_) => {
        'id': uuid,
        'plan': {'id': uuid, 'name': 'P', 'template': false, 'itemCount': 0, 'totalDurationMinutes': 0},
        'teamId': uuid,
        'dueOn': '2026-11-20',
        ..._audit(),
      });
      await ApiPlansRepository(_athlete(a), tenant).assign(
        ath.CreatePlanAssignmentRequest((b) => b
          ..planId = uuid
          ..teamId = uuid
          ..dueOn = ath.Date(2026, 11, 20)),
      );
      expect(a.body, {'planId': uuid, 'teamId': uuid, 'dueOn': '2026-11-20'});
      final c = _Adapter((_) => {'id': uuid, 'assignmentId': uuid, 'playerId': uuid, 'status': 'PARTIAL', 'comment': 'a medias', ..._audit()});
      final r = await ApiPlansRepository(_athlete(c), tenant).record(uuid, uuid, ath.CompletionStatus.PARTIAL, comment: 'a medias');
      expect(c.last!.path, contains('/completions'));
      expect(c.body, {'status': 'PARTIAL', 'comment': 'a medias'});
      expect(r.status, ath.CompletionStatus.PARTIAL);
    });
  });

  group('health and fitness', () {
    test('injury recovery update', () async {
      final a = _Adapter((_) => {'id': uuid, 'playerId': uuid, 'bodyPart': 'Rodilla', 'severity': 'MINOR', 'status': 'RECOVERED', 'occurredOn': '2026-10-01', 'actualReturnOn': '2026-10-20', ..._audit()});
      final i = await ApiHealthRepository(_athlete(a), tenant).updateInjury(
        uuid,
        ath.UpdateInjuryRequest((b) => b
          ..status = ath.InjuryStatus.RECOVERED
          ..actualReturnOn = ath.Date(2026, 10, 20)),
      );
      expect(a.last!.method, 'PATCH');
      expect(a.body, {'status': 'RECOVERED', 'actualReturnOn': '2026-10-20'});
      expect(i.status, ath.InjuryStatus.RECOVERED);
    });

    test('measurements are listed per player', () async {
      final a = _Adapter((_) => [
        {'id': uuid, 'playerId': uuid, 'measuredOn': '2026-10-10', 'heightCm': 148.5, ..._audit()},
      ]);
      final list = await ApiHealthRepository(_athlete(a), tenant).measurements(uuid);
      expect(a.last!.queryParameters, containsPair('playerId', uuid));
      expect(list.single.heightCm, 148.5);
      expect(list.single.weightKg, isNull);
    });

    test('a created result carries the expected band and the reference-pending flag', () async {
      final a = _Adapter((_) => {
        'id': uuid, 'playerId': uuid, 'testTypeId': uuid, 'testCode': 'VJ', 'unit': 'cm', 'measuredOn': '2026-10-10', 'value': 35.0,
        'ageAtMeasurement': 11, 'expectedBand': 'AVERAGE', 'bandStatus': 'MATCHED', 'normId': uuid, 'referencePending': true, ..._audit(),
      });
      final r = await ApiFitnessRepository(_athlete(a), tenant).createResult(
        ath.PhysicalTestResultInput((b) => b
          ..playerId = uuid
          ..testTypeId = uuid
          ..measuredOn = ath.Date(2026, 10, 10)
          ..value = 35),
      );
      expect(r.expectedBand, ath.NormBand.AVERAGE);
      expect(r.referencePending, isTrue);
    });

    test('norms: scope parameter, tenant norm input uses source_ -> source', () async {
      final a = _Adapter((_) => <Object?>[]);
      final repo = ApiFitnessRepository(_athlete(a), tenant);
      await repo.norms(scope: 'TENANT', testTypeId: uuid);
      expect(a.last!.queryParameters, containsPair('scope', 'TENANT'));
      expect(a.last!.queryParameters, containsPair('testTypeId', uuid));
      final b = _Adapter((_) => {'id': uuid, 'global': false, 'referencePending': false, 'testTypeId': uuid, 'gender': 'MALE', 'minAge': 10, 'maxAge': 12, 'band': 'AVERAGE', 'source': 'Club'});
      await ApiFitnessRepository(_athlete(b), tenant).createNorm(
        ath.$PhysicalTestNormInput((n) => n
          ..testTypeId = uuid
          ..gender = ath.Gender.MALE
          ..minAge = 10
          ..maxAge = 12
          ..band = ath.NormBand.AVERAGE
          ..source_ = 'Club'),
      );
      expect(b.body, containsPair('source', 'Club'));
    });
  });

  group('platform', () {
    Map<String, Object?> tenantJson(String status) => {
      'id': uuid, 'slug': 'norte', 'name': 'Norte', 'status': status, 'timezone': 'Europe/Madrid', 'defaultLocale': 'es', 'createdAt': '2026-01-05T10:00:00Z',
    };

    test('no tenant header on /platform; list filters', () async {
      final a = _Adapter((_) => {'items': [tenantJson('ACTIVE')], 'page': {'page': 0, 'size': 100, 'totalElements': 1, 'totalPages': 1}});
      final list = await ApiPlatformRepository(_core(a)).tenants(status: api.TenantStatus.ACTIVE, query: 'nor');
      expect(a.last!.path, '/platform/tenants');
      expect(a.last!.headers.containsKey('X-Tenant-Id'), isFalse);
      expect(a.last!.queryParameters, containsPair('status', 'ACTIVE'));
      expect(a.last!.queryParameters, containsPair('q', 'nor'));
      expect(list.single.status, api.TenantStatus.ACTIVE);
    });

    test('create sends the first admin; suspend and withdraw send the reason; reactivate none', () async {
      final a = _Adapter((_) => tenantJson('ACTIVE'));
      final repo = ApiPlatformRepository(_core(a));
      await repo.create(
        api.CreateTenantRequest((b) => b
          ..slug = 'norte'
          ..name = 'Norte'
          ..timezone = 'Europe/Madrid'
          ..defaultLocale = api.ApiLocale.es
          ..firstAdmin.replace(api.FirstAdmin((f) => f
            ..email = 'a@b.co'
            ..givenName = 'A'
            ..familyName = 'B'))),
      );
      expect((a.body as Map)['firstAdmin'], containsPair('email', 'a@b.co'));
      await repo.suspend(uuid, 'Impago');
      expect(a.last!.path, endsWith('/suspend'));
      expect(a.body, {'reason': 'Impago'});
      await repo.withdraw(uuid, 'Cierre');
      expect(a.last!.path, endsWith('/withdraw'));
      await repo.reactivate(uuid);
      expect(a.last!.path, endsWith('/reactivate'));
    });

    test('usage parses counters per service and the unavailable list', () async {
      final a = _Adapter((_) => {
        'tenantId': uuid,
        'collectedAt': '2026-11-01T10:00:00Z',
        'services': [
          {'tenantId': uuid, 'service': 'core', 'collectedAt': '2026-11-01T10:00:00Z', 'counters': {'players': 80, 'newOne': 1}},
        ],
        'unavailableServices': ['game'],
      });
      final u = await ApiPlatformRepository(_core(a)).usage(uuid);
      expect(u.services.single.counters['players'], 80);
      expect(u.services.single.counters['newOne'], 1);
      expect(u.unavailableServices.single, api.TenantUsageUnavailableServicesEnum.game);
    });
  });
}
