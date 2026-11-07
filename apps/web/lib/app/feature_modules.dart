import 'package:flutter/widgets.dart';

import '../core/navigation/destinations.dart';

// One deferred library per feature module: its code is only downloaded when
// the route is first opened. Real modules (WP12-WP14) keep this pattern:
// replace the screen import, keep `deferred as`.
import '../features/admin/presentation/academy_profile_screen.dart'
    deferred as admin_profile;
import '../features/admin/presentation/admin_screen.dart' deferred as admin;
import '../features/admin/presentation/age_categories_screen.dart'
    deferred as admin_categories;
import '../features/admin/presentation/members_screen.dart'
    deferred as admin_members;
import '../features/admin/presentation/seasons_screen.dart'
    deferred as admin_seasons;
import '../features/audit/presentation/audit_log_screen.dart' deferred as audit;
import '../features/match/presentation/live_match_screen.dart'
    deferred as match_live;
import '../features/match/presentation/match_setup_screen.dart'
    deferred as match_setup;
import '../features/match/presentation/matches_screen.dart' deferred as matches;
import '../features/match/presentation/season_stats_screen.dart'
    deferred as match_stats;
import '../features/health/presentation/fitness_screens.dart'
    deferred as fitness;
import '../features/health/presentation/player_health_view.dart'
    deferred as health;
import '../features/me/presentation/me_screen.dart' deferred as me;
import '../features/my_players/presentation/my_players_screen.dart'
    deferred as my_players;
import '../features/platform/presentation/platform_screen.dart'
    deferred as platform;
import '../features/platform/presentation/academy_requests_screen.dart'
    deferred as platform_requests
    show AcademyRequestsScreen;
import '../features/roster/presentation/approvals_screen.dart'
    deferred as approvals;
import '../features/roster/presentation/cases_screen.dart' deferred as cases;
import '../features/roster/presentation/players_screen.dart'
    deferred as players;
import '../features/roster/presentation/teams_screen.dart' deferred as teams;
import '../features/platform/presentation/tenant_detail_screen.dart'
    deferred as tenant_detail;
import '../features/training/presentation/absences_screen.dart'
    deferred as absences;
import '../features/training/presentation/assignments_screen.dart'
    deferred as assignments;
import '../features/training/presentation/plans_screen.dart' deferred as plans;
import '../features/training/presentation/schedules_screen.dart'
    deferred as schedules;
import '../features/training/presentation/session_screen.dart'
    deferred as session;
import '../features/training/presentation/training_screen.dart'
    deferred as training;

/// A lazily loaded feature screen behind a bottom-navigation destination.
class FeatureModule {
  const FeatureModule(this.load, this.build, {this.subPages = const []});

  /// `<prefix>.loadLibrary`
  final Future<void> Function() load;

  /// Constructs the screen; only valid after [load] completed.
  final Widget Function() build;

  /// Sub-routes below the destination path (`members/:id`), each with its
  /// own deferred library. Order matters: literal paths before `:param`.
  final List<ModulePage> subPages;
}

/// A page below a destination, e.g. `/admin/members/:personId`.
class ModulePage {
  const ModulePage(this.path, this.load, this.build);

  /// Relative path as in go_router (`members/:personId`).
  final String path;
  final Future<void> Function() load;
  final Widget Function(Map<String, String> params) build;
}

