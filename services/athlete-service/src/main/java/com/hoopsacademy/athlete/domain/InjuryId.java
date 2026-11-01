package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a injury (value object over a UUID). */
public record InjuryId(UUID value) {

    public InjuryId {
        Objects.requireNonNull(value, "injury id");
    }

    public static InjuryId random() {
        return new InjuryId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
