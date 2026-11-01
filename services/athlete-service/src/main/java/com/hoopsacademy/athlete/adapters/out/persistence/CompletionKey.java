package com.hoopsacademy.athlete.adapters.out.persistence;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

/** Composite primary key (assignment, player) of {@link CompletionEntity}. */
class CompletionKey implements Serializable {

    UUID assignmentId;
    UUID playerId;

    CompletionKey() {}

    CompletionKey(UUID assignmentId, UUID playerId) {
        this.assignmentId = assignmentId;
        this.playerId = playerId;
    }

    @Override
    public boolean equals(Object o) {
        return o instanceof CompletionKey other
                && Objects.equals(assignmentId, other.assignmentId)
                && Objects.equals(playerId, other.playerId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(assignmentId, playerId);
    }
}
