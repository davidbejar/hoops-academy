import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/platform/application/platform_providers.dart';
import 'package:hoops_app/features/platform/data/platform_repository.dart';

import 'fake_repos.dart' show Faulty;

api.Tenant tenantOf(String id, String name, {String? slug, api.TenantStatus status = api.TenantStatus.ACTIVE}) => api.Tenant(
  (b) => b
    ..id = id
    ..slug = slug ?? name.toLowerCase().replaceAll(' ', '-')
    ..name = name
    ..status = status
    ..timezone = 'Europe/Madrid'
    ..defaultLocale = api.ApiLocale.es
    ..createdAt = DateTime.utc(2026, 1, 5),
);

api.UsageReport usageReport(String service, Map<String, int> counters) => api.UsageReport(
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
  api.TemporaryPasswordStatus temporaryPassword = api.TemporaryPasswordStatus.NONE,
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

/// A Problem+JSON failure as the Dio layer throws it (`code` is the machine-readable business code).
DioException problem(int status, String code) {
  final request = RequestOptions(path: '/platform');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: request,
      statusCode: status,
      data: {'status': status, 'code': code, 'detail': 'English server detail that must never be shown'},
    ),
  );
}

class FakePlatformRepository with Faulty implements PlatformRepository {
  FakePlatformRepository({List<api.Tenant>? tenants, this.usageResult, this.usageFails = false, Map<String, List<api.TenantAdmin>>? admins})
    : list = tenants ?? [],
      adminsOf = admins ?? {};

  final List<api.Tenant> list;
  api.TenantUsage? usageResult;
  bool usageFails;
  /// Snapshots returned by `usageHistory` (empty by default).
  List<api.TenantUsageSnapshot> history = [];
  bool historyFails = false;
  api.CreateTenantRequest? created;
  String? lastReason;
  api.TenantStatus? lastStatusFilter;
  String? lastQuery;

  /// Administrators per tenant id.
  final Map<String, List<api.TenantAdmin>> adminsOf;

  /// Holds `admins()` until completed (loading state) / makes only the list fail (the tenant still loads).
  Completer<void>? adminsGate;
  Object? adminsListFails;

  /// Thrown by add/update/remove/resend only (the list keeps working), e.g. `problem(409, 'LAST_ADMIN')`.
  Object? adminMutationFails;
  api.AddTenantAdminRequest? addedAdmin;
  api.UpdateTenantAdminRequest? updatedAdmin;
  String? updatedAdminId;
  final List<String> removedAdmins = [];

  /// What the server returns for a login it creates (null: the person already had a login).
  String? newLoginPassword = 'test-temp-password-1';

  /// What a re-issue returns; each call hands out the next one (`Reissued-1`, ...).
  String reissuedPrefix = 'Reissued-';
  final List<String> reissuedFor = [];

  int _i(String id) => list.indexWhere((t) => t.id == id);

  @override
  Future<List<api.Tenant>> tenants({api.TenantStatus? status, String? query}) => run('tenants', () {
    lastStatusFilter = status;
    lastQuery = query;
    return [
      for (final t in list)
        if ((status == null || t.status == status) &&
            (query == null || t.name.toLowerCase().contains(query.toLowerCase()) || t.slug.contains(query.toLowerCase())))
          t,
    ];
  });

  @override
  Future<api.Tenant> tenant(String tenantId) => run('tenant', () => list[_i(tenantId)]);

  @override
  Future<api.TenantWithPassword> create(api.CreateTenantRequest request) => run('create', () {
    created = request;
    final t = tenantOf('new-${list.length}', request.name, slug: request.slug);
    list.add(t);
    return api.TenantWithPassword(
      (b) => b
        ..id = t.id
        ..slug = t.slug
        ..name = t.name
        ..status = t.status
        ..timezone = t.timezone
        ..defaultLocale = t.defaultLocale
        ..createdAt = t.createdAt
        ..temporaryPassword = newLoginPassword,
    );
  });

  api.Tenant _set(String id, api.TenantStatus s) {
    list[_i(id)] = list[_i(id)].rebuild((b) => b.status = s);
    return list[_i(id)];
  }

  @override
  Future<api.Tenant> suspend(String tenantId, String reason) => run('suspend', () {
    lastReason = reason;
    return _set(tenantId, api.TenantStatus.SUSPENDED);
  });

  @override
  Future<api.Tenant> withdraw(String tenantId, String reason) => run('withdraw', () {
    lastReason = reason;
    return _set(tenantId, api.TenantStatus.WITHDRAWN);
  });

  @override
  Future<api.Tenant> reactivate(String tenantId) => run('reactivate', () => _set(tenantId, api.TenantStatus.ACTIVE));

