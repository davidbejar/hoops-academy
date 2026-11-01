package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import java.time.Instant;
import java.util.Objects;

/** An event row: the recorded event, who recorded it, when it arrived and the VOID that voided it (or null). */
public record StoredEvent(RecordedEvent recorded, Recorder recordedBy, Instant receivedAt, EventId voidedBy) {

    public StoredEvent {
        Objects.requireNonNull(recorded, "recorded");
        Objects.requireNonNull(recordedBy, "recordedBy");
        Objects.requireNonNull(receivedAt, "receivedAt");
    }
}
