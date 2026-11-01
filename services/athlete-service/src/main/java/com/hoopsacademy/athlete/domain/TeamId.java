package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a team (value object over a UUID). */
public record TeamId(UUID value) {

    public TeamId {
        Objects.requireNonNull(value, "team id");
    }

    public static TeamId random() {
        return new TeamId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
