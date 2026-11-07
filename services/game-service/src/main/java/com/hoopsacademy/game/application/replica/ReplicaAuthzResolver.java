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
import java.util.function.Predicate;
import java.util.stream.Collectors;

/**
 * The caller's authorisation context from the local replica (ADR-0037, {@code hoops.roster.source=replica}), with
 * the rules of core's {@code /internal/authz}: an active person with that login in an ACTIVE tenant; their own player
 * with the PLAYER role, their linked players with the PARENT role; staff teams and the teams of the own and linked
 * players' open valid assignments, both without teams whose season ended before today in the academy's time zone;
 * the known staff teams whose season ended are the historic staff teams (read-only history, ADR-0042).
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
        Map<TeamId, LocalDate> seasonEnds = seasonEnds(staffTeams, playerTeams);
        LocalDate today = LocalDate.ofInstant(clock.instant(), zone);
        Set<TeamId> current = teamsWhere(seasonEnds, end -> !end.isBefore(today));
        Set<TeamId> ended = teamsWhere(seasonEnds, end -> end.isBefore(today));
        return new AuthzContext(subject, person.id(), tenantId, person.roles(), values(staffTeams, current),
                linkedPlayers.stream().map(PlayerId::value).collect(Collectors.toSet()), ownPlayer.map(PlayerId::value),
                values(playerTeams, current), Optional.of(zone), values(staffTeams, ended));
    }

    private Set<TeamId> teamsOf(Optional<PlayerId> ownPlayer, Set<PlayerId> linkedPlayers) {
        Set<PlayerId> players = new HashSet<>(linkedPlayers);
        ownPlayer.ifPresent(players::add);
        return players.isEmpty() ? Set.of() : replica.openValidTeamsOf(players);
    }

    /** The season end of each known team among both sets (unknown teams count neither as current nor as ended). */
    private Map<TeamId, LocalDate> seasonEnds(Set<TeamId> staffTeams, Set<TeamId> playerTeams) {
        Set<TeamId> candidates = new HashSet<>(staffTeams);
        candidates.addAll(playerTeams);
        return replica.seasonEnds(candidates);
    }

    private static Set<TeamId> teamsWhere(Map<TeamId, LocalDate> seasonEnds, Predicate<LocalDate> seasonEnd) {
        return seasonEnds.entrySet().stream().filter(team -> seasonEnd.test(team.getValue())).map(Map.Entry::getKey)
                .collect(Collectors.toSet());
    }

    private static Set<UUID> values(Set<TeamId> teams, Set<TeamId> current) {
        return teams.stream().filter(current::contains).map(TeamId::value).collect(Collectors.toSet());
    }
}
