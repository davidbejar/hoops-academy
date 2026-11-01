package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.game.domain.HomeAway;
import com.hoopsacademy.game.domain.Match;
import com.hoopsacademy.game.domain.MatchStatus;
import java.time.Instant;
import java.util.UUID;

/** The contract's {@code Match}. Score and lastServerSeq are 0 until WP7 adds match events. */
public record MatchDto(
        UUID id, UUID teamId, UUID seasonId, String opponentName, HomeAway homeAway, Instant scheduledAt, String venue,
        MatchStatus status, int periodCount, int periodMinutes, Instant startedAt, Instant finishedAt, Instant cancelledAt,
        String cancelReason, ScoreDto score, long lastServerSeq) {

    public record ScoreDto(int team, int opponent) {}

    static MatchDto from(Match m) {
        return new MatchDto(m.id().value(), m.teamId().value(), m.seasonId().value(), m.opponentName(), m.homeAway(),
                m.scheduledAt(), m.venue(), m.status(), m.periodCount(), m.periodMinutes(), m.startedAt(), m.finishedAt(),
                m.cancelledAt(), m.cancelReason(), new ScoreDto(0, 0), 0L);
    }
}
