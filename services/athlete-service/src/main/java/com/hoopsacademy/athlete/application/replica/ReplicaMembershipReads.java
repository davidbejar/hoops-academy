package com.hoopsacademy.athlete.application.replica;

import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Collection;
import java.util.Optional;
import java.util.Set;

/** Replica reads behind the membership of a login in the BOUND tenant (RLS); each mirrors one of core's queries. */
public interface ReplicaMembershipReads {

    /** The tenant's lifecycle status and zone, as last published by core. */
    record TenantState(String status, ZoneId timezone) {

        public boolean active() {
            return "ACTIVE".equals(status);
        }
    }

    /** An active person with the login. */
    record Member(PersonId personId, Set<TenantRole> roles) {}

    Optional<TenantState> tenant(TenantId tenant);

    Optional<Member> activeMemberWithLogin(String subject);

    Optional<PlayerId> playerOf(PersonId person);

    Set<PlayerId> guardedPlayers(PersonId guardian);

    Set<TeamId> staffTeams(PersonId person);

    /** Teams with an open, valid assignment of one of the players. */
    Set<TeamId> openValidTeamsOf(Collection<PlayerId> players);

    /** The teams (of those known) whose season ends today or later. */
    Set<TeamId> seasonNotEnded(Collection<TeamId> teams, LocalDate today);

    /** The teams (of those known) whose season ended before {@code today} (ADR-0042). */
    Set<TeamId> seasonEnded(Collection<TeamId> teams, LocalDate today);
}
