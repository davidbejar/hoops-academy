package com.hoopsacademy.core.domain.roster;

import java.util.Objects;
import java.util.UUID;

/** Identity of a age category. */
public record AgeCategoryId(UUID value) {

    public AgeCategoryId {
        Objects.requireNonNull(value, "age category id");
    }

    public static AgeCategoryId random() {
        return new AgeCategoryId(UUID.randomUUID());
    }
}
