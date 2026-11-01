package com.hoopsacademy.game.domain.projection;

import com.hoopsacademy.game.domain.events.EventId;
import java.util.List;
import java.util.Map;

/**
 * Result of projecting a match: one line per roster player (roster order), the summary, match-level warnings
 * (not attributable to a roster player) and which VOID event voided which event.
 */
public record Projection(
        List<PlayerLine> playerStats, MatchSummary summary, List<ProjectionWarning> warnings,
        Map<EventId, EventId> voidedBy) {

    public Projection {
        playerStats = List.copyOf(playerStats);
        warnings = List.copyOf(warnings);
        voidedBy = Map.copyOf(voidedBy);
    }

    /** Sum of the player lines. */
    public StatLine teamTotals() {
        return playerStats.stream().map(PlayerLine::stats).reduce(StatLine.ZERO, StatLine::plus);
    }
}
