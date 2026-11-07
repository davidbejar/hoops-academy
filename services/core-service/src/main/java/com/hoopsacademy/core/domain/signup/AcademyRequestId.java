package com.hoopsacademy.core.domain.signup;

import java.util.Objects;
import java.util.UUID;

/** Identity of a request for a new academy. */
public record AcademyRequestId(UUID value) {

    public AcademyRequestId {
        Objects.requireNonNull(value, "academy request id");
    }

    public static AcademyRequestId random() {
        return new AcademyRequestId(UUID.randomUUID());
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
