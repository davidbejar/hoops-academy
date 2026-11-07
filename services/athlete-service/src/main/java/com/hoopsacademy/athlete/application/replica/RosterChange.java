package com.hoopsacademy.athlete.application.replica;

import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * The payload of one core roster event, reduced to what athlete reads (RosterPort and the membership). A
 * {@code *Changed} carries the aggregate's whole current state (state transfer), a {@code *Removed} its identity.
 */
public sealed interface RosterChange {

    RosterTopic topic();

    record PersonChanged(String displayName, Optional<String> subject, Set<TenantRole> roles, boolean active)
            implements RosterChange {

        public PersonChanged {
            roles = Set.copyOf(roles);
        }

        @Override
        public RosterTopic topic() {
            return RosterTopic.PERSON;
        }
    }

    record PlayerChanged(PersonId personId, String displayName, String status, Optional<LocalDate> birthDate,
            Optional<Gender> gender) implements RosterChange {

        @Override
        public RosterTopic topic() {
            return RosterTopic.PLAYER;
        }
    }

    record TeamChanged(UUID seasonId, LocalDate seasonEndDate, String name) implements RosterChange {

        @Override
        public RosterTopic topic() {
            return RosterTopic.TEAM;
        }
    }

    record TeamPlayerChanged(TeamId teamId, PlayerId playerId, Optional<String> jerseyNumber, LocalDate joinedOn,
            Optional<LocalDate> leftOn, Optional<String> invalidReason) implements RosterChange {

        @Override
        public RosterTopic topic() {
            return RosterTopic.TEAM_PLAYER;
        }
    }

    record TeamStaffChanged(TeamId teamId, PersonId personId, String role, LocalDate since) implements RosterChange {

        @Override
        public RosterTopic topic() {
            return RosterTopic.TEAM_STAFF;
        }
    }

    record TeamStaffRemoved(TeamId teamId, PersonId personId) implements RosterChange {

        @Override
        public RosterTopic topic() {
            return RosterTopic.TEAM_STAFF;
        }
    }

    record GuardianLinkChanged(PersonId guardianPersonId, PlayerId playerId) implements RosterChange {

        @Override
        public RosterTopic topic() {
            return RosterTopic.GUARDIAN_LINK;
        }
    }

    record GuardianLinkRemoved(PersonId guardianPersonId, PlayerId playerId) implements RosterChange {

        @Override
        public RosterTopic topic() {
            return RosterTopic.GUARDIAN_LINK;
        }
    }

    record TenantChanged(String status, ZoneId timezone) implements RosterChange {

        @Override
        public RosterTopic topic() {
            return RosterTopic.TENANT;
        }
    }

    /**
     * A person, player, team, team assignment or tenant core deleted (WP81, empty payload): the replica keeps the row of
     * the event's aggregate id as removed, with nothing but its identity (WP82, ADR-0037 point 3).
     */
    record Removed(RosterTopic topic) implements RosterChange {}
}