/// Every destination's module. This is the single place a feature plugs in.
final Map<AppDestination, FeatureModule> featureModules = {
  AppDestination.admin: FeatureModule(
    admin.loadLibrary,
    () => admin.AdminScreen(),
    subPages: [
      ModulePage(
        'profile',
        admin_profile.loadLibrary,
        (_) => admin_profile.AcademyProfileScreen(),
      ),
      ModulePage(
        'members',
        admin_members.loadLibrary,
        (_) => admin_members.MembersScreen(),
      ),
      ModulePage(
        'members/:personId',
        admin_members.loadLibrary,
        (p) => admin_members.MemberDetailScreen(personId: p['personId']!),
      ),
      ModulePage(
        'seasons',
        admin_seasons.loadLibrary,
        (_) => admin_seasons.SeasonsScreen(),
      ),
      ModulePage(
        'seasons/:seasonId/rollover',
        admin_seasons.loadLibrary,
        (p) => admin_seasons.RolloverScreen(seasonId: p['seasonId']!),
      ),
      ModulePage(
        'age-categories',
        admin_categories.loadLibrary,
        (_) => admin_categories.AgeCategoriesScreen(),
      ),
      ModulePage(
        'activity',
        audit.loadLibrary,
        (_) => audit.AcademyActivityScreen(),
      ),
    ],
  ),
  AppDestination.teams: FeatureModule(
    teams.loadLibrary,
    () => teams.TeamsScreen(),
    subPages: [
      ModulePage('cases', cases.loadLibrary, (_) => cases.CasesScreen()),
      ModulePage(
        ':teamId',
        teams.loadLibrary,
        (p) => teams.TeamDetailScreen(teamId: p['teamId']!),
      ),
    ],
  ),
  AppDestination.matches: FeatureModule(
    matches.loadLibrary,
    () => matches.MatchesScreen(),
    subPages: [
      // Season stats of a player; WP14 links Me / My players here.
      ModulePage(
        'stats/:playerId',
        match_stats.loadLibrary,
        (p) => match_stats.SeasonStatsScreen(playerId: p['playerId']!),
      ),
      ModulePage(
        ':matchId/setup',
        match_setup.loadLibrary,
        (p) => match_setup.MatchSetupScreen(matchId: p['matchId']!),
      ),
      ModulePage(
        ':matchId',
        match_live.loadLibrary,
        (p) => match_live.LiveMatchScreen(matchId: p['matchId']!),
      ),
    ],
  ),
  AppDestination.training: FeatureModule(
    training.loadLibrary,
    () => training.TrainingScreen(),
    subPages: [
      ModulePage(
        'session/:sessionId',
        session.loadLibrary,
        (p) => session.SessionDetailScreen(sessionId: p['sessionId']!),
      ),
      ModulePage(
        'schedules',
        schedules.loadLibrary,
        (_) => schedules.SchedulesScreen(),
      ),
      ModulePage(
        'absences',
        absences.loadLibrary,
        (_) => absences.AbsencesScreen(),
      ),
      ModulePage('plans', plans.loadLibrary, (_) => plans.PlanLibraryScreen()),
      ModulePage(
        'plans/:planId',
        plans.loadLibrary,
        (p) => plans.PlanEditorScreen(planId: p['planId']!),
      ),
      ModulePage(
        'assignments',
        assignments.loadLibrary,
        (_) => assignments.AssignmentsScreen(),
      ),
      ModulePage(
        'assignments/:assignmentId',
        assignments.loadLibrary,
        (p) => assignments.AssignmentProgressScreen(
          assignmentId: p['assignmentId']!,
        ),
      ),
    ],
  ),
  AppDestination.players: FeatureModule(
    players.loadLibrary,
    () => players.PlayersScreen(),
    subPages: [
      ModulePage(
        'requests',
        approvals.loadLibrary,
        (_) => approvals.ApprovalsScreen(),
      ),
      ModulePage('new', players.loadLibrary, (_) => players.PlayerFormScreen()),
      ModulePage(
        'tests',
        fitness.loadLibrary,
        (_) => fitness.TestTypesScreen(),
      ),
      ModulePage('norms', fitness.loadLibrary, (_) => fitness.NormsScreen()),
      ModulePage(
        ':playerId/health',
        health.loadLibrary,
        (p) => health.PlayerHealthScreen(playerId: p['playerId']!),
      ),
      ModulePage(
        ':playerId',
        players.loadLibrary,
        (p) => players.PlayerDetailScreen(playerId: p['playerId']!),
      ),
    ],
  ),
  AppDestination.myPlayers: FeatureModule(
    my_players.loadLibrary,
    () => my_players.MyPlayersScreen(),
  ),
  AppDestination.me: FeatureModule(me.loadLibrary, () => me.MePageScreen()),
  AppDestination.platform: FeatureModule(
    platform.loadLibrary,
    () => platform.PlatformScreen(),
    subPages: [
      ModulePage(
        'activity',
        audit.loadLibrary,
        (_) => audit.PlatformActivityScreen(),
      ),
      ModulePage(
        'requests',
        platform_requests.loadLibrary,
        (_) => platform_requests.AcademyRequestsScreen(),
      ),
      ModulePage(
        ':tenantId',
        tenant_detail.loadLibrary,
        (p) => tenant_detail.TenantDetailScreen(tenantId: p['tenantId']!),
      ),
      ModulePage(
        ':tenantId/activity',
        audit.loadLibrary,
        (p) => audit.PlatformActivityScreen(tenantId: p['tenantId']!),
      ),
    ],
  ),
};
