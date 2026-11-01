package com.hoopsacademy.athlete.application;

import java.util.Optional;

/** Applies a partial change to a nullable field: absent keeps the current value, present-empty clears it. */
final class Patches {

    private Patches() {}

    static <T> T apply(Optional<Optional<T>> change, T current) {
        return change.isPresent() ? change.get().orElse(null) : current;
    }
}
