package com.hoopsacademy.game.domain.projection;

import java.util.List;

/** Score of a match and the last event sequence number the projection includes. */
public record MatchSummary(int teamScore, int opponentScore, List<PeriodScore> periodScores, long lastServerSeq) {

    public MatchSummary {
        periodScores = List.copyOf(periodScores);
    }
}
