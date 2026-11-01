import 'package:flutter/widgets.dart';

import '../core/navigation/destinations.dart';

// One deferred library per feature module: its code is only downloaded when
// the route is first opened. Real modules (WP12-WP14) keep this pattern:
// replace the screen import, keep `deferred as`.
import '../features/admin/presentation/admin_screen.dart' deferred as admin;
import '../features/matches/presentation/matches_screen.dart' deferred as matches;
import '../features/me/presentation/me_screen.dart' deferred as me;
import '../features/my_players/presentation/my_players_screen.dart' deferred as my_players;
import '../features/platform/presentation/platform_screen.dart' deferred as platform;
import '../features/players/presentation/players_screen.dart' deferred as players;
import '../features/teams/presentation/teams_screen.dart' deferred as teams;
import '../features/training/presentation/training_screen.dart' deferred as training;

/// A lazily loaded feature screen behind a bottom-navigation destination.
class FeatureModule {
  const FeatureModule(this.load, this.build);

  /// `<prefix>.loadLibrary`
  final Future<void> Function() load;

  /// Constructs the screen; only valid after [load] completed.
  final Widget Function() build;
}

/// Every destination's module. This is the single place a feature plugs in.
final Map<AppDestination, FeatureModule> featureModules = {
  AppDestination.admin: FeatureModule(admin.loadLibrary, () => admin.AdminScreen()),
  AppDestination.teams: FeatureModule(teams.loadLibrary, () => teams.TeamsScreen()),
  AppDestination.matches: FeatureModule(matches.loadLibrary, () => matches.MatchesScreen()),
  AppDestination.training: FeatureModule(training.loadLibrary, () => training.TrainingScreen()),
  AppDestination.players: FeatureModule(players.loadLibrary, () => players.PlayersScreen()),
  AppDestination.myPlayers: FeatureModule(my_players.loadLibrary, () => my_players.MyPlayersScreen()),
  AppDestination.me: FeatureModule(me.loadLibrary, () => me.MePageScreen()),
  AppDestination.platform: FeatureModule(platform.loadLibrary, () => platform.PlatformScreen()),
};
