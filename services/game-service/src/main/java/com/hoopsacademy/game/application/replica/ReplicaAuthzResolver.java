package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Typed;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * The caller's authorisation context from the local replica (ADR-0037, {@code hoops.roster.source=replica}), with
 * the rules of core's {@code /internal/authz}: an active person with that login in an ACTIVE tenant; their own player
 * with the PLAYER role, their linked players with the PARENT role; staff teams and the teams of the own and linked
 * players' open valid assignments, both without teams whose season ended before today in the academy's time zone.
 * Called by the tenant filter with the requested tenant bound.
 */
@ApplicationScoped
@Typed(ReplicaAuthzResolver.class)
public class ReplicaAuthzResolver implements AuthzContextResolver {

    private final RosterReplicaQueries replica;
    private final Clock clock;

    public ReplicaAuthzResolver(RosterReplicaQueries replica, Clock clock) {
        this.replica = replica;
        this.clock = clock;
    }

    @Override
    @Transactional
    public Optional<AuthzContext> resolve(String subject, TenantId tenantId) {
        return replica.tenant(tenantId).filter(ReplicaTenant::active)
                .flatMap(tenant -> replica.activePerson(subject)
                        .map(person -> contextOf(subject, person, tenantId, tenant.timezone())));
    }

    private AuthzContext contextOf(String subject, ReplicaPerson person, TenantId tenantId, ZoneId zone) {
        Optional<PlayerId> ownPlayer = person.has(TenantRole.PLAYER) ? replica.playerOf(person.id()) : Optional.empty();
        Set<PlayerId> linkedPlayers = person.has(TenantRole.PARENT) ? replica.linkedPlayers(person.id()) : Set.of();
        Set<TeamId> staffTeams = replica.staffTeams(person.id());
        Set<TeamId> playerTeams = teamsOf(ownPlayer, linkedPlayers);
        Set<TeamId> current = seasonNotEnded(staffTeams, playerTeams, LocalDate.ofInstant(clock.instant(), zone));
        return new AuthzContext(subject, person.id(), tenantId, person.roles(), values(staffTeams, current),
                linkedPlayers.stream().map(PlayerId::value).collect(Collectors.toSet()), ownPlayer.map(PlayerId::value),
                values(playerTeams, current), Optional.of(zone));
    }

    private Set<TeamId> teamsOf(Optional<PlayerId> ownPlayer, Set<PlayerId> linkedPlayers) {
        Set<PlayerId> players = new HashSet<>(linkedPlayers);
        ownPlayer.ifPresent(players::add);
        return players.isEmpty() ? Set.of() : replica.openValidTeamsOf(players);
    }

    private Set<TeamId> seasonNotEnded(Set<TeamId> staffTeams, Set<TeamId> playerTeams, LocalDate today) {
        Set<TeamId> candidates = new HashSet<>(staffTeams);
        candidates.addAll(playerTeams);
        return replica.seasonEnds(candidates).entrySet().stream()
                .filter(team -> !team.getValue().isBefore(today))
                .map(Map.Entry::getKey)
                .collect(Collectors.toSet());
    }

    private static Set<UUID> values(Set<TeamId> teams, Set<TeamId> current) {
        return teams.stream().filter(current::contains).map(TeamId::value).collect(Collectors.toSet());
    }
}
