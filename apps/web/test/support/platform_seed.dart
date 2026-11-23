import 'package:hoops_app/core/api/api.dart' as api;

import 'mock_backend.dart';

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

/// Seeds the platform console's data.
extension PlatformSeed on MockBackend {
  /// The academy requests, newest first as the workbench lists them.
  void seedAcademyRequests(List<api.AcademyRequest> requests) =>
      platform.academyRequests.addAll(requests.reversed.map(coreJson));

  /// The academies the platform knows.
  void seedTenants(List<api.Tenant> tenants) =>
      platform.tenants.addAll(tenants.map(coreJson));
}
