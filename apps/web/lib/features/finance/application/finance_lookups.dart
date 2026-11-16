import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart' as api;
import '../../admin/application/admin_providers.dart';
import '../../roster/application/roster_providers.dart';

/// The names the finance screens put on ids: seasons, age categories and the
/// teams of every season (a plan, or a due of an earlier season, may belong
/// to any of them).
class FinanceLookups {
  const FinanceLookups({
    required this.seasons,
    required this.categories,
    required this.teams,
  });

  final List<api.Season> seasons;
  final List<api.AgeCategory> categories;
  final List<api.Team> teams;

  api.Season? season(String? id) =>
      seasons.where((s) => s.id == id).firstOrNull;

  /// The season in use: the current one, else the newest.
  api.Season? get defaultSeason =>
      seasons.where((s) => s.current).firstOrNull ?? seasons.lastOrNull;

  String? seasonName(String? id) => season(id)?.name;

  String? teamName(String? id) =>
      teams.where((t) => t.id == id).firstOrNull?.name;

  String? categoryName(String? id) =>
      categories.where((c) => c.id == id).firstOrNull?.name;

  List<api.Team> teamsOfSeason(String seasonId) => [
    for (final t in teams)
      if (t.seasonId == seasonId) t,
  ];
}

final financeLookupsProvider = FutureProvider<FinanceLookups>((ref) async {
  final seasons = await ref.watch(seasonsProvider.future);
  final categories = await ref.watch(ageCategoriesProvider.future);
  final repo = ref.watch(teamsRepositoryProvider);
  return FinanceLookups(
    seasons: seasons,
    categories: categories,
    teams: [for (final s in seasons) ...await repo.list(seasonId: s.id)],
  );
});
