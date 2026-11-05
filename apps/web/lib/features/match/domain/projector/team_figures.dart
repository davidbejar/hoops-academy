/// Team-level figures of a match (score, period scores, team totals) and how
/// a caller with a filtered event feed gets them right (ADR-0030).
library;

import 'dart:math' as math;

import '../match_event.dart';
import 'projection.dart';
import 'projector.dart';

/// What every member sees of a match. [periodScores] and [teamTotals] are
/// null when unknown (a snapshot that carried the score only).
class TeamFigures {
  const TeamFigures({required this.teamScore, required this.opponentScore, this.periodScores, this.teamTotals});

  factory TeamFigures.of(Projection p) => TeamFigures(
    teamScore: p.summary.teamScore,
    opponentScore: p.summary.opponentScore,
    periodScores: p.summary.periodScores,
    teamTotals: p.teamTotals,
  );

  final int teamScore;
  final int opponentScore;
  final List<PeriodScore>? periodScores;
  final StatLine? teamTotals;
}

/// The server's figures (`GET box-score`, or the match's score) as of
/// [lastServerSeq]: they include every event, also those the caller's feed
/// does not show.
class OfficialFigures {
  const OfficialFigures({required this.figures, required this.lastServerSeq});
  final TeamFigures figures;
  final int lastServerSeq;
}

/// Team figures for a caller whose feed is filtered: the [official] snapshot
/// plus what the caller's own [events] (feed ∪ own queue) changed after it —
/// visible events with a newer serverSeq and own events not stored yet.
/// Events the caller cannot see that arrived after the snapshot show up with
/// the next snapshot.
TeamFigures reconcileTeamFigures({
  required OfficialFigures official,
  required MatchRules rules,
  required List<RosterPlayer> roster,
  required List<RecordedEvent> events,
}) {
  final now = TeamFigures.of(project(rules, roster, events));
  final counted = TeamFigures.of(project(rules, roster, [
    for (final e in events)
      if (e.serverSeq != null && e.serverSeq! <= official.lastServerSeq) e,
  ]));
  final base = official.figures;
  final basePeriods = base.periodScores;
  final baseTotals = base.teamTotals;
  return TeamFigures(
    teamScore: math.max(0, base.teamScore + now.teamScore - counted.teamScore),
    opponentScore: math.max(0, base.opponentScore + now.opponentScore - counted.opponentScore),
    periodScores: basePeriods == null ? null : _addPeriods(basePeriods, now.periodScores!, counted.periodScores!),
    teamTotals: baseTotals == null ? null : baseTotals + now.teamTotals! - counted.teamTotals!,
  );
}

List<PeriodScore> _addPeriods(List<PeriodScore> base, List<PeriodScore> plus, List<PeriodScore> minus) {
  final team = <int, int>{}, opponent = <int, int>{};
  void add(List<PeriodScore> scores, int sign) {
    for (final s in scores) {
      team[s.period] = (team[s.period] ?? 0) + sign * s.team;
      opponent[s.period] = (opponent[s.period] ?? 0) + sign * s.opponent;
    }
  }

  add(base, 1);
  add(plus, 1);
  add(minus, -1);
  return [
    for (final period in team.keys.toList()..sort())
      PeriodScore(period, math.max(0, team[period]!), math.max(0, opponent[period]!)),
  ];
}
