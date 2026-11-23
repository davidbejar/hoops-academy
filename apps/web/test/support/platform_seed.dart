import 'package:built_collection/built_collection.dart';
import 'package:hoops_app/core/api/api.dart' as api;

import 'mock_backend.dart';

api.Tenant tenantOf(
  String id,
  String name, {
  String? slug,
  api.TenantStatus status = api.TenantStatus.ACTIVE,
}) => api.Tenant(
  (b) => b
    ..id = id
    ..slug = slug ?? name.toLowerCase().replaceAll(' ', '-')
    ..name = name
    ..status = status
    ..timezone = 'Europe/Madrid'
    ..defaultLocale = api.ApiLocale.es
    ..createdAt = DateTime.utc(2026, 1, 5),
);

api.PlatformUserMembership userMembership(
  String tenantId,
  String tenantName, {
  String given = 'Casey',
  String family = 'Coach',
  Set<api.TenantRole> roles = const {api.TenantRole.COACH},
  bool active = true,
  api.TenantStatus status = api.TenantStatus.ACTIVE,
}) => api.PlatformUserMembership(
  (b) => b
    ..tenantId = tenantId
    ..tenantName = tenantName
    ..tenantSlug = tenantName.toLowerCase().replaceAll(' ', '-')
    ..tenantStatus = status
    ..personId = 'p-$tenantId'
    ..givenName = given
    ..familyName = family
    ..roles = SetBuilder<api.TenantRole>(roles)
    ..active = active,
);

api.PlatformUser platformUserOf(
  String id,
  String? email, {
  List<api.PlatformUserMembership> memberships = const [],
}) => api.PlatformUser(
  (b) => b
    ..id = id
    ..email = email
    ..createdAt = DateTime.utc(2026, 10, 1)
    ..memberships = ListBuilder<api.PlatformUserMembership>(memberships),
);

api.UsageReport usageReport(String service, Map<String, int> counters) =>
    api.UsageReport(
      (b) => b
        ..tenantId = 'x'
        ..service = api.UsageReportServiceEnum.valueOf(service)
        ..collectedAt = DateTime.utc(2026, 11, 1)
        ..lastActivityAt = DateTime.utc(2026, 10, 30)
        ..counters = MapBuilder<String, int>(counters),
    );

api.TenantAdmin adminOf(
  String personId,
  String given,
  String family, {
  String? email,
  api.InvitationStatus status = api.InvitationStatus.ACCEPTED,
  Set<api.TenantRole> otherRoles = const {},
  api.TemporaryPasswordStatus temporaryPassword =
      api.TemporaryPasswordStatus.NONE,
}) => api.TenantAdmin(
  (b) => b
    ..personId = personId
    ..givenName = given
    ..familyName = family
    ..email = email ?? '${given.toLowerCase()}@example.org'
    ..invitationStatus = status
    ..temporaryPasswordStatus = temporaryPassword
    ..otherRoles = SetBuilder<api.TenantRole>(otherRoles),
);

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

  /// The administrators of the academy [tenantId].
  void seedAdmins(String tenantId, List<api.TenantAdmin> admins) =>
      platform.admins[tenantId] = [...admins.map(coreJson)];

  /// What the usage dashboard of [tenantId] reads.
  void seedUsage(String tenantId, api.TenantUsage usage) =>
      platform.usageOf[tenantId] = coreJson(usage);

  /// The usage trend of [tenantId] (from the first to the last snapshot).
  void seedUsageHistory(
    String tenantId,
    List<api.TenantUsageSnapshot> snapshots,
  ) => platform.historyOf[tenantId] = coreJson(
    api.TenantUsageHistory(
      (b) => b
        ..tenantId = tenantId
        ..from = snapshots.isEmpty
            ? api.Date(2026, 10, 1)
            : snapshots.first.date
        ..to = snapshots.isEmpty ? api.Date(2026, 11, 1) : snapshots.last.date
        ..snapshots.replace(snapshots),
    ),
  );

  /// Logins of the platform's user list (and e-mails that already sign in).
  void seedLogins(List<api.PlatformUser> users) =>
      platform.logins.addAll(users.map(coreJson));

  /// The academy [tenantId] as the mock holds it now.
  Map<String, Object?> tenantNow(String tenantId) =>
      platform.tenants.firstWhere((t) => t['id'] == tenantId);

  /// The administrator [personId] of [tenantId] as the mock holds it now.
  Map<String, Object?> adminNow(String tenantId, String personId) =>
      platform.admins[tenantId]!.firstWhere((a) => a['personId'] == personId);
}
