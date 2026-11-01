package com.hoopsacademy.game.domain.projection;

/**
 * Counting statistics of a player (or a team). fg1 = free throws. {@code personalFouls} counts every foul
 * (contract semantics); technical and unsportsmanlike fouls are additionally counted on their own.
 */
public record StatLine(
        int points,
        int fg1Made, int fg1Attempted,
        int fg2Made, int fg2Attempted,
        int fg3Made, int fg3Attempted,
        int assists,
        int offensiveRebounds, int defensiveRebounds,
        int turnovers, int steals, int blocks,
        int personalFouls, int technicalFouls, int unsportsmanlikeFouls,
        int secondsPlayed) {

    public static final StatLine ZERO = new StatLine(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    public StatLine plus(StatLine o) {
        return new StatLine(points + o.points,
                fg1Made + o.fg1Made, fg1Attempted + o.fg1Attempted,
                fg2Made + o.fg2Made, fg2Attempted + o.fg2Attempted,
                fg3Made + o.fg3Made, fg3Attempted + o.fg3Attempted,
                assists + o.assists,
                offensiveRebounds + o.offensiveRebounds, defensiveRebounds + o.defensiveRebounds,
                turnovers + o.turnovers, steals + o.steals, blocks + o.blocks,
                personalFouls + o.personalFouls, technicalFouls + o.technicalFouls,
                unsportsmanlikeFouls + o.unsportsmanlikeFouls,
                secondsPlayed + o.secondsPlayed);
    }

    public int rebounds() {
        return offensiveRebounds + defensiveRebounds;
    }

    /** Whether the line shows any participation (minutes or any counted action). */
    public boolean hasActivity() {
        return !equals(ZERO);
    }
}
