package com.hoopsacademy.athlete.domain;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/** A player's (or their parent's / coach's) statement about an assignment; one per assignment and player. */
public record PlanCompletion(
        UUID id,
        AssignmentId assignmentId,
        PlayerId playerId,
        CompletionStatus status,
        String note,
        Actor markedBy,
        Instant markedAt) {

    public PlanCompletion {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(assignmentId, "assignmentId");
        Objects.requireNonNull(playerId, "playerId");
        Objects.requireNonNull(status, "status");
        Objects.requireNonNull(markedBy, "markedBy");
        Objects.requireNonNull(markedAt, "markedAt");
    }

    public static PlanCompletion record(AssignmentId assignment, PlayerId player, CompletionStatus status, String note,
            Actor by, Instant now) {
        return new PlanCompletion(UUID.randomUUID(), assignment, player, status, note, by, now);
    }

    public PlanCompletion changedTo(CompletionStatus newStatus, String newNote, Actor by, Instant now) {
        return new PlanCompletion(id, assignmentId, playerId, newStatus, newNote, by, now);
    }
}
