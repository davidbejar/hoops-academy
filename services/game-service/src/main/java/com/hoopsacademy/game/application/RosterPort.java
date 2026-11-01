package com.hoopsacademy.game.application;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.TeamId;
import java.util.Collection;
import java.util.List;

/**
 * What game-service needs from core-service (ADR-0008). v1 adapter: REST to core {@code /internal/**}; v2 may read
 * local replicas instead. Every method may throw {@link com.hoopsacademy.common.problem.UpstreamUnavailableException}
 * (mapped to 503 by common-quarkus). The caller's membership is resolved by common-quarkus'
 * {@code RosterAuthzResolver} over the same shared client.
 */
public interface RosterPort {

    /**
     * Current roster of a team.
     *
     * @throws com.hoopsacademy.common.problem.NotFoundException when the team (or tenant) is unknown to core
     */
    TeamRoster teamRoster(TenantId tenantId, TeamId teamId);

    /** Minimal data of the given players; unknown ids are simply absent from the answer. */
    List<PlayerBrief> players(TenantId tenantId, Collection<PlayerId> ids);

}
