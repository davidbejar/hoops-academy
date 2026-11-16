import '../../../core/api/api.dart' as api;
import '../../../core/session/capabilities.dart';
import '../../me/domain/current_user.dart';

/// Who sees which part of the finance area (decision 96, the finance rows of
/// `docs/domain/authz-matrix.md`). UI affordances only: the service decides
/// every call again (a 403 is worded, never shown as a crash).
extension FinanceRights on Capabilities {
  /// Settings, plans, dues, payments, expenses, the balance and the exports:
  /// ADMIN.
  bool get canManageFinance => isAdmin;

  /// Who of the team is up to date, no amounts: the team's current COACH
  /// (not an ASSISTANT_COACH, not a former coach, not another team's coach).
  ///
  /// With the team's [staff] list at hand the person must also be listed there
  /// as COACH, so a COACH who is only the assistant of this team is not
  /// offered what the service refuses.
  bool canSeeTeamDueStatus(String teamId, {List<api.TeamStaffMember>? staff}) {
    if (!roles.contains(TenantRole.coach) || !isStaffOf(teamId)) return false;
    if (staff == null) return true;
    return staff.any(
      (s) => s.person.personId == personId && s.role == api.StaffRole.COACH,
    );
  }

  /// The dues and payments of a player: a PARENT linked to them, the PLAYER
  /// themself.
  bool canSeeFamilyDues(String playerId) =>
      isLinkedTo(playerId) || isSelf(playerId);
}
