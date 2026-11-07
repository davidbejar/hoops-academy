package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * A core roster event as the replica needs it (ADR-0037): the envelope plus the part of the aggregate's state that
 * game reads. State transfer: every {@code Changed} carries the whole current state, a {@code Removed} the identity.
 */
public sealed interface RosterEvent {

    /** The aggregates whose removal carries only their identity (WP81's {@code <aggregate>.removed}, empty payload). */
    enum Aggregate {
        TENANT("core.tenant"),
        PERSON("core.person"),
        PLAYER("core.player"),
        TEAM("core.team"),
        TEAM_PLAYER("core.team-player");

        private final String topic;

        Aggregate(String topic) {
            this.topic = topic;
        }

        public String topic() {
            return topic;
        }
    }

    EventEnvelope envelope();

    /** The topic the event came from (kept with the applied event id). */
    String topic();

    record TenantChanged(EventEnvelope envelope, TenantStatus status, ZoneId timezone) implements RosterEvent {
        @Override
        public String topic() {
            return "core.tenant";
        }
    }

    /** @param subject the Keycloak {@code sub} of the member's login, empty while they have none */
    record PersonChanged(EventEnvelope envelope, String displayName, Optional<String> subject, Set<TenantRole> roles,
            boolean active) implements RosterEvent {

        public PersonChanged {
            roles = Set.copyOf(roles);
        }

        @Override
        public String topic() {
            return "core.person";
        }
    }

    record PlayerChanged(EventEnvelope envelope, UUID personId, String displayName, String status,
            Optional<LocalDate> birthDate, Optional<String> gender) implements RosterEvent {
        @Override
        public String topic() {
            return "core.player";
        }
    }

    record TeamChanged(EventEnvelope envelope, SeasonId seasonId, LocalDate seasonEndDate, String name)
            implements RosterEvent {
        @Override
        public String topic() {
            return "core.team";
        }
    }

    record TeamPlayerChanged(EventEnvelope envelope, TeamId teamId, PlayerId playerId, Optional<String> jerseyNumber,
            LocalDate joinedOn, Optional<LocalDate> leftOn, Optional<String> invalidReason) implements RosterEvent {
        @Override
        public String topic() {
            return "core.team-player";
        }
    }

    record TeamStaffChanged(EventEnvelope envelope, TeamId teamId, UUID personId, String role) implements RosterEvent {
        @Override
        public String topic() {
            return "core.team-staff";
        }
    }

    record TeamStaffRemoved(EventEnvelope envelope, TeamId teamId, UUID personId) implements RosterEvent {
        @Override
        public String topic() {
            return "core.team-staff";
        }
    }

    record GuardianLinkChanged(EventEnvelope envelope, UUID guardianPersonId, PlayerId playerId) implements RosterEvent {
        @Override
        public String topic() {
            return "core.guardian-link";
        }
    }

    record GuardianLinkRemoved(EventEnvelope envelope, UUID guardianPersonId, PlayerId playerId) implements RosterEvent {
        @Override
        public String topic() {
            return "core.guardian-link";
        }
    }

    /**
     * A person, player, team, team assignment or tenant core deleted (WP81): the replica keeps the row as removed, with
     * nothing but its identity, so a late older change cannot bring it back (ADR-0037 point 3, WP82).
     */
    record Removed(EventEnvelope envelope, Aggregate aggregate) implements RosterEvent {
        @Override
        public String topic() {
            return aggregate.topic();
        }
    }
}
