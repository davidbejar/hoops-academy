package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.TeamId;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/** In-memory {@link RosterReplicaQueries} for the rule tests: answers what the tables would hold. */
class FakeRosterQueries implements RosterReplicaQueries {

    final Map<TenantId, ReplicaTenant> tenants = new HashMap<>();
    final Map<TeamId, ReplicaTeam> teams = new HashMap<>();
    final Map<TeamId, List<RosterLine>> rosters = new HashMap<>();
    final Map<PlayerId, ReplicaPlayer> players = new LinkedHashMap<>();
    final List<Collection<PlayerId>> playerQueries = new ArrayList<>();
    final List<TeamId> rosterQueries = new ArrayList<>();

    @Override
    public Optional<ReplicaTenant> tenant(TenantId tenantId) {
        return Optional.ofNullable(tenants.get(tenantId));
    }

    @Override
    public Optional<ReplicaTeam> team(TeamId teamId) {
        return Optional.ofNullable(teams.get(teamId));
    }

    @Override
    public List<RosterLine> roster(TeamId teamId) {
        rosterQueries.add(teamId);
        return rosters.getOrDefault(teamId, List.of());
    }

    @Override
    public List<ReplicaPlayer> players(Collection<PlayerId> ids) {
        playerQueries.add(List.copyOf(ids));
        return ids.stream().map(players::get).filter(java.util.Objects::nonNull).toList();
    }
}
