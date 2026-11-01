package com.hoopsacademy.game.domain.events;

import java.util.Objects;
import java.util.UUID;

/** Client-generated identity of a match event (UUIDv7); the idempotency key of the sync protocol. */
public record EventId(UUID value) implements Comparable<EventId> {

    public EventId {
        Objects.requireNonNull(value, "event id value");
    }

    public static EventId of(UUID value) {
        return new EventId(value);
    }

    @Override
    public int compareTo(EventId other) {
        return value.compareTo(other.value);
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
