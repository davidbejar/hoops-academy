import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/export/export_context.dart';
import '../../../core/export/export_runner.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../roster/application/roster_providers.dart';
import '../../tenant/application/tenant_providers.dart';
import '../../training/application/training_providers.dart';
import '../application/live_match_controller.dart';
import 'match_exports.dart';
import 'season_stats_screen.dart';

/// What the season statistics screen exports: the stats it shows, for the
/// player's name (when the caller may read it) in the file and the sheet.
Future<ExportJob> prepareStatsExport(
  WidgetRef ref,
  AppLocalizations l, {
  required String playerId,
  required String seasonId,
}) async {
  final stats = await ref.read(
    seasonStatsProvider((playerId, seasonId)).future,
  );
  if (stats.gamesPlayed == 0 && stats.matches.isEmpty) {
    throw const NothingToExport();
  }
  String? name;
  try {
    name = (await ref.read(playerDetailProvider(playerId).future)).displayName;
  } on Object {
    name = null; // a role that may not read the player still gets the numbers
  }
  return ExportJob(
    slug: ref.read(academySlugProvider),
    what: name == null ? 'player-stats' : 'player-stats-$name',
    day: exportDay(ref),
    table: playerStatsTable(
      l,
      stats,
      zone: ref.read(tenantZoneProvider),
      playerName: name,
    ),
  );
}

/// The box score of [live] as the caller may see it (a parent or player: the
/// lines of their own / linked players; the totals are the server's).
ExportJob boxScoreJob(WidgetRef ref, AppLocalizations l, LiveMatch live) {
  final names = ref.read(teamNamesProvider);
  final lines = <BoxScoreLine>[
    for (final line in live.projection.playerStats)
      if (live.rights.canSeeLine(line.playerId))
        BoxScoreLine(
          name: live.player(line.playerId)?.displayName ?? line.playerId,
          jersey: live.player(line.playerId)?.jerseyNumber,
          starter: line.wasStarter,
          stats: line.stats,
        ),
  ];
  return ExportJob(
    slug: ref.read(academySlugProvider),
    what: 'box-score-vs-${live.match.opponentName}',
    day: exportDay(ref),
    table: boxScoreTable(
      l,
      BoxScoreExport(
        teamName: names[live.match.teamId] ?? l.matchUs,
        opponentName: live.match.opponentName,
        lines: lines,
        totals: live.team.teamTotals,
        teamScore: live.team.teamScore,
        opponentScore: live.team.opponentScore,
      ),
    ),
  );
}
