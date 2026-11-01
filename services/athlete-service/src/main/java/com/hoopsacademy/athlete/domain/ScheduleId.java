package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a schedule (value object over a UUID). */
public record ScheduleId(UUID value) {

    public ScheduleId {
        Objects.requireNonNull(value, "schedule id");
    }

    public static ScheduleId random() {
        return new ScheduleId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
