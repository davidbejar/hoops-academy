package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.domain.roster.Team;
import java.util.UUID;

/** The contract's small reference objects. */
final class RefDtos {

    private RefDtos() {}

    /** Contract {@code PersonRef}. */
    record PersonRef(UUID personId, String displayName) {}

    /** Contract {@code PlayerRef}. */
    record PlayerRef(UUID id, String displayName) {}

    /** Contract {@code TeamRef}. */
    record TeamRef(UUID id, String name) {

        static TeamRef of(Team team) {
            return team == null ? null : new TeamRef(team.id().value(), team.name());
        }
    }
}
