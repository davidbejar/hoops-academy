package com.hoopsacademy.athlete.domain;

import java.util.Objects;
import java.util.UUID;

/** Identity of a catalogue exercise (value object over a UUID). */
public record ExerciseId(UUID value) {

    public ExerciseId {
        Objects.requireNonNull(value, "exercise id");
    }

    public static ExerciseId random() {
        return new ExerciseId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
