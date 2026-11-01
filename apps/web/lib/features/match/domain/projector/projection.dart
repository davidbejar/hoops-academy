/// Result types of the box-score projection (mirror of game-service
/// `domain.projection`).
library;

/// Counting statistics of a player or team. fg1 = free throws.
/// [personalFouls] counts every foul; technical / unsportsmanlike are also
/// counted on their own.
class StatLine {
  const StatLine({
    this.points = 0,
    this.fg1Made = 0,
    this.fg1Attempted = 0,
    this.fg2Made = 0,
    this.fg2Attempted = 0,
    this.fg3Made = 0,
    this.fg3Attempted = 0,
    this.assists = 0,
    this.offensiveRebounds = 0,
    this.defensiveRebounds = 0,
    this.turnovers = 0,
    this.steals = 0,
    this.blocks = 0,
    this.personalFouls = 0,
    this.technicalFouls = 0,
    this.unsportsmanlikeFouls = 0,
    this.secondsPlayed = 0,
  });

  static const zero = StatLine();

  final int points;
  final int fg1Made, fg1Attempted, fg2Made, fg2Attempted, fg3Made, fg3Attempted;
  final int assists, offensiveRebounds, defensiveRebounds, turnovers, steals, blocks;
  final int personalFouls, technicalFouls, unsportsmanlikeFouls;
  final int secondsPlayed;

  int get rebounds => offensiveRebounds + defensiveRebounds;

  /// Field goals (2 + 3 points).
  int get fgMade => fg2Made + fg3Made;
  int get fgAttempted => fg2Attempted + fg3Attempted;

  StatLine operator +(StatLine o) => StatLine(
    points: points + o.points,
    fg1Made: fg1Made + o.fg1Made,
    fg1Attempted: fg1Attempted + o.fg1Attempted,
    fg2Made: fg2Made + o.fg2Made,
    fg2Attempted: fg2Attempted + o.fg2Attempted,
    fg3Made: fg3Made + o.fg3Made,
    fg3Attempted: fg3Attempted + o.fg3Attempted,
    assists: assists + o.assists,
    offensiveRebounds: offensiveRebounds + o.offensiveRebounds,
    defensiveRebounds: defensiveRebounds + o.defensiveRebounds,
    turnovers: turnovers + o.turnovers,
    steals: steals + o.steals,
    blocks: blocks + o.blocks,
    personalFouls: personalFouls + o.personalFouls,
    technicalFouls: technicalFouls + o.technicalFouls,
    unsportsmanlikeFouls: unsportsmanlikeFouls + o.unsportsmanlikeFouls,
    secondsPlayed: secondsPlayed + o.secondsPlayed,
  );
}

/// Inconsistencies the projector reports (open set on the wire).
abstract final class WarningCode {
  static const subInPlayerOnCourt = 'SUB_IN_PLAYER_ON_COURT';
  static const subOutPlayerNotOnCourt = 'SUB_OUT_PLAYER_NOT_ON_COURT';
  static const playerNotOnCourt = 'PLAYER_NOT_ON_COURT';
  static const playerNotInRoster = 'PLAYER_NOT_IN_ROSTER';
  static const tooManyPlayersOnCourt = 'TOO_MANY_PLAYERS_ON_COURT';
  static const eventOutsidePeriod = 'EVENT_OUTSIDE_PERIOD';
  static const periodAlreadyRunning = 'PERIOD_ALREADY_RUNNING';
  static const periodAlreadyPlayed = 'PERIOD_ALREADY_PLAYED';
  static const periodNotRunning = 'PERIOD_NOT_RUNNING';
  static const missingPeriodEnd = 'MISSING_PERIOD_END';
  static const clockOutOfRange = 'CLOCK_OUT_OF_RANGE';
  static const voidTargetNotFound = 'VOID_TARGET_NOT_FOUND';
  static const voidOfVoid = 'VOID_OF_VOID';
}

/// A domain inconsistency; events are never dropped for these.
class ProjectionWarning {
  const ProjectionWarning({required this.code, required this.eventId, this.playerId});
  final String code;
  final String eventId;
  final String? playerId;
}

class PlayerLine {
  const PlayerLine({required this.playerId, required this.wasStarter, required this.stats, this.warnings = const []});
  final String playerId;
  final bool wasStarter;
  final StatLine stats;
  final List<ProjectionWarning> warnings;
}

class PeriodScore {
  const PeriodScore(this.period, this.team, this.opponent);
  final int period;
  final int team;
  final int opponent;
}

class MatchSummary {
  const MatchSummary({
    required this.teamScore,
    required this.opponentScore,
    required this.periodScores,
    required this.lastServerSeq,
  });
  final int teamScore;
  final int opponentScore;
  final List<PeriodScore> periodScores;
  final int lastServerSeq;
}

/// Where the replay ended: what the live screen shows (not in the vectors).
class LiveState {
  const LiveState({
    required this.onCourt,
    required this.period,
    required this.running,
    required this.clock,
    required this.playedPeriods,
  });

  /// Roster players on court after the last event (starters before tip-off).
  final Set<String> onCourt;

  /// Current (running) or last started period; 0 before the first start.
  final int period;
  final bool running;

  /// Clock of the last event while running / at the last period boundary.
  final int clock;
  final Set<int> playedPeriods;
}

/// Box score of a match: one line per roster player (roster order).
class Projection {
  const Projection({
    required this.playerStats,
    required this.summary,
    required this.warnings,
    required this.voidedBy,
    required this.live,
  });

  final List<PlayerLine> playerStats;
  final MatchSummary summary;

  /// Match-level warnings (VOID resolution first, then replay order).
  final List<ProjectionWarning> warnings;

  /// voided event id -> VOID event id.
  final Map<String, String> voidedBy;
  final LiveState live;

  StatLine get teamTotals => playerStats.fold(StatLine.zero, (a, l) => a + l.stats);

  PlayerLine? lineOf(String playerId) {
    for (final l in playerStats) {
      if (l.playerId == playerId) return l;
    }
    return null;
  }
}
