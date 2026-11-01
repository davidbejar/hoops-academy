package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.game.application.GetBoxScore;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.RosterEntry;
import com.hoopsacademy.game.domain.projection.PlayerLine;
import com.hoopsacademy.game.domain.projection.ProjectionWarning;
import com.hoopsacademy.game.domain.projection.SeasonLine;
import com.hoopsacademy.game.domain.projection.SeasonStats;
import com.hoopsacademy.game.domain.projection.StatLine;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Contract DTOs of the Statistics tag: BoxScore and PlayerSeasonStats. */
final class StatisticsDtos {

    private StatisticsDtos() {}

    /** Contract StatLine; personalFouls counts every foul, technical/unsportsmanlike are also counted on their own. */
    record StatLineDto(int points, int fg1Made, int fg1Attempted, int fg2Made, int fg2Attempted, int fg3Made,
            int fg3Attempted, int assists, int offensiveRebounds, int defensiveRebounds, int turnovers, int steals,
            int blocks, int personalFouls, int technicalFouls, int unsportsmanlikeFouls, int secondsPlayed) {

        static StatLineDto from(StatLine s) {
            return new StatLineDto(s.points(), s.fg1Made(), s.fg1Attempted(), s.fg2Made(), s.fg2Attempted(),
                    s.fg3Made(), s.fg3Attempted(), s.assists(), s.offensiveRebounds(), s.defensiveRebounds(),
                    s.turnovers(), s.steals(), s.blocks(), s.personalFouls(), s.technicalFouls(),
                    s.unsportsmanlikeFouls(), s.secondsPlayed());
        }
    }

    record WarningDto(String code, UUID eventId, UUID playerId, String message) {

        static List<WarningDto> from(List<ProjectionWarning> warnings) {
            return warnings.stream().map(w -> new WarningDto(w.code(), w.eventId().value(),
                    w.playerId() == null ? null : w.playerId().value(), w.message())).toList();
        }
    }

    record PlayerMatchStatsDto(UUID playerId, String displayName, String jerseyNumber, boolean wasStarter,
            StatLineDto stats, List<WarningDto> warnings) {}

    record PeriodScoreDto(int period, int team, int opponent) {}

    record BoxScoreDto(UUID matchId, MatchStatus status, MatchDto.ScoreDto score, List<PeriodScoreDto> periodScores,
            StatLineDto teamTotals, List<PlayerMatchStatsDto> players, List<WarningDto> warnings,
            long lastServerSeq) {

        static BoxScoreDto from(GetBoxScore.BoxScore box) {
            var projection = box.projection();
            var summary = projection.summary();
            Map<PlayerId, PlayerLine> lines = projection.playerStats().stream()
                    .collect(Collectors.toMap(PlayerLine::playerId, Function.identity()));
            List<PlayerMatchStatsDto> players = box.roster().entries().stream()
                    .filter(entry -> box.visiblePlayers().contains(entry.playerId()))
                    .map(entry -> player(entry, lines.get(entry.playerId())))
                    .toList();
            return new BoxScoreDto(box.match().id().value(), box.match().status(),
                    new MatchDto.ScoreDto(summary.teamScore(), summary.opponentScore()),
                    summary.periodScores().stream().map(p -> new PeriodScoreDto(p.period(), p.team(), p.opponent())).toList(),
                    StatLineDto.from(projection.teamTotals()), players, WarningDto.from(projection.warnings()),
                    summary.lastServerSeq());
        }

        private static PlayerMatchStatsDto player(RosterEntry entry, PlayerLine line) {
            StatLine stats = line == null ? StatLine.ZERO : line.stats();
            return new PlayerMatchStatsDto(entry.playerId().value(), entry.displayName(),
                    entry.jerseyNumber() == null ? null : entry.jerseyNumber().value(), entry.starter(),
                    StatLineDto.from(stats), line == null ? List.of() : WarningDto.from(line.warnings()));
        }
    }

    record StatAveragesDto(double points, double assists, double rebounds, double steals, double blocks,
            double turnovers, double personalFouls, double minutesPlayed) {}

    record PlayerMatchLineDto(UUID matchId, Instant scheduledAt, String opponentName, MatchStatus status,
            boolean wasStarter, StatLineDto stats) {

        static PlayerMatchLineDto from(SeasonLine line) {
            return new PlayerMatchLineDto(line.matchId().value(), line.scheduledAt(), line.opponentName(), line.status(),
                    line.wasStarter(), StatLineDto.from(line.stats()));
        }
    }

    record PlayerSeasonStatsDto(UUID playerId, UUID seasonId, int gamesPlayed, int gamesStarted, StatLineDto totals,
            StatAveragesDto averages, List<PlayerMatchLineDto> matches) {

        static PlayerSeasonStatsDto from(SeasonStats s) {
            SeasonStats.Averages a = s.averages();
            return new PlayerSeasonStatsDto(s.playerId().value(), s.seasonId().value(), s.gamesPlayed(), s.gamesStarted(),
                    StatLineDto.from(s.totals()), new StatAveragesDto(a.points(), a.assists(), a.rebounds(), a.steals(),
                            a.blocks(), a.turnovers(), a.personalFouls(), a.minutesPlayed()),
                    s.matches().stream().map(PlayerMatchLineDto::from).toList());
        }
    }
}
