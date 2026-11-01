package com.hoopsacademy.core.domain.roster;

import java.util.Objects;
import java.util.UUID;

/** Identity of a team assignment. */
public record TeamPlayerId(UUID value) {

    public TeamPlayerId {
        Objects.requireNonNull(value, "team assignment id");
    }

    public static TeamPlayerId random() {
        return new TeamPlayerId(UUID.randomUUID());
    }
}
