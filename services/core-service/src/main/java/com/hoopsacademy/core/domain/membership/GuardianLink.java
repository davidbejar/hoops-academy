package com.hoopsacademy.core.domain.membership;

import java.time.Instant;
import java.util.Objects;

/** A PARENT person linked as guardian of a player. */
public record GuardianLink(GuardianLinkId id, PersonId guardian, PlayerId player, Instant createdAt) {

    public GuardianLink {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(guardian, "guardian");
        Objects.requireNonNull(player, "player");
    }
}
