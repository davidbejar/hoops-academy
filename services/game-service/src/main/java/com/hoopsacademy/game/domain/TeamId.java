package com.hoopsacademy.game.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a team (value object over a UUID). */
public record TeamId(UUID value) {

    public TeamId {
        Objects.requireNonNull(value, "team id value");
    }

    public static TeamId of(UUID value) {
        return new TeamId(value);
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
