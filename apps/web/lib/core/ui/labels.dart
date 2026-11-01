import '../../features/me/domain/current_user.dart';
import '../../l10n/gen/app_localizations.dart';
import '../api/api.dart' as api;

/// Localised names for contract enums, shared by admin and roster screens.
extension TenantRoleLabel on api.TenantRole {
  String label(AppLocalizations l) {
    if (this == api.TenantRole.ADMIN) return l.roleAdmin;
    if (this == api.TenantRole.COACH) return l.roleCoach;
    if (this == api.TenantRole.ASSISTANT_COACH) return l.roleAssistantCoach;
    if (this == api.TenantRole.PARENT) return l.roleParent;
    if (this == api.TenantRole.PLAYER) return l.rolePlayer;
    return name;
  }
}

/// Roles an admin can grant (excludes the generator's fallback value).
const grantableRoles = [
  api.TenantRole.ADMIN,
  api.TenantRole.COACH,
  api.TenantRole.ASSISTANT_COACH,
  api.TenantRole.PARENT,
  api.TenantRole.PLAYER,
];

extension StaffRoleLabel on api.StaffRole {
  String label(AppLocalizations l) =>
      this == api.StaffRole.COACH ? l.roleCoach : l.roleAssistantCoach;
}

extension AgeRuleLabel on api.AgeRule {
  String label(AppLocalizations l) =>
      this == api.AgeRule.BIRTHDAY ? l.ageRuleBirthday : l.ageRuleBirthYear;
}

extension GenderPolicyLabel on api.GenderPolicy {
  String label(AppLocalizations l) {
    if (this == api.GenderPolicy.MALE) return l.genderPolicyMale;
    if (this == api.GenderPolicy.FEMALE) return l.genderPolicyFemale;
    return l.genderPolicyMixed;
  }
}

extension GenderLabel on api.Gender {
  String label(AppLocalizations l) =>
      this == api.Gender.FEMALE ? l.genderFemale : l.genderMale;
}

extension PlayerStatusLabel on api.PlayerStatus {
  String label(AppLocalizations l) {
    if (this == api.PlayerStatus.ACTIVE) return l.statusActive;
    if (this == api.PlayerStatus.ORPHAN) return l.statusOrphan;
    if (this == api.PlayerStatus.PENDING_APPROVAL) {
      return l.statusPendingApproval;
    }
    return l.statusWithdrawn;
  }
}

extension ApprovalStatusLabel on api.ApprovalStatus {
  String label(AppLocalizations l) {
    if (this == api.ApprovalStatus.PENDING) return l.approvalStatusPending;
    if (this == api.ApprovalStatus.APPROVED) return l.approvalStatusApproved;
    if (this == api.ApprovalStatus.REJECTED) return l.approvalStatusRejected;
    return l.approvalStatusCancelled;
  }
}

extension ApprovalActionLabel on api.ApprovalAction {
  String label(AppLocalizations l) => this == api.ApprovalAction.WITHDRAW_PLAYER
      ? l.approvalActionWithdraw
      : l.approvalActionAdd;
}

extension EligibilityReasonLabel on api.EligibilityReason {
  String label(AppLocalizations l) {
    if (this == api.EligibilityReason.CATEGORY_TOO_LOW) {
      return l.reasonCategoryTooLow;
    }
    if (this == api.EligibilityReason.PLAY_UP_LIMIT_EXCEEDED) {
      return l.reasonPlayUpLimit;
    }
    if (this == api.EligibilityReason.GENDER_POLICY) {
      return l.reasonGenderPolicy;
    }
    if (this == api.EligibilityReason.MISSING_BIRTH_DATE) {
      return l.reasonMissingBirthDate;
    }
    if (this == api.EligibilityReason.MISSING_GENDER) {
      return l.reasonMissingGender;
    }
    return l.reasonPlayerNotActive;
  }
}

/// Role-name list for the locale, e.g. for a member row.
String rolesText(Iterable<api.TenantRole> roles, AppLocalizations l) =>
    roles.map((r) => r.label(l)).join(', ');

TenantRole? domainRole(api.TenantRole r) {
  if (r == api.TenantRole.ADMIN) return TenantRole.admin;
  if (r == api.TenantRole.COACH) return TenantRole.coach;
  if (r == api.TenantRole.ASSISTANT_COACH) return TenantRole.assistantCoach;
  if (r == api.TenantRole.PARENT) return TenantRole.parent;
  if (r == api.TenantRole.PLAYER) return TenantRole.player;
  return null;
}

String formatDate(api.Date d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String formatAthDate(dynamic d) =>
    '${(d.year as int).toString().padLeft(4, '0')}-${(d.month as int).toString().padLeft(2, '0')}-${(d.day as int).toString().padLeft(2, '0')}';
