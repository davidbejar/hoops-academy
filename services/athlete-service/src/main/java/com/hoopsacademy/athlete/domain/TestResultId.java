package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a test result (value object over a UUID). */
public record TestResultId(UUID value) {

    public TestResultId {
        Objects.requireNonNull(value, "test result id");
    }

    public static TestResultId random() {
        return new TestResultId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
