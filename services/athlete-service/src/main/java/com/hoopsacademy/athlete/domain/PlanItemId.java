package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a plan item (value object over a UUID). */
public record PlanItemId(UUID value) {

    public PlanItemId {
        Objects.requireNonNull(value, "plan item id");
    }

    public static PlanItemId random() {
        return new PlanItemId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
