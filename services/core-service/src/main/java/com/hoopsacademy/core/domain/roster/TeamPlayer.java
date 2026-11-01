package com.hoopsacademy.core.domain.roster;

import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import com.hoopsacademy.core.domain.membership.PlayerId;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Objects;

/**
 * A player's assignment to a team. Open while {@code leftOn} is null; valid while open and not invalidated. The
 * evaluator never deletes an assignment: it records {@code invalidatedAt} + reason and keeps the row.
 */
public record TeamPlayer(TeamPlayerId id, TeamId team, PlayerId player, JerseyNumber jersey, LocalDate joinedOn,
        LocalDate leftOn, int playUpLevels, Instant invalidatedAt, EligibilityReason invalidReason) {

    public TeamPlayer {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(team, "team");
        Objects.requireNonNull(player, "player");
        Objects.requireNonNull(joinedOn, "joinedOn");
        if (playUpLevels < 0) {
            throw new IllegalArgumentException("playUpLevels must be >= 0");
        }
    }

    public static TeamPlayer assign(TeamId team, PlayerId player, JerseyNumber jersey, LocalDate joinedOn,
            int playUpLevels) {
        return new TeamPlayer(TeamPlayerId.random(), team, player, jersey, joinedOn, null, playUpLevels, null, null);
    }

    public boolean isOpen() {
        return leftOn == null;
    }

    public boolean isValid() {
        return isOpen() && invalidatedAt == null;
    }

    public TeamPlayer invalidate(EligibilityReason reason, Instant at) {
        if (!isValid()) {
            throw new IllegalStateException("Only a valid open assignment can be invalidated");
        }
        return new TeamPlayer(id, team, player, jersey, joinedOn, null, playUpLevels, at, reason);
    }

    /** Closes the assignment on {@code on}, or on the joining day when it has not started yet. */
    public TeamPlayer close(LocalDate on) {
        if (!isOpen()) {
            throw new IllegalStateException("The assignment is already closed");
        }
        LocalDate left = on.isBefore(joinedOn) ? joinedOn : on;
        return new TeamPlayer(id, team, player, jersey, joinedOn, left, playUpLevels, invalidatedAt, invalidReason);
    }

    public TeamPlayer withJersey(JerseyNumber number) {
        return new TeamPlayer(id, team, player, number, joinedOn, leftOn, playUpLevels, invalidatedAt, invalidReason);
    }
}
