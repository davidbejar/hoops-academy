package com.hoopsacademy.athlete.domain;

import java.util.Objects;

/** Who recorded something: the person in the tenant plus a display-name snapshot for audit output. */
public record Actor(PersonId personId, String displayName) {

    public Actor {
        Objects.requireNonNull(personId, "personId");
        if (displayName == null || displayName.isBlank()) {
            throw new IllegalArgumentException("displayName must not be blank");
        }
    }
}
