package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a test type (value object over a UUID). */
public record TestTypeId(UUID value) {

    public TestTypeId {
        Objects.requireNonNull(value, "test type id");
    }

    public static TestTypeId random() {
        return new TestTypeId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
