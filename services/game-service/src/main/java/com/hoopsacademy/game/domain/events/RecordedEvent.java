package com.hoopsacademy.game.domain.events;

import java.util.Objects;

/** An event as the server stored it: the client's facts plus the server sequence number. */
public record RecordedEvent(MatchEvent event, long serverSeq) {

    public RecordedEvent {
        Objects.requireNonNull(event, "event");
    }

    public EventId id() {
        return event.id();
    }

    public EventMeta meta() {
        return event.meta();
    }
}
