package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a player (value object over a UUID). */
public record PlayerId(UUID value) {

    public PlayerId {
        Objects.requireNonNull(value, "player id");
    }

    public static PlayerId random() {
        return new PlayerId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
