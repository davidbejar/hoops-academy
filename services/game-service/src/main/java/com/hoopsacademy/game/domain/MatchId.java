package com.hoopsacademy.game.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a match (value object over a UUID). */
public record MatchId(UUID value) {

    public MatchId {
        Objects.requireNonNull(value, "match id value");
    }

    public static MatchId of(UUID value) {
        return new MatchId(value);
    }

    public static MatchId random() {
        return new MatchId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
