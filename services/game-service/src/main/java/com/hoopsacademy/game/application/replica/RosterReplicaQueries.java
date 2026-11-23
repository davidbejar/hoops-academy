package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.TeamId;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/**
 * Reads of the roster replica (ADR-0037) in the tenant bound to the current transaction (RLS). Removed rows (WP82) are
 * never returned; assignments only when open and valid and their player is known and not removed. The membership
 * reads of the tenant filter are common's {@code MembershipReads} (ADR-0066).
 */
public interface RosterReplicaQueries {

    /** The tenant's own row; empty when it is not the bound tenant or core never reported it. */
    Optional<ReplicaTenant> tenant(TenantId tenantId);

    Optional<ReplicaTeam> team(TeamId teamId);

    /** The team's open, valid assignments of known players, in joining order. */
    List<RosterLine> roster(TeamId teamId);

    /** The known players among {@code ids}. */
    List<ReplicaPlayer> players(Collection<PlayerId> ids);
}
