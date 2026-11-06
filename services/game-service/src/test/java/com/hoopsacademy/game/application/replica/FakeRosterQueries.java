package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.TeamId;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/** In-memory {@link RosterReplicaQueries} for the rule tests: answers what the tables would hold. */
class FakeRosterQueries implements RosterReplicaQueries {

    final Map<TenantId, ReplicaTenant> tenants = new HashMap<>();
    final Map<TeamId, ReplicaTeam> teams = new HashMap<>();
    final Map<TeamId, List<RosterLine>> rosters = new HashMap<>();
    final Map<PlayerId, ReplicaPlayer> players = new LinkedHashMap<>();
    final Map<String, ReplicaPerson> persons = new HashMap<>();
    final Map<UUID, PlayerId> ownPlayers = new HashMap<>();
    final Map<UUID, Set<PlayerId>> links = new HashMap<>();
    final Map<UUID, Set<TeamId>> staff = new HashMap<>();
    final Map<PlayerId, Set<TeamId>> assignments = new HashMap<>();
    final List<Collection<PlayerId>> playerQueries = new ArrayList<>();

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
        return rosters.getOrDefault(teamId, List.of());
    }

    @Override
    public List<ReplicaPlayer> players(Collection<PlayerId> ids) {
        playerQueries.add(List.copyOf(ids));
        return ids.stream().map(players::get).filter(java.util.Objects::nonNull).toList();
    }

    @Override
    public Optional<ReplicaPerson> activePerson(String subject) {
        return Optional.ofNullable(persons.get(subject));
    }

    @Override
    public Optional<PlayerId> playerOf(UUID personId) {
        return Optional.ofNullable(ownPlayers.get(personId));
    }

    @Override
    public Set<PlayerId> linkedPlayers(UUID guardianPersonId) {
        return links.getOrDefault(guardianPersonId, Set.of());
    }

    @Override
    public Set<TeamId> staffTeams(UUID personId) {
        return staff.getOrDefault(personId, Set.of());
    }

    @Override
    public Set<TeamId> openValidTeamsOf(Collection<PlayerId> playerIds) {
        Set<TeamId> result = new HashSet<>();
        playerIds.forEach(id -> result.addAll(assignments.getOrDefault(id, Set.of())));
        return result;
    }

    @Override
    public Map<TeamId, LocalDate> seasonEnds(Collection<TeamId> teamIds) {
        return teamIds.stream().filter(teams::containsKey)
                .collect(Collectors.toMap(id -> id, id -> teams.get(id).seasonEndDate()));
    }
}
