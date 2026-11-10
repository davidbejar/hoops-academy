import '../../l10n/gen/app_localizations.dart';
import '../../features/me/domain/current_user.dart';
import 'destinations.dart';

extension DestinationLabel on AppDestination {
  String label(AppLocalizations l) => switch (this) {
    AppDestination.admin => l.navAdmin,
    AppDestination.teams => l.navTeams,
    AppDestination.matches => l.navMatches,
    AppDestination.training => l.navTraining,
    AppDestination.players => l.navPlayers,
    AppDestination.myPlayers => l.navMyPlayers,
    AppDestination.me => l.navMe,
    AppDestination.appAdmin => l.navAppHub,
    AppDestination.appAcademies => l.navAppAcademies,
    AppDestination.appUsers => l.navAppUsers,
    AppDestination.appRequests => l.navAppRequests,
    AppDestination.appActivity => l.navAppActivity,
  };
}

extension TenantRoleLabel on TenantRole {
  String label(AppLocalizations l) => switch (this) {
    TenantRole.admin => l.roleAdmin,
    TenantRole.coach => l.roleCoach,
    TenantRole.assistantCoach => l.roleAssistantCoach,
    TenantRole.parent => l.roleParent,
    TenantRole.player => l.rolePlayer,
  };
}
