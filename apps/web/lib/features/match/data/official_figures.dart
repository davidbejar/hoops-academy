import 'package:hoops_game_api/hoops_game_api.dart' as gen;

import '../domain/projector/projection.dart';
import '../domain/projector/team_figures.dart';

/// The server's team figures from `GET box-score` (ADR-0030).
OfficialFigures officialFiguresOf(gen.BoxScore box) => OfficialFigures(
  lastServerSeq: box.lastServerSeq,
  figures: TeamFigures(
    teamScore: box.score.team,
    opponentScore: box.score.opponent,
    periodScores: [for (final p in box.periodScores) PeriodScore(p.period, p.team, p.opponent)],
    teamTotals: _statLine(box.teamTotals),
  ),
);

/// The score a match carries (offline fallback: period scores and totals unknown).
OfficialFigures officialScoreOf(gen.Match match) => OfficialFigures(
  lastServerSeq: match.lastServerSeq,
  figures: TeamFigures(teamScore: match.score.team, opponentScore: match.score.opponent),
);

StatLine _statLine(gen.StatLine s) => StatLine(
  points: s.points,
  fg1Made: s.fg1Made,
  fg1Attempted: s.fg1Attempted,
  fg2Made: s.fg2Made,
  fg2Attempted: s.fg2Attempted,
  fg3Made: s.fg3Made,
  fg3Attempted: s.fg3Attempted,
  assists: s.assists,
  offensiveRebounds: s.offensiveRebounds,
  defensiveRebounds: s.defensiveRebounds,
  turnovers: s.turnovers,
  steals: s.steals,
  blocks: s.blocks,
  personalFouls: s.personalFouls,
  technicalFouls: s.technicalFouls,
  unsportsmanlikeFouls: s.unsportsmanlikeFouls,
  secondsPlayed: s.secondsPlayed,
);
