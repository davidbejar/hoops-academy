package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.events.MatchEvent;
import java.util.Objects;
import java.util.UUID;

/** One event of a submitted batch after schema validation: either a well-formed event or the reason it is not. */
public sealed interface SubmittedEvent {

    /** Id to report the result under; the nil UUID when the submitted event had no usable id. */
    UUID eventId();

    record Valid(MatchEvent event) implements SubmittedEvent {
        public Valid {
            Objects.requireNonNull(event, "event");
        }

        @Override
        public UUID eventId() {
            return event.id().value();
        }
    }

    record Invalid(UUID eventId, String message) implements SubmittedEvent {
        public static final UUID NO_ID = new UUID(0, 0);

        public Invalid {
            Objects.requireNonNull(eventId, "eventId");
            Objects.requireNonNull(message, "message");
        }
    }
}
