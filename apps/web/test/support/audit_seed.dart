import 'package:built_value/serializer.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/audit/domain/audit_entry.dart';

import 'mock_backend.dart';

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

String _wire<T>(T value) =>
    api.serializers.serialize(value, specifiedType: FullType(T))! as String;

/// [e] as the services send it: an `AuditEvent`, a `PlatformAuditEvent` when
/// it names its academy.
Map<String, Object?> auditEventJson(AuditEntry e) => {
  'id': e.id,
  'at': e.at.toUtc().toIso8601String(),
  'action': _wire(e.action),
  'actor': {
    'kind': _wire(e.actorKind),
    'subject': e.actorSubject,
    'personId': null,
    'displayName': e.actorName,
  },
  'target': {
    'type': _wire(e.targetType),
    'id': e.targetId,
    'displayName': e.targetName,
  },
  'metadata': <String, Object?>{},
  if (e.tenantId != null) ...{
    'tenantId': e.tenantId,
    'tenantName': e.tenantName,
  },
};

/// Seeds the audit trails of the backend, newest first.
extension AuditSeed on MockBackend {
  /// The trail of the test academy (`GET /api/core/audit-events`).
  void seedAcademyTrail(List<AuditEntry> entries) =>
      core.auditEvents.addAll(entries.map(auditEventJson));

  /// The trail of every academy (`GET /platform/audit-events`); each entry
  /// names an academy the platform knows (seed it with `tenants`).
  void seedPlatformTrail(List<AuditEntry> entries) =>
      platform.auditEvents.addAll(entries.map(auditEventJson));
}
