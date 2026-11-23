package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Roster data owned by core-service (ADR-0008), read from the local replica (the default, ADR-0037) or from core's
 * cached REST API (the fallback), chosen by {@code hoops.roster.source}; within one request each team's roster is read
 * once. The caller's membership (roles, relations, tenant zone, player teams) arrives as the request's
 * {@code AuthzContext}. Every method may throw {@link com.hoopsacademy.common.problem.UpstreamUnavailableException}
 * (503).
 */
public interface RosterPort {

    /** @throws NotFoundException when the team does not exist in the tenant */
    TeamRoster teamRoster(TenantId tenant, TeamId team);

    /** Players found by id; unknown ids are simply absent from the result. */
    Map<PlayerId, PlayerBrief> players(TenantId tenant, Collection<PlayerId> ids);

    /** Is the player known in the tenant? */
    default boolean playerExists(TenantId tenant, PlayerId id) {
        return players(tenant, java.util.List.of(id)).containsKey(id);
    }

    /**
     * The teams among {@code candidates} whose current roster has at least one of {@code players}, whatever their
     * season; a team the source does not know is left out. This default reads each candidate's roster; the replica
     * answers with one query.
     */
    default Set<TeamId> teamsOf(TenantId tenant, Collection<PlayerId> players, Collection<TeamId> candidates) {
        if (players.isEmpty()) {
            return Set.of();
        }
        return candidates.stream()
                .filter(team -> knownRoster(tenant, team).filter(roster -> players.stream().anyMatch(roster::hasPlayer))
                        .isPresent())
                .collect(Collectors.toCollection(LinkedHashSet::new));
    }

    private Optional<TeamRoster> knownRoster(TenantId tenant, TeamId team) {
        try {
            return Optional.of(teamRoster(tenant, team));
        } catch (NotFoundException unknownTeam) {
            return Optional.empty();
        }
    }
}
