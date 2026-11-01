package com.hoopsacademy.core.domain.roster;

import java.util.Objects;
import java.util.UUID;

/** Identity of a season. */
public record SeasonId(UUID value) {

    public SeasonId {
        Objects.requireNonNull(value, "season id");
    }

    public static SeasonId random() {
        return new SeasonId(UUID.randomUUID());
    }
}
