import 'package:flutter/widgets.dart';

import '../core/navigation/destinations.dart';

// One deferred library per feature module: its code is only downloaded when
// the route is first opened. Real modules (WP12-WP14) keep this pattern:
// replace the screen import, keep `deferred as`.
import '../features/admin/presentation/academy_profile_screen.dart' deferred as admin_profile;
import '../features/admin/presentation/admin_screen.dart' deferred as admin;
import '../features/admin/presentation/age_categories_screen.dart' deferred as admin_categories;
import '../features/admin/presentation/members_screen.dart' deferred as admin_members;
import '../features/admin/presentation/seasons_screen.dart' deferred as admin_seasons;
import '../features/matches/presentation/matches_screen.dart' deferred as matches;
import '../features/me/presentation/me_screen.dart' deferred as me;
import '../features/my_players/presentation/my_players_screen.dart' deferred as my_players;
import '../features/platform/presentation/platform_screen.dart' deferred as platform;
import '../features/roster/presentation/approvals_screen.dart' deferred as approvals;
import '../features/roster/presentation/cases_screen.dart' deferred as cases;
import '../features/roster/presentation/players_screen.dart' deferred as players;
import '../features/roster/presentation/teams_screen.dart' deferred as teams;
import '../features/training/presentation/training_screen.dart' deferred as training;

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
      ModulePage('profile', admin_profile.loadLibrary, (_) => admin_profile.AcademyProfileScreen()),
      ModulePage('members', admin_members.loadLibrary, (_) => admin_members.MembersScreen()),
      ModulePage(
        'members/:personId',
        admin_members.loadLibrary,
        (p) => admin_members.MemberDetailScreen(personId: p['personId']!),
      ),
      ModulePage('seasons', admin_seasons.loadLibrary, (_) => admin_seasons.SeasonsScreen()),
      ModulePage(
        'seasons/:seasonId/rollover',
        admin_seasons.loadLibrary,
        (p) => admin_seasons.RolloverScreen(seasonId: p['seasonId']!),
      ),
      ModulePage('age-categories', admin_categories.loadLibrary, (_) => admin_categories.AgeCategoriesScreen()),
    ],
  ),
  AppDestination.teams: FeatureModule(
    teams.loadLibrary,
    () => teams.TeamsScreen(),
    subPages: [
      ModulePage('cases', cases.loadLibrary, (_) => cases.CasesScreen()),
      ModulePage(':teamId', teams.loadLibrary, (p) => teams.TeamDetailScreen(teamId: p['teamId']!)),
    ],
  ),
  AppDestination.matches: FeatureModule(matches.loadLibrary, () => matches.MatchesScreen()),
  AppDestination.training: FeatureModule(training.loadLibrary, () => training.TrainingScreen()),
  AppDestination.players: FeatureModule(
    players.loadLibrary,
    () => players.PlayersScreen(),
    subPages: [
      ModulePage('requests', approvals.loadLibrary, (_) => approvals.ApprovalsScreen()),
      ModulePage('new', players.loadLibrary, (_) => players.PlayerFormScreen()),
      ModulePage(':playerId', players.loadLibrary, (p) => players.PlayerDetailScreen(playerId: p['playerId']!)),
    ],
  ),
  AppDestination.myPlayers: FeatureModule(my_players.loadLibrary, () => my_players.MyPlayersScreen()),
  AppDestination.me: FeatureModule(me.loadLibrary, () => me.MePageScreen()),
  AppDestination.platform: FeatureModule(platform.loadLibrary, () => platform.PlatformScreen()),
};
