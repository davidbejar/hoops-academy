import 'package:material_ui/material_ui.dart';

import '../../features/me/domain/current_user.dart';

/// Top-level places reachable from the bottom navigation.
enum AppDestination {
  admin(
    '/admin',
    Icons.admin_panel_settings_outlined,
    Icons.admin_panel_settings,
  ),
  teams('/teams', Icons.groups_outlined, Icons.groups),
  matches(
    '/matches',
    Icons.sports_basketball_outlined,
    Icons.sports_basketball,
  ),
  training('/training', Icons.fitness_center_outlined, Icons.fitness_center),
  players('/players', Icons.person_search_outlined, Icons.person_search),
  myPlayers(
    '/my-players',
    Icons.family_restroom_outlined,
    Icons.family_restroom,
  ),
  me('/me', Icons.person_outline, Icons.person),
  appAdmin(
    '/app-admin',
    Icons.admin_panel_settings_outlined,
    Icons.admin_panel_settings,
  ),
  appAcademies(
    '/app-admin/academies',
    Icons.apartment_outlined,
    Icons.apartment,
  ),
  appUsers('/app-admin/users', Icons.people_outline, Icons.people),
  appRequests(
    '/app-admin/requests',
    Icons.mark_email_unread_outlined,
    Icons.mark_email_unread,
  ),
  appActivity('/app-admin/activity', Icons.history, Icons.history);

  const AppDestination(this.path, this.icon, this.selectedIcon);

  final String path;
  final IconData icon;
  final IconData selectedIcon;
}

/// Bottom-navigation destinations of the active context. In the application
/// admin of a super admin they are the hub's areas; in an academy they follow
/// the person's effective role. When a person holds several roles the highest
/// wins (ADMIN > COACH/ASSISTANT > PARENT > PLAYER); the server still
/// authorises every call.
List<AppDestination> destinationsFor({
  required Set<TenantRole> roles,
  required bool applicationAdmin,
}) {
  if (applicationAdmin) {
    return const [
      AppDestination.appAdmin,
      AppDestination.appAcademies,
      AppDestination.appUsers,
      AppDestination.appRequests,
      AppDestination.appActivity,
    ];
  }
  if (roles.contains(TenantRole.admin)) {
    return const [
      AppDestination.admin,
      AppDestination.teams,
      AppDestination.matches,
      AppDestination.training,
      AppDestination.players,
    ];
  }
  if (roles.contains(TenantRole.coach) ||
      roles.contains(TenantRole.assistantCoach)) {
    return const [
      AppDestination.teams,
      AppDestination.matches,
      AppDestination.training,
      AppDestination.players,
    ];
  }
  if (roles.contains(TenantRole.parent)) {
    return const [
      AppDestination.matches,
      AppDestination.training,
      AppDestination.myPlayers,
    ];
  }
  if (roles.contains(TenantRole.player)) {
    return const [
      AppDestination.matches,
      AppDestination.training,
      AppDestination.me,
    ];
  }
  return const [];
}

String homePathFor({
  required Set<TenantRole> roles,
  required bool applicationAdmin,
}) {
  final destinations = destinationsFor(
    roles: roles,
    applicationAdmin: applicationAdmin,
  );
  return destinations.isEmpty ? '/no-access' : destinations.first.path;
}
