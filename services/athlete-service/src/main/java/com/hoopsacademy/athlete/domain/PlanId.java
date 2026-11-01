package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a plan (value object over a UUID). */
public record PlanId(UUID value) {

    public PlanId {
        Objects.requireNonNull(value, "plan id");
    }

    public static PlanId random() {
        return new PlanId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
