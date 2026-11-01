package com.hoopsacademy.core.domain.identity;

import java.util.Objects;
import java.util.UUID;

/** Identity of a platform login ({@code core.app_user}). */
public record UserId(UUID value) {

    public UserId {
        Objects.requireNonNull(value, "user id");
    }

    public static UserId random() {
        return new UserId(UUID.randomUUID());
    }
}
