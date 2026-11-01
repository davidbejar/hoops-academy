package com.hoopsacademy.athlete.domain;

import java.time.Instant;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

/** A plan given to a whole team (its roster at read time) or to one player. */
public record PlanAssignment(
        AssignmentId id,
        PlanId planId,
        TeamId teamIdOrNull,
        PlayerId playerIdOrNull,
        LocalDate dueOn,
        String notes,
        Actor assignedBy,
        Instant createdAt) {

    public PlanAssignment {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(planId, "planId");
        Objects.requireNonNull(dueOn, "dueOn");
        Objects.requireNonNull(assignedBy, "assignedBy");
        if (teamIdOrNull == null && playerIdOrNull == null) {
            throw new TrainingRuleViolation("Give either teamId or playerId", "ASSIGNMENT_TARGET_REQUIRED");
        }
        if (teamIdOrNull != null && playerIdOrNull != null) {
            throw new TrainingRuleViolation("Give only one of teamId and playerId", "ASSIGNMENT_TARGET_AMBIGUOUS");
        }
    }

    public static PlanAssignment create(PlanId plan, Optional<TeamId> team, Optional<PlayerId> player, LocalDate dueOn,
            String notes, Actor by, Instant now) {
        return new PlanAssignment(AssignmentId.random(), plan, team.orElse(null), player.orElse(null), dueOn, notes, by, now);
    }

    public Optional<TeamId> teamId() {
        return Optional.ofNullable(teamIdOrNull);
    }

    public Optional<PlayerId> playerId() {
        return Optional.ofNullable(playerIdOrNull);
    }

    /** The players this assignment is for: the given current roster for a team assignment, else the one player. */
    public List<PlayerId> targets(Collection<PlayerId> teamRoster) {
        return playerIdOrNull != null ? List.of(playerIdOrNull) : List.copyOf(teamRoster);
    }
}
