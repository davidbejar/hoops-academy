package com.hoopsacademy.athlete.adapters.out.persistence;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

/** Composite primary key (session, player) of {@link AttendanceEntity}. */
class AttendanceKey implements Serializable {

    UUID sessionId;
    UUID playerId;

    AttendanceKey() {}

    AttendanceKey(UUID sessionId, UUID playerId) {
        this.sessionId = sessionId;
        this.playerId = playerId;
    }

    @Override
    public boolean equals(Object o) {
        return o instanceof AttendanceKey other
                && Objects.equals(sessionId, other.sessionId)
                && Objects.equals(playerId, other.playerId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(sessionId, playerId);
    }
}
