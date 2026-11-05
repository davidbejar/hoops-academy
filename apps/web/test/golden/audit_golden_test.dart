import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoops_app/core/api/api.dart' as api;
import 'package:hoops_app/features/me/domain/current_user.dart';

import '../support/fake_audit.dart';
import '../support/fake_repos.dart';
import '../support/pump_helpers.dart';

/// Regenerate with `flutter test --update-goldens test/golden/audit_golden_test.dart`.
void main() {
  final trail = FakeAuditRepository([
    auditEntry('g1', api.AuditAction.memberPeriodInvited, at: DateTime.utc(2026, 11, 3, 9, 30),
        actorName: 'Ana Ruiz', targetName: 'Beatriz Soto Fernández'),
    auditEntry('g2', api.AuditAction.memberPeriodInvitationAccepted, at: DateTime.utc(2026, 11, 3, 8, 5),
        actorName: 'Beatriz Soto Fernández', targetName: 'Beatriz Soto Fernández'),
    auditEntry('g3', api.AuditAction.memberPeriodTemporaryPasswordExpired, at: DateTime.utc(2026, 11, 2, 23, 0),
        actorKind: api.AuditActorKind.SYSTEM, actorName: null, targetName: 'Leo Gil'),
    auditEntry('g4', api.AuditAction.playerPeriodApproved, at: DateTime.utc(2026, 11, 2, 17, 45),
        targetType: api.AuditTargetType.player, targetName: 'Leo Gil'),
    auditEntry('g5', api.AuditAction.adminPeriodAdded, at: DateTime.utc(2026, 11, 1, 12, 0),
        actorKind: api.AuditActorKind.PLATFORM, actorName: null, targetName: 'Ana Ruiz'),
    auditEntry('g6', api.AuditAction.tenantPeriodProfileChanged, at: DateTime.utc(2026, 10, 30, 10, 15),
        targetType: api.AuditTargetType.tenant, targetName: 'Club Norte'),
  ]);

  Future<void> pump(WidgetTester tester, Size size) => pumpAs(
    tester,
    roles: {TenantRole.admin},
    core: FakeCore(),
    location: '/admin/activity',
    size: size,
    overrides: trail.overrides,
  );

  testWidgets('academy activity, 360x780', (tester) async {
    await pump(tester, const Size(360, 780));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/audit_activity_360x780.png'));
  });

  testWidgets('academy activity, 1024x768', (tester) async {
    await pump(tester, const Size(1024, 768));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/audit_activity_1024x768.png'));
  });
}
