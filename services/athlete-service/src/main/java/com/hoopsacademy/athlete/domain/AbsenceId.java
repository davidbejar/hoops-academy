package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a absence (value object over a UUID). */
public record AbsenceId(UUID value) {

    public AbsenceId {
        Objects.requireNonNull(value, "absence id");
    }

    public static AbsenceId random() {
        return new AbsenceId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
