import 'dart:typed_data';

import 'package:built_collection/built_collection.dart';

import '../../../core/api/api.dart' as api;
import '../domain/audit_entry.dart';

/// The audit trail: an academy's (`GET /api/core/audit-events`, ADMIN) and every academy's
/// (`GET /platform/audit-events`, super_admin).
abstract class AuditRepository {
  Future<AuditPage> academy(String tenantId, AuditQuery query);
  Future<AuditPage> platform(AuditQuery query, {String? tenantId});

  /// The server's CSV of everything the filters select, not one page (core 3.5.0); headers in [language].
  Future<Uint8List> exportAcademy(
    String tenantId,
    AuditQuery query, {
    required String language,
  });
  Future<Uint8List> exportPlatform(
    AuditQuery query, {
    String? tenantId,
    required String language,
  });
}

class ApiAuditRepository implements AuditRepository {
  ApiAuditRepository(api.HoopsCoreApi client)
    : _audit = client.getAuditApi(),
      _platform = client.getPlatformApi();

  final api.AuditApi _audit;
  final api.PlatformApi _platform;

  @override
  Future<AuditPage> academy(String tenantId, AuditQuery query) async {
    final page = (await _audit.listAuditEvents(
      xTenantId: tenantId,
      from: query.fromInstant,
      to: query.toInstant,
      action: _actions(query),
      page: query.page,
      size: AuditQuery.pageSize,
    )).data!;
    return _pageOf(page.page, [
      for (final e in page.items)
        _entry(e.id, e.at, e.action, e.actor, e.target),
    ]);
  }

  @override
  Future<AuditPage> platform(AuditQuery query, {String? tenantId}) async {
    final page = (await _platform.listPlatformAuditEvents(
      tenantId: tenantId,
      from: query.fromInstant,
      to: query.toInstant,
      action: _actions(query),
      page: query.page,
      size: AuditQuery.pageSize,
    )).data!;
    return _pageOf(page.page, [
      for (final e in page.items)
        _entry(
          e.id,
          e.at,
          e.action,
          e.actor,
          e.target,
          tenantId: e.tenantId,
          tenantName: e.tenantName,
        ),
    ]);
  }

  @override
  Future<Uint8List> exportAcademy(
    String tenantId,
    AuditQuery query, {
    required String language,
  }) async => (await _audit.exportAuditEvents(
    xTenantId: tenantId,
    from: query.fromInstant,
    to: query.toInstant,
    action: _actions(query),
    acceptLanguage: language,
  )).data!;

  @override
  Future<Uint8List> exportPlatform(
    AuditQuery query, {
    String? tenantId,
    required String language,
  }) async => (await _platform.exportPlatformAuditEvents(
    tenantId: tenantId,
    from: query.fromInstant,
    to: query.toInstant,
    action: _actions(query),
    acceptLanguage: language,
  )).data!;

  static BuiltList<api.AuditAction>? _actions(AuditQuery query) =>
      query.actions.isEmpty ? null : BuiltList<api.AuditAction>(query.actions);

  static AuditPage _pageOf(api.PageMeta meta, List<AuditEntry> items) =>
      AuditPage(
        items: items,
        page: meta.page,
        totalPages: meta.totalPages,
        totalElements: meta.totalElements,
      );

  static AuditEntry _entry(
    String id,
    DateTime at,
    api.AuditAction action,
    api.AuditActor actor,
    api.AuditTarget target, {
    String? tenantId,
    String? tenantName,
  }) => AuditEntry(
    id: id,
    at: at,
    action: action,
    actorKind: actor.kind,
    actorSubject: actor.subject,
    actorName: actor.displayName,
    targetType: target.type,
    targetId: target.id,
    targetName: target.displayName,
    tenantId: tenantId,
    tenantName: tenantName,
  );
}
