package com.hoopsacademy.core.domain.roster;

import java.util.Objects;
import java.util.UUID;

/** Identity of a team. */
public record TeamId(UUID value) {

    public TeamId {
        Objects.requireNonNull(value, "team id");
    }

    public static TeamId random() {
        return new TeamId(UUID.randomUUID());
    }
}
