package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.TeamId;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Reads of the roster replica (ADR-0037) in the tenant bound to the current transaction (RLS). Removed rows (WP82) are
 * never returned, nor guardian links to a removed player; assignments only when open and valid and their player is
 * known and not removed.
 */
public interface RosterReplicaQueries {

    /** The tenant's own row; empty when it is not the bound tenant or core never reported it. */
    Optional<ReplicaTenant> tenant(TenantId tenantId);

    Optional<ReplicaTeam> team(TeamId teamId);

    /** The team's open, valid assignments of known players, in joining order. */
    List<RosterLine> roster(TeamId teamId);

    /** The known players among {@code ids}. */
    List<ReplicaPlayer> players(Collection<PlayerId> ids);

    /** The active person whose login is {@code subject}. */
    Optional<ReplicaPerson> activePerson(String subject);

    /** The person's own player record. */
    Optional<PlayerId> playerOf(UUID personId);

    /** The players the person is guardian of. */
    Set<PlayerId> linkedPlayers(UUID guardianPersonId);

    /** The teams the person is staff of. */
    Set<TeamId> staffTeams(UUID personId);

    /** The teams with an open, valid assignment of one of {@code players}. */
    Set<TeamId> openValidTeamsOf(Collection<PlayerId> players);

    /** The season end of each known team among {@code teams}. */
    Map<TeamId, LocalDate> seasonEnds(Collection<TeamId> teams);
}
