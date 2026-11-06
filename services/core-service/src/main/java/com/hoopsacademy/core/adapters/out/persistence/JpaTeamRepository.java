package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.TeamRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import com.hoopsacademy.core.domain.roster.GenderPolicy;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.time.Clock;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@ApplicationScoped
class JpaTeamRepository implements TeamRepository {

    private final EntityManager em;
    private final Clock clock;

    JpaTeamRepository(EntityManager em, Clock clock) {
        this.em = em;
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
    }

    @Override
    public void update(Team team) {
        copy(team, em.find(TeamEntity.class, team.id().value()));
        ConstraintConflicts.flush(em, "TEAM_NAME_TAKEN", "A team with this name exists in the season");
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
        List<String> conditions = new ArrayList<>();
        filter.season().ifPresent(s -> conditions.add("t.seasonId = :season"));
        filter.category().ifPresent(c -> conditions.add("t.ageCategoryId = :category"));
        filter.onlyTeams().ifPresent(ids -> conditions.add("t.id in :ids"));
        String where = conditions.isEmpty() ? "" : " where " + String.join(" and ", conditions);
        TypedQuery<TeamEntity> items = em.createQuery("select t from TeamEntity t" + where
                + " order by (select s.startDate from SeasonEntity s where s.id = t.seasonId) desc,"
                + " (select c.sortRank from AgeCategoryEntity c where c.id = t.ageCategoryId), t.name, t.id",
                TeamEntity.class);
        TypedQuery<Long> total = em.createQuery("select count(t) from TeamEntity t" + where, Long.class);
        for (TypedQuery<?> query : List.of(items, total)) {
            filter.season().ifPresent(s -> query.setParameter("season", s.value()));
            filter.category().ifPresent(c -> query.setParameter("category", c.value()));
            filter.onlyTeams().ifPresent(ids -> query.setParameter("ids", ids.stream().map(TeamId::value).toList()));
        }
        List<Team> found = items.setFirstResult(page.offset()).setMaxResults(page.size()).getResultStream()
                .map(JpaTeamRepository::toDomain).toList();
        return new PageResult<>(found, page, total.getSingleResult());
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
    public Set<TeamId> seasonNotEnded(Collection<TeamId> ids, LocalDate today) {
        if (ids.isEmpty()) {
            return Set.of();
        }
        return em.createQuery("select t.id from TeamEntity t, SeasonEntity s where s.id = t.seasonId "
                        + "and t.id in :ids and s.endDate >= :today", UUID.class)
                .setParameter("ids", ids.stream().map(TeamId::value).toList())
                .setParameter("today", today)
                .getResultStream().map(TeamId::new).collect(Collectors.toSet());
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
