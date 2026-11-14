import '../../../core/session/capabilities.dart';
import '../../me/domain/current_user.dart';

/// Who writes a player's preferred number: ADMIN, COACH, a linked PARENT and the PLAYER himself (core 3.5.0); an
/// ASSISTANT_COACH only reads it.
extension PreferredJerseyRights on Capabilities {
  bool get _staffWriter =>
      roles.contains(TenantRole.admin) || roles.contains(TenantRole.coach);

  bool canSetPreferredJersey(String playerId) =>
      _staffWriter || isLinkedTo(playerId) || isSelf(playerId);

  /// Parents and players word it as a wish: the coach decides.
  bool isJerseyWish(String playerId) =>
      !_staffWriter && (isLinkedTo(playerId) || isSelf(playerId));
}

/// The roster export (core 3.6.0, decision 83): ADMIN (ended seasons too) and the team's current COACH. A former
/// coach of an ended season, an assistant coach, a parent and a player get 403, so the button is not offered.
extension RosterExportRights on Capabilities {
  bool canExportRoster(String teamId) =>
      roles.contains(TenantRole.admin) ||
      (roles.contains(TenantRole.coach) && isStaffOf(teamId));
}
