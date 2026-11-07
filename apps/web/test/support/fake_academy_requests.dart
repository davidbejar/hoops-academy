import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/platform/application/academy_request_providers.dart';
import 'package:hoops_app/features/platform/data/academy_request_repository.dart';

import 'fake_platform.dart' show tenantOf;
import 'fake_repos.dart' show Faulty;

api.AcademyRequest academyRequestOf(
  String id,
  String academy, {
  String? name = 'Lucía Pérez',
  String email = 'lucia@valle.example',
  api.AcademyRequestRole role = api.AcademyRequestRole.COACH,
  api.AcademyRequestStatus status = api.AcademyRequestStatus.PENDING,
  api.ApiLocale locale = api.ApiLocale.es,
  String? reason,
  String? tenantId,
  bool notified = true,
}) => api.AcademyRequest(
  (b) => b
    ..id = id
    ..status = status
    ..name = name
    ..email = email
    ..role = role
    ..academyName = academy
    ..locale = locale
    ..requestedAt = DateTime.utc(2026, 11, 5, 9)
    ..decidedAt = status == api.AcademyRequestStatus.PENDING
        ? null
        : DateTime.utc(2026, 11, 6)
    ..decidedBy = status == api.AcademyRequestStatus.PENDING ? null : 'root'
    ..reason = reason
    ..tenantId = tenantId
    ..notifiedAt = status != api.AcademyRequestStatus.PENDING && notified
        ? DateTime.utc(2026, 11, 6)
        : null,
);

/// In-memory workbench: decisions move a request between the lists like the server does.
class FakeAcademyRequestRepository
    with Faulty
    implements AcademyRequestRepository {
  FakeAcademyRequestRepository([List<api.AcademyRequest>? requests])
    : requests = requests ?? [];

  final List<api.AcademyRequest> requests;
  api.AcceptAcademyRequest? accepted;
  String? rejectedReason;

  /// Thrown by accept / reject only (the lists keep working), e.g. `problem(409, 'SLUG_TAKEN')`.
  Object? decisionFails;

  /// What the server returns for a login it creates (null: the person already had a login).
  String? newLoginPassword = 'Request-Temp-Pass1';

  List<Override> get overrides => [
    academyRequestRepositoryProvider.overrideWithValue(this),
  ];

  @override
  Future<List<api.AcademyRequest>> list(api.AcademyRequestStatus status) => run(
    'list',
    () => [
      for (final r in requests)
        if (r.status == status) r,
    ],
  );

  @override
  Future<api.AcademyRequestAccepted> accept(
    String requestId,
    api.AcceptAcademyRequest request,
  ) => run('accept', () {
    if (decisionFails != null) throw decisionFails!;
    accepted = request;
    final decided = _decide(
      requestId,
      (b) => b
        ..status = api.AcademyRequestStatus.ACCEPTED
        ..tenantId = 'new-tenant',
    );
    return api.AcademyRequestAccepted(
      (b) => b
        ..request.replace(decided)
        ..tenant.replace(
          tenantOf('new-tenant', decided.academyName, slug: request.slug),
        )
        ..temporaryPassword = newLoginPassword,
    );
  });

  @override
  Future<api.AcademyRequest> reject(String requestId, String reason) =>
      run('reject', () {
        if (decisionFails != null) throw decisionFails!;
        rejectedReason = reason;
        return _decide(
          requestId,
          (b) => b
            ..status = api.AcademyRequestStatus.REJECTED
            ..reason = reason,
        );
      });

  api.AcademyRequest _decide(
    String id,
    void Function(api.AcademyRequestBuilder) change,
  ) {
    final i = requests.indexWhere((r) => r.id == id);
    final decided = requests[i].rebuild(
      (b) => change(
        b
          ..decidedAt = DateTime.utc(2026, 11, 7)
          ..decidedBy = 'root'
          ..notifiedAt = DateTime.utc(2026, 11, 7),
      ),
    );
    requests[i] = decided;
    return decided;
  }
}
