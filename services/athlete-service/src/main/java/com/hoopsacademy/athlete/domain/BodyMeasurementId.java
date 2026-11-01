package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a measurement (value object over a UUID). */
public record BodyMeasurementId(UUID value) {

    public BodyMeasurementId {
        Objects.requireNonNull(value, "measurement id");
    }

    public static BodyMeasurementId random() {
        return new BodyMeasurementId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
