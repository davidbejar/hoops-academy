import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/audit/application/audit_providers.dart';
import 'package:hoops_app/features/audit/data/audit_repository.dart';
import 'package:hoops_app/features/audit/domain/audit_entry.dart';

import 'fake_repos.dart' show Faulty;

AuditEntry auditEntry(
  String id,
  api.AuditAction action, {
  DateTime? at,
  api.AuditActorKind actorKind = api.AuditActorKind.PERSON,
  String? actorSubject = 'sub',
  String? actorName = 'Ana Ruiz',
  api.AuditTargetType targetType = api.AuditTargetType.person,
  String? targetName = 'Leo Gil',
  String? tenantId,
  String? tenantName,
}) => AuditEntry(
  id: id,
  at: at ?? DateTime.utc(2026, 11, 3, 9, 30),
  action: action,
  actorKind: actorKind,
  actorSubject: actorSubject,
  actorName: actorName,
  targetType: targetType,
  targetId: 'target-$id',
  targetName: targetName,
  tenantId: tenantId,
  tenantName: tenantName,
);

/// In-memory audit trail: pages [entries] by the query's page and size, filters by action, records every query.
class FakeAuditRepository with Faulty implements AuditRepository {
  FakeAuditRepository([List<AuditEntry>? entries]) : entries = entries ?? [];

  final List<AuditEntry> entries;
  final List<(String?, AuditQuery)> academyQueries = [];
  final List<(String?, AuditQuery)> platformQueries = [];

  AuditPage _page(AuditQuery q) {
    final matching = [
      for (final e in entries)
        if (q.actions.isEmpty || q.actions.contains(e.action)) e,
    ];
    final start = q.page * AuditQuery.pageSize;
    final items = matching.skip(start).take(AuditQuery.pageSize).toList();
    final pages = (matching.length + AuditQuery.pageSize - 1) ~/ AuditQuery.pageSize;
    return AuditPage(items: items, page: q.page, totalPages: pages, totalElements: matching.length);
  }

  @override
  Future<AuditPage> academy(String tenantId, AuditQuery query) => run('academy', () {
    academyQueries.add((tenantId, query));
    return _page(query);
  });

  @override
  Future<AuditPage> platform(AuditQuery query, {String? tenantId}) => run('platform', () {
    platformQueries.add((tenantId, query));
    return _page(query);
  });

  List<Override> get overrides => [auditRepositoryProvider.overrideWithValue(this)];
}
