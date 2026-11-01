package com.hoopsacademy.game.domain;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/** The players of one match; a player appears at most once. */
public record MatchRoster(MatchId matchId, List<RosterEntry> entries) {

    public MatchRoster {
        Objects.requireNonNull(matchId, "matchId");
        entries = List.copyOf(entries);
        Set<PlayerId> seen = new HashSet<>();
        for (RosterEntry entry : entries) {
            if (!seen.add(entry.playerId())) {
                throw new DomainRuleViolation("Player " + entry.playerId() + " is listed twice", "DUPLICATE_PLAYER");
            }
        }
    }

    public static MatchRoster empty(MatchId matchId) {
        return new MatchRoster(matchId, List.of());
    }

    public boolean hasStarter() {
        return entries.stream().anyMatch(RosterEntry::starter);
    }
}
