package com.hoopsacademy.core.domain.membership;

import java.util.Objects;
import java.util.UUID;

/** Identity of a player record (a person holding the PLAYER role). */
public record PlayerId(UUID value) {

    public PlayerId {
        Objects.requireNonNull(value, "player id");
    }

    public static PlayerId random() {
        return new PlayerId(UUID.randomUUID());
    }
}
