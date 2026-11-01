package com.hoopsacademy.game.domain.projection;

import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

/** A player's statistics over a season: totals of every match line, per-game averages over games played. */
public record SeasonStats(
        PlayerId playerId, SeasonId seasonId, int gamesPlayed, int gamesStarted, StatLine totals, Averages averages,
        List<SeasonLine> matches) {

    public SeasonStats {
        matches = List.copyOf(matches);
    }

    /** Per-game averages, rounded half-up to two decimals; zero when no game was played. */
    public record Averages(
            double points, double assists, double rebounds, double steals, double blocks, double turnovers,
            double personalFouls, double minutesPlayed) {}

    public static SeasonStats of(PlayerId playerId, SeasonId seasonId, List<SeasonLine> lines) {
        StatLine totals = lines.stream().map(SeasonLine::stats).reduce(StatLine.ZERO, StatLine::plus);
        int played = (int) lines.stream().filter(SeasonLine::played).count();
        int started = (int) lines.stream().filter(SeasonLine::wasStarter).count();
        return new SeasonStats(playerId, seasonId, played, started, totals, averages(totals, played), lines);
    }

    private static Averages averages(StatLine t, int games) {
        return new Averages(per(t.points(), games), per(t.assists(), games), per(t.rebounds(), games),
                per(t.steals(), games), per(t.blocks(), games), per(t.turnovers(), games), per(t.personalFouls(), games),
                games == 0 ? 0 : round(t.secondsPlayed() / 60.0 / games));
    }

    private static double per(int total, int games) {
        return games == 0 ? 0 : round((double) total / games);
    }

    private static double round(double value) {
        return BigDecimal.valueOf(value).setScale(2, RoundingMode.HALF_UP).doubleValue();
    }
}