  @override
  Future<api.TenantUsage> usage(String tenantId) => run('usage', () {
    if (usageFails) throw StateError('usage down');
    return usageResult ??
        api.TenantUsage(
          (b) => b
            ..tenantId = tenantId
            ..collectedAt = DateTime.utc(2026, 11, 1),
        );
  });
  @override
  Future<api.TenantUsageHistory> usageHistory(String tenantId) => run('usageHistory', () {
    if (historyFails) throw StateError('history down');
    return api.TenantUsageHistory(
      (b) => b
        ..tenantId = tenantId
        ..from = api.Date(2026, 10, 1)
        ..to = api.Date(2026, 11, 1)
        ..snapshots.replace(history),
    );
  });

  List<api.TenantAdmin> _admins(String tenantId) => adminsOf.putIfAbsent(tenantId, () => []);

  api.Tenant _manageable(String tenantId) {
    final t = list[_i(tenantId)];
    if (t.status == api.TenantStatus.WITHDRAWN) throw problem(409, 'TENANT_WITHDRAWN');
    return t;
  }

  @override
  Future<List<api.TenantAdmin>> admins(String tenantId) async {
    await adminsGate?.future;
    if (adminsListFails != null) throw adminsListFails!;
    return run('admins', () {
      _manageable(tenantId);
      return List.of(_admins(tenantId));
    });
  }

  @override
  Future<api.TenantAdminWithPassword> addAdmin(String tenantId, api.AddTenantAdminRequest request) => run('addAdmin', () {
    if (adminMutationFails != null) throw adminMutationFails!;
    _manageable(tenantId);
    addedAdmin = request;
    final admin = adminOf(
      'new-${_admins(tenantId).length}',
      request.givenName,
      request.familyName,
      email: request.email,
      status: newLoginPassword == null ? api.InvitationStatus.ACCEPTED : api.InvitationStatus.PENDING,
    );
    _admins(tenantId).add(admin);
    return _withPassword(admin, newLoginPassword);
  });

  api.TenantAdminWithPassword _withPassword(api.TenantAdmin a, String? password) => api.TenantAdminWithPassword(
    (b) => b
      ..personId = a.personId
      ..givenName = a.givenName
      ..familyName = a.familyName
      ..email = a.email
      ..invitationStatus = a.invitationStatus
      ..temporaryPasswordStatus = a.temporaryPasswordStatus
      ..otherRoles = SetBuilder<api.TenantRole>(a.otherRoles)
      ..temporaryPassword = password,
  );

  @override
  Future<api.TenantAdmin> updateAdmin(String tenantId, String personId, api.UpdateTenantAdminRequest request) =>
      run('updateAdmin', () {
        if (adminMutationFails != null) throw adminMutationFails!;
        _manageable(tenantId);
        updatedAdmin = request;
        updatedAdminId = personId;
        final admins = _admins(tenantId);
        final i = admins.indexWhere((a) => a.personId == personId);
        admins[i] = admins[i].rebuild(
          (b) => b
            ..givenName = request.givenName ?? admins[i].givenName
            ..familyName = request.familyName ?? admins[i].familyName
            ..email = request.email ?? admins[i].email,
        );
        return admins[i];
      });

  @override
  Future<void> removeAdmin(String tenantId, String personId) => run('removeAdmin', () {
    if (adminMutationFails != null) throw adminMutationFails!;
    _manageable(tenantId);
    final admins = _admins(tenantId);
    if (admins.length == 1) throw problem(409, 'LAST_ADMIN');
    removedAdmins.add(personId);
    admins.removeWhere((a) => a.personId == personId);
  });

  @override
  Future<api.TenantAdminWithPassword> issueAdminTemporaryPassword(String tenantId, String personId) =>
      run('issueAdminTemporaryPassword', () {
        if (adminMutationFails != null) throw adminMutationFails!;
        _manageable(tenantId);
        final admin = _admins(tenantId).firstWhere((a) => a.personId == personId);
        if (admin.invitationStatus != api.InvitationStatus.PENDING) throw problem(409, 'INVITATION_NOT_PENDING');
        reissuedFor.add(personId);
        final renewed = admin.rebuild((b) => b..temporaryPasswordStatus = api.TemporaryPasswordStatus.ACTIVE);
        final admins = _admins(tenantId);
        admins[admins.indexOf(admin)] = renewed;
        return _withPassword(renewed, '$reissuedPrefix${reissuedFor.length}');
      });
}

class FakePlatform {
  FakePlatform({FakePlatformRepository? repo}) : repo = repo ?? FakePlatformRepository();
  final FakePlatformRepository repo;
  List<Override> get overrides => [platformRepositoryProvider.overrideWithValue(repo)];
}
