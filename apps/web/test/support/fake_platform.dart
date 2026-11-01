import 'package:built_collection/built_collection.dart';
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

class FakePlatformRepository with Faulty implements PlatformRepository {
  FakePlatformRepository({List<api.Tenant>? tenants, this.usageResult, this.usageFails = false}) : list = tenants ?? [];

  final List<api.Tenant> list;
  api.TenantUsage? usageResult;
  bool usageFails;
  api.CreateTenantRequest? created;
  String? lastReason;
  api.TenantStatus? lastStatusFilter;
  String? lastQuery;

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
  Future<api.Tenant> create(api.CreateTenantRequest request) => run('create', () {
    created = request;
    final t = tenantOf('new-${list.length}', request.name, slug: request.slug);
    list.add(t);
    return t;
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
}

class FakePlatform {
  FakePlatform({FakePlatformRepository? repo}) : repo = repo ?? FakePlatformRepository();
  final FakePlatformRepository repo;
  List<Override> get overrides => [platformRepositoryProvider.overrideWithValue(repo)];
}
