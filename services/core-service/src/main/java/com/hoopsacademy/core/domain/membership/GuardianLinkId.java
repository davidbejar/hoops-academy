package com.hoopsacademy.core.domain.membership;

import java.util.Objects;
import java.util.UUID;

/** Identity of a guardian ↔ player link. */
public record GuardianLinkId(UUID value) {

    public GuardianLinkId {
        Objects.requireNonNull(value, "guardian link id");
    }

    public static GuardianLinkId random() {
        return new GuardianLinkId(UUID.randomUUID());
    }
}
