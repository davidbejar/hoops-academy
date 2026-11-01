package com.hoopsacademy.game.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a season (value object over a UUID). */
public record SeasonId(UUID value) {

    public SeasonId {
        Objects.requireNonNull(value, "season id value");
    }

    public static SeasonId of(UUID value) {
        return new SeasonId(value);
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
