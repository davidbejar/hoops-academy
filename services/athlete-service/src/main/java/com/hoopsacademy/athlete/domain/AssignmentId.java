package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a plan assignment (value object over a UUID). */
public record AssignmentId(UUID value) {

    public AssignmentId {
        Objects.requireNonNull(value, "plan assignment id");
    }

    public static AssignmentId random() {
        return new AssignmentId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
