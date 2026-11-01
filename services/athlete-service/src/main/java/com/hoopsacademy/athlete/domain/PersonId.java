package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a person (value object over a UUID). */
public record PersonId(UUID value) {

    public PersonId {
        Objects.requireNonNull(value, "person id");
    }

    public static PersonId random() {
        return new PersonId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
