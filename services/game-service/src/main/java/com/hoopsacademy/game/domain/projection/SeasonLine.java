package com.hoopsacademy.game.domain.projection;

import com.hoopsacademy.game.domain.MatchId;
import com.hoopsacademy.game.domain.MatchStatus;
import java.time.Instant;
import java.util.Objects;

/** A player's projected line in one match of a season, with the match facts a season view shows. */
public record SeasonLine(
        MatchId matchId, Instant scheduledAt, String opponentName, MatchStatus status, boolean wasStarter, StatLine stats) {

    public SeasonLine {
        Objects.requireNonNull(matchId, "matchId");
        Objects.requireNonNull(stats, "stats");
    }

    /** Started, or has minutes or any counted action. */
    public boolean played() {
        return wasStarter || stats.hasActivity();
    }
}
