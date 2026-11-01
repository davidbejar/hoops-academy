package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.tenancy.TenantId;
import java.util.Collection;
import java.util.Map;
import java.util.Optional;

/**
 * Roster and membership data owned by core-service (ADR-0008). v1 is a cached REST adapter; v2 may replace it with
 * a local replica fed by events without touching the use cases.
 */
public interface RosterPort {

    /** @throws com.hoopsacademy.common.problem.NotFoundException when the team does not exist in the tenant */
    TeamRoster teamRoster(TenantId tenant, TeamId team);

    /** Players found by id; unknown ids are simply absent from the result. */
    Map<PlayerId, PlayerBrief> players(TenantId tenant, Collection<PlayerId> ids);

    /** The subject's membership, or empty when they are not a member of the tenant. */
    Optional<MemberContext> authzContext(TenantId tenant, String subject);

    /** Is the player known in the tenant? */
    default boolean playerExists(TenantId tenant, PlayerId id) {
        return players(tenant, java.util.List.of(id)).containsKey(id);
    }
}
