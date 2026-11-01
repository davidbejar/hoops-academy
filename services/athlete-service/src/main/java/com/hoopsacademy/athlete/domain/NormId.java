package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a norm (value object over a UUID). */
public record NormId(UUID value) {

    public NormId {
        Objects.requireNonNull(value, "norm id");
    }

    public static NormId random() {
        return new NormId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
