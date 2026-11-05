import 'package:built_value/serializer.dart' show FullType;

import '../../../core/api/api.dart' as api;
import '../../../l10n/gen/app_localizations.dart';

/// Every action the server records (the generated enum's fallback for unknown values excluded).
final List<api.AuditAction> auditActions = [
  for (final a in api.AuditAction.values)
    if (a != api.AuditAction.unknownDefaultOpenApi) a,
];

extension AuditActionLabel on api.AuditAction {
  /// One localized label per action; an action this build does not know yet shows its wire name.
  String label(AppLocalizations l) => switch (this) {
    api.AuditAction.adminPeriodAdded => l.auditActionAdminAdded,
    api.AuditAction.adminPeriodRemoved => l.auditActionAdminRemoved,
    api.AuditAction.adminPeriodTemporaryPasswordIssued => l.auditActionAdminTemporaryPasswordIssued,
    api.AuditAction.adminPeriodUpdated => l.auditActionAdminUpdated,
    api.AuditAction.approvalPeriodCancelled => l.auditActionApprovalCancelled,
    api.AuditAction.guardianLinkPeriodCreated => l.auditActionGuardianLinkCreated,
    api.AuditAction.guardianLinkPeriodRemoved => l.auditActionGuardianLinkRemoved,
    api.AuditAction.memberPeriodDeactivated => l.auditActionMemberDeactivated,
    api.AuditAction.memberPeriodInvitationAccepted => l.auditActionMemberInvitationAccepted,
    api.AuditAction.memberPeriodInvited => l.auditActionMemberInvited,
    api.AuditAction.memberPeriodLoginEmailChanged => l.auditActionMemberLoginEmailChanged,
    api.AuditAction.memberPeriodRolesReplaced => l.auditActionMemberRolesReplaced,
    api.AuditAction.memberPeriodTemporaryPasswordExpired => l.auditActionMemberTemporaryPasswordExpired,
    api.AuditAction.memberPeriodTemporaryPasswordIssued => l.auditActionMemberTemporaryPasswordIssued,
    api.AuditAction.memberPeriodUpdated => l.auditActionMemberUpdated,
    api.AuditAction.playerPeriodApproved => l.auditActionPlayerApproved,
    api.AuditAction.playerPeriodRejected => l.auditActionPlayerRejected,
    api.AuditAction.playerPeriodRequested => l.auditActionPlayerRequested,
    api.AuditAction.playerPeriodWithdrawn => l.auditActionPlayerWithdrawn,
    api.AuditAction.tenantPeriodCreated => l.auditActionTenantCreated,
    api.AuditAction.tenantPeriodLogoRemoved => l.auditActionTenantLogoRemoved,
    api.AuditAction.tenantPeriodLogoReplaced => l.auditActionTenantLogoReplaced,
    api.AuditAction.tenantPeriodMasterDataChanged => l.auditActionTenantMasterDataChanged,
    api.AuditAction.tenantPeriodProfileChanged => l.auditActionTenantProfileChanged,
    api.AuditAction.tenantPeriodReactivated => l.auditActionTenantReactivated,
    api.AuditAction.tenantPeriodSettingsChanged => l.auditActionTenantSettingsChanged,
    api.AuditAction.tenantPeriodSuspended => l.auditActionTenantSuspended,
    api.AuditAction.tenantPeriodWithdrawn => l.auditActionTenantWithdrawn,
    _ => name,
  };
}

extension AuditTargetTypeLabel on api.AuditTargetType {
  /// Shown when the target has no resolved name.
  String label(AppLocalizations l) => switch (this) {
    api.AuditTargetType.person => l.auditTargetPerson,
    api.AuditTargetType.player => l.auditTargetPlayer,
    api.AuditTargetType.tenant => l.auditTargetTenant,
    api.AuditTargetType.approvalRequest => l.auditTargetApprovalRequest,
    api.AuditTargetType.guardianLink => l.auditTargetGuardianLink,
    _ => name,
  };
}

extension AuditActorKindLabel on api.AuditActorKind {
  /// Shown when the actor has no resolved name.
  String label(AppLocalizations l) => switch (this) {
    api.AuditActorKind.SYSTEM => l.auditActorSystem,
    api.AuditActorKind.PLATFORM => l.auditActorPlatform,
    _ => l.auditActorMember,
  };
}

/// The action's name on the wire (`member.invited`), e.g. for stable widget keys.
String auditWireName(api.AuditAction action) =>
    api.serializers.serialize(action, specifiedType: const FullType(api.AuditAction))! as String;
