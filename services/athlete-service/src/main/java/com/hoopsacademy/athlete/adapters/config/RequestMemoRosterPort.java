package com.hoopsacademy.athlete.adapters.config;

import com.hoopsacademy.athlete.application.PlayerBrief;
import com.hoopsacademy.athlete.application.RosterPort;
import com.hoopsacademy.athlete.application.TeamRoster;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import java.util.Collection;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.function.Supplier;

/**
 * Keeps each {@code teamRoster} answer (a roster, or "not found") for the rest of the request (ATH-01): the access
 * rules ask for the same team several times, which the replica would answer with the same queries again. Nothing
 * outlives the request (ADR-0037 keeps the replica uncached), and outside a request (the nightly job, the consumer)
 * every call goes to the source. A failure of the source (503) is not kept.
 */
final class RequestMemoRosterPort implements RosterPort {

    record TeamKey(TenantId tenant, TeamId team) {}

    /** Exactly one of the two is set. */
    record Answer(TeamRoster roster, NotFoundException notFound) {

        TeamRoster get() {
            if (notFound != null) {
                throw notFound;
            }
            return roster;
        }
    }

    private final RosterPort source;
    private final Supplier<Optional<Map<TeamKey, Answer>>> currentRequest;

    /** @param currentRequest the answers of the running request; empty when no request is active */
    RequestMemoRosterPort(RosterPort source, Supplier<Optional<Map<TeamKey, Answer>>> currentRequest) {
        this.source = source;
        this.currentRequest = currentRequest;
    }

    @Override
    public TeamRoster teamRoster(TenantId tenant, TeamId team) {
        Optional<Map<TeamKey, Answer>> answers = currentRequest.get();
        if (answers.isEmpty()) {
            return source.teamRoster(tenant, team);
        }
        TeamKey key = new TeamKey(tenant, team);
        Answer known = answers.get().get(key);
        if (known == null) {
            known = read(tenant, team);
            answers.get().put(key, known);
        }
        return known.get();
    }

    @Override
    public Map<PlayerId, PlayerBrief> players(TenantId tenant, Collection<PlayerId> ids) {
        return source.players(tenant, ids);
    }

    @Override
    public Set<TeamId> teamsOf(TenantId tenant, Collection<PlayerId> players, Collection<TeamId> candidates) {
        return source.teamsOf(tenant, players, candidates);
    }

    private Answer read(TenantId tenant, TeamId team) {
        try {
            return new Answer(source.teamRoster(tenant, team), null);
        } catch (NotFoundException notFound) {
            return new Answer(null, notFound);
        }
    }
}
