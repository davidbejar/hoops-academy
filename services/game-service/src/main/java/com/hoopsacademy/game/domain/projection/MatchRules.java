package com.hoopsacademy.game.domain.projection;

import com.hoopsacademy.game.domain.Match;

/**
 * Timing rules the projector needs. Periods above {@code periodCount} are overtimes of {@code overtimeMinutes}.
 */
public record MatchRules(int periodCount, int periodMinutes, int overtimeMinutes) {

    public static final int DEFAULT_OVERTIME_MINUTES = 5;
    public static final int PLAYERS_ON_COURT = 5;

    public MatchRules {
        if (periodCount < 1 || periodMinutes < 1 || overtimeMinutes < 1) {
            throw new IllegalArgumentException("period count and lengths must be positive");
        }
    }

    public static MatchRules of(Match match, int overtimeMinutes) {
        return new MatchRules(match.periodCount(), match.periodMinutes(), overtimeMinutes);
    }

    public int periodSeconds(int period) {
        return 60 * (period <= periodCount ? periodMinutes : overtimeMinutes);
    }
}
