package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.events.RosterChanges;
import com.hoopsacademy.core.application.port.TeamPlayerRepository;
import com.hoopsacademy.core.domain.eligibility.EligibilityReason;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayer;
import com.hoopsacademy.core.domain.roster.TeamPlayerId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@ApplicationScoped
class JpaTeamPlayerRepository implements TeamPlayerRepository {

    private final EntityManager em;
    private final RosterChanges changes;

    JpaTeamPlayerRepository(EntityManager em, RosterChanges changes) {
        this.em = em;
        this.changes = changes;
    }

    @Override
    public void insert(TeamPlayer assignment) {
        TeamPlayerEntity row = new TeamPlayerEntity();
        row.id = assignment.id().value();
        copy(assignment, row);
        em.persist(row);
        ConstraintConflicts.flush(em, "TEAM_PLAYER_CONFLICT", "The player or jersey is already on the team");
        changes.teamPlayer(assignment.id());
    }

    @Override
    public void update(TeamPlayer assignment) {
        copy(assignment, em.find(TeamPlayerEntity.class, assignment.id().value()));
        ConstraintConflicts.flush(em, "JERSEY_NUMBER_TAKEN", "The jersey number is already used on the team");
        changes.teamPlayer(assignment.id());
    }

    @Override
    public Optional<TeamPlayer> find(TeamPlayerId id) {
        return em.createQuery("select a from TeamPlayerEntity a where a.id = :id", TeamPlayerEntity.class)
                .setParameter("id", id.value()).getResultStream().findFirst().map(JpaTeamPlayerRepository::toDomain);
    }

    @Override
    public Optional<TeamPlayer> findOpen(TeamId team, PlayerId player) {
        return em.createQuery("""
                        select a from TeamPlayerEntity a
                         where a.teamId = :team and a.playerId = :player and a.leftOn is null""", TeamPlayerEntity.class)
                .setParameter("team", team.value()).setParameter("player", player.value())
                .getResultStream().findFirst().map(JpaTeamPlayerRepository::toDomain);
    }

    @Override
    public List<TeamPlayer> ofTeam(TeamId team, boolean includeLeft) {
        return em.createQuery("select a from TeamPlayerEntity a where a.teamId = :team"
                        + (includeLeft ? "" : " and a.leftOn is null") + " order by a.joinedOn, a.id", TeamPlayerEntity.class)
                .setParameter("team", team.value()).getResultStream().map(JpaTeamPlayerRepository::toDomain).toList();
    }

    @Override
    public List<TeamPlayer> openValidOfTeams(Collection<TeamId> teams) {
        if (teams.isEmpty()) {
            return List.of();
        }
        return em.createQuery("""
                        select a from TeamPlayerEntity a
                         where a.teamId in :teams and a.leftOn is null and a.invalidatedAt is null
                         order by a.joinedOn, a.id""", TeamPlayerEntity.class)
                .setParameter("teams", teams.stream().map(TeamId::value).toList())
                .getResultStream().map(JpaTeamPlayerRepository::toDomain).toList();
    }

    @Override
    public List<TeamPlayer> openOfPlayers(Collection<PlayerId> players) {
        if (players.isEmpty()) {
            return List.of();
        }
        return em.createQuery("""
                        select a from TeamPlayerEntity a where a.playerId in :players and a.leftOn is null
                         order by a.joinedOn, a.id""", TeamPlayerEntity.class)
                .setParameter("players", players.stream().map(PlayerId::value).toList())
                .getResultStream().map(JpaTeamPlayerRepository::toDomain).toList();
    }

    @Override
    public boolean jerseyTaken(TeamId team, JerseyNumber jersey, Optional<TeamPlayerId> except) {
        UUID exceptId = except.map(TeamPlayerId::value).orElse(null);
        return em.createQuery("""
                        select a.id from TeamPlayerEntity a
                         where a.teamId = :team and a.jerseyNumber = :jersey and a.leftOn is null""", UUID.class)
                .setParameter("team", team.value()).setParameter("jersey", jersey.value())
                .getResultStream().anyMatch(id -> !id.equals(exceptId));
    }

    @Override
    public Map<TeamId, Long> countOpenValid(Collection<TeamId> teams) {
        if (teams.isEmpty()) {
            return Map.of();
        }
        return em.createQuery("""
                        select a.teamId, count(a) from TeamPlayerEntity a
                         where a.teamId in :teams and a.leftOn is null and a.invalidatedAt is null
                         group by a.teamId""", Object[].class)
                .setParameter("teams", teams.stream().map(TeamId::value).toList())
                .getResultStream()
                .collect(Collectors.toMap(row -> new TeamId((UUID) row[0]), row -> (Long) row[1]));
    }

    private static void copy(TeamPlayer assignment, TeamPlayerEntity row) {
        row.teamId = assignment.team().value();
        row.playerId = assignment.player().value();
        row.jerseyNumber = assignment.jersey() == null ? null : assignment.jersey().value();
        row.joinedOn = assignment.joinedOn();
        row.leftOn = assignment.leftOn();
        row.playUpLevels = assignment.playUpLevels();
        row.invalidatedAt = assignment.invalidatedAt();
        row.invalidReason = assignment.invalidReason() == null ? null : assignment.invalidReason().name();
    }

    private static TeamPlayer toDomain(TeamPlayerEntity row) {
        return new TeamPlayer(new TeamPlayerId(row.id), new TeamId(row.teamId), new PlayerId(row.playerId),
                JerseyNumber.ofNullable(row.jerseyNumber), row.joinedOn, row.leftOn, row.playUpLevels, row.invalidatedAt,
                row.invalidReason == null ? null : EligibilityReason.valueOf(row.invalidReason));
    }
}
