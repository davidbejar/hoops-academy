package com.hoopsacademy.core.domain.membership;

import java.util.Objects;
import java.util.UUID;

/** Identity of a person (member) within a tenant. */
public record PersonId(UUID value) {

    public PersonId {
        Objects.requireNonNull(value, "person id");
    }

    public static PersonId random() {
        return new PersonId(UUID.randomUUID());
    }
}
