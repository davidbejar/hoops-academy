package com.hoopsacademy.game.domain.projection;

import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.events.EventId;
import java.util.Objects;

/** A domain inconsistency found while projecting; events are never rejected for these. playerId may be null. */
public record ProjectionWarning(String code, EventId eventId, PlayerId playerId, String message) {

    public ProjectionWarning {
        Objects.requireNonNull(code, "code");
        Objects.requireNonNull(eventId, "eventId");
        Objects.requireNonNull(message, "message");
    }

    static ProjectionWarning of(WarningCode code, EventId eventId, PlayerId playerId, String message) {
        return new ProjectionWarning(code.name(), eventId, playerId, message);
    }
}
