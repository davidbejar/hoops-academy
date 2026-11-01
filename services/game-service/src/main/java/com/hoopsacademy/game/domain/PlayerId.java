package com.hoopsacademy.game.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a player (value object over a UUID). */
public record PlayerId(UUID value) {

    public PlayerId {
        Objects.requireNonNull(value, "player id value");
    }

    public static PlayerId of(UUID value) {
        return new PlayerId(value);
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
