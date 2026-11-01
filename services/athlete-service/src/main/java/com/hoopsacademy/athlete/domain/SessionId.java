package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a session (value object over a UUID). */
public record SessionId(UUID value) {

    public SessionId {
        Objects.requireNonNull(value, "session id");
    }

    public static SessionId random() {
        return new SessionId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
