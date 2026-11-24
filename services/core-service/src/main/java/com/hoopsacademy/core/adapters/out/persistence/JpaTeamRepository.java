package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.common.paging.PageRequest;
import com.hoopsacademy.common.paging.PageResult;
import com.hoopsacademy.common.persistence.PagedQuery;
import com.hoopsacademy.core.application.events.RosterChanges;
import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.GenderPolicy;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Clock;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@ApplicationScoped
class JpaTeamRepository implements TeamRepository {

    private final EntityManager em;
    private final RosterChanges changes;
    private final Clock clock;

    JpaTeamRepository(EntityManager em, Clock clock, RosterChanges changes) {
        this.em = em;
        this.changes = changes;
        this.clock = clock;
    }

    @Override
    public void insert(Team team) {
        TeamEntity row = new TeamEntity();
        row.id = team.id().value();
        row.createdAt = clock.instant();
        copy(team, row);
        em.persist(row);
        ConstraintConflicts.flush(em, "TEAM_NAME_TAKEN", "A team with this name exists in the season");
        changes.team(team.id());
    }

    @Override
    public void update(Team team) {
        copy(team, em.find(TeamEntity.class, team.id().value()));
        ConstraintConflicts.flush(em, "TEAM_NAME_TAKEN", "A team with this name exists in the season");
        changes.team(team.id());
    }

    @Override
    public Optional<Team> find(TeamId id) {
        return em.createQuery("select t from TeamEntity t where t.id = :id", TeamEntity.class)
                .setParameter("id", id.value()).getResultStream().findFirst().map(JpaTeamRepository::toDomain);
    }

    @Override
    public List<Team> findAll(Collection<TeamId> ids) {
        if (ids.isEmpty()) {
            return List.of();
        }
        return em.createQuery("select t from TeamEntity t where t.id in :ids", TeamEntity.class)
                .setParameter("ids", ids.stream().map(TeamId::value).toList())
                .getResultStream().map(JpaTeamRepository::toDomain).toList();
    }

    @Override
    public List<Team> inSeasons(Collection<SeasonId> seasons) {
        if (seasons.isEmpty()) {
            return List.of();
        }
        return em.createQuery("select t from TeamEntity t where t.seasonId in :seasons order by t.name, t.id",
                        TeamEntity.class)
                .setParameter("seasons", seasons.stream().map(SeasonId::value).toList())
                .getResultStream().map(JpaTeamRepository::toDomain).toList();
    }

    @Override
    public PageResult<Team> list(TeamFilter filter, PageRequest page) {
        if (filter.onlyTeams().filter(Collection::isEmpty).isPresent()) {
            return new PageResult<>(List.of(), page, 0);
        }
        return PagedQuery.of(em, "from TeamEntity t", "t")
                .whereIf(filter.season(), "t.seasonId = :season", "season", SeasonId::value)
                .whereIf(filter.category(), "t.ageCategoryId = :category", "category", AgeCategoryId::value)
                .whereIf(filter.onlyTeams(), "t.id in :ids", "ids", ids -> ids.stream().map(TeamId::value).toList())
                .orderBy("(select s.startDate from SeasonEntity s where s.id = t.seasonId) desc,"
                        + " (select c.sortRank from AgeCategoryEntity c where c.id = t.ageCategoryId), t.name, t.id")
                .page(page, "select t", TeamEntity.class, JpaTeamRepository::toDomain);
    }

    @Override
    public boolean nameTaken(SeasonId season, String name, Optional<TeamId> except) {
        UUID exceptId = except.map(TeamId::value).orElse(null);
        return em.createQuery("select t.id from TeamEntity t where t.seasonId = :season and t.name = :name", UUID.class)
                .setParameter("season", season.value()).setParameter("name", name)
                .getResultStream().anyMatch(id -> !id.equals(exceptId));
    }

    @Override
    public boolean usesCategory(AgeCategoryId category) {
        return em.createQuery("select count(t) from TeamEntity t where t.ageCategoryId = :category", Long.class)
                .setParameter("category", category.value()).getSingleResult() > 0;
    }

    @Override
    public Map<TeamId, LocalDate> seasonEnds(Collection<TeamId> ids) {
        if (ids.isEmpty()) {
            return Map.of();
        }
        return em.createQuery("select t.id, s.endDate from TeamEntity t, SeasonEntity s where s.id = t.seasonId "
                        + "and t.id in :ids", Object[].class)
                .setParameter("ids", ids.stream().map(TeamId::value).toList())
                .getResultStream()
                .collect(Collectors.toMap(row -> new TeamId((UUID) row[0]), row -> (LocalDate) row[1]));
    }

    @Override
    public long count() {
        return em.createQuery("select count(t) from TeamEntity t", Long.class).getSingleResult();
    }

    private static void copy(Team team, TeamEntity row) {
        row.seasonId = team.season().value();
        row.name = team.name();
        row.alias = team.alias();
        row.ageCategoryId = team.category().value();
        row.genderPolicy = team.genderPolicy().name();
    }

    private static Team toDomain(TeamEntity row) {
        return new Team(new TeamId(row.id), new SeasonId(row.seasonId), row.name, row.alias,
                new AgeCategoryId(row.ageCategoryId), GenderPolicy.valueOf(row.genderPolicy));
    }
}
