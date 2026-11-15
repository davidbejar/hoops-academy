package com.hoopsacademy.game.adapters.out.client;

import com.hoopsacademy.game.application.sheet.MatchSheet;
import com.hoopsacademy.game.domain.JerseyNumber;
import com.hoopsacademy.game.domain.projection.PeriodScore;
import com.hoopsacademy.game.domain.projection.StatLine;
import java.util.List;

/** pdf.yaml {@code MatchSheetRequest}: the wire shape of a {@link MatchSheet}. Never logged. */
record MatchSheetBody(String locale, Academy academy, MatchInfo match, Score score, List<PeriodLine> periodScores,
        Stats teamTotals, List<PlayerLine> players) {

    static MatchSheetBody of(MatchSheet sheet) {
        MatchSheet.Header header = sheet.header();
        return new MatchSheetBody(sheet.language().code(),
                new Academy(sheet.academy().name(), sheet.academy().timeZone().getId()),
                new MatchInfo(header.teamName(), header.opponentName(), header.homeAway().name(),
                        header.scheduledAt().toString(), header.venue(), header.status().name(), header.periodCount(),
                        header.periodMinutes()),
                new Score(sheet.teamScore(), sheet.opponentScore()),
                sheet.periodScores().stream().map(PeriodLine::of).toList(), Stats.of(sheet.teamTotals()),
                sheet.players().stream().map(PlayerLine::of).toList());
    }

    record Academy(String name, String timeZone) {}

    record MatchInfo(String teamName, String opponentName, String homeAway, String scheduledAt, String venue,
            String status, int periodCount, int periodMinutes) {}

    record Score(int team, int opponent) {}

    record PeriodLine(int period, int team, int opponent) {

        static PeriodLine of(PeriodScore score) {
            return new PeriodLine(score.period(), score.team(), score.opponent());
        }
    }

    record PlayerLine(String displayName, String jerseyNumber, boolean wasStarter, Stats stats) {

        static PlayerLine of(MatchSheet.Line line) {
            JerseyNumber jersey = line.jerseyNumber();
            return new PlayerLine(line.displayName(), jersey == null ? null : jersey.value(), line.starter(),
                    Stats.of(line.stats()));
        }
    }

    /** pdf.yaml {@code StatLine} (as game's: fg1 = free throws). */
    record Stats(int points, int fg1Made, int fg1Attempted, int fg2Made, int fg2Attempted, int fg3Made,
            int fg3Attempted, int assists, int offensiveRebounds, int defensiveRebounds, int turnovers, int steals,
            int blocks, int personalFouls, int technicalFouls, int unsportsmanlikeFouls, int secondsPlayed) {

        static Stats of(StatLine line) {
            return new Stats(line.points(), line.fg1Made(), line.fg1Attempted(), line.fg2Made(),
                    line.fg2Attempted(), line.fg3Made(), line.fg3Attempted(), line.assists(),
                    line.offensiveRebounds(), line.defensiveRebounds(), line.turnovers(), line.steals(),
                    line.blocks(), line.personalFouls(), line.technicalFouls(), line.unsportsmanlikeFouls(),
                    line.secondsPlayed());
        }
    }
}
