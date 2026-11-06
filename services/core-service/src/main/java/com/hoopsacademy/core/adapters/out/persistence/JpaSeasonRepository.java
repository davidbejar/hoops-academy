package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.events.RosterChanges;
import com.hoopsacademy.core.application.port.SeasonRepository;
import com.hoopsacademy.core.domain.roster.Season;
import com.hoopsacademy.core.domain.roster.SeasonId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@ApplicationScoped
class JpaSeasonRepository implements SeasonRepository {

    static final String OVERLAP = "SEASON_OVERLAP";
    private static final String OVERLAP_MESSAGE = "The season overlaps another season";

    private final EntityManager em;
    private final RosterChanges changes;
    private final Clock clock;

    JpaSeasonRepository(EntityManager em, Clock clock, RosterChanges changes) {
        this.em = em;
        this.changes = changes;
        this.clock = clock;
    }

    @Override
    public void insert(Season season) {
        SeasonEntity row = new SeasonEntity();
        row.id = season.id().value();
        row.createdAt = clock.instant();
        copy(season, row);
        em.persist(row);
        ConstraintConflicts.flush(em, OVERLAP, OVERLAP_MESSAGE);
    }

    @Override
    public void update(Season season) {
        copy(season, em.find(SeasonEntity.class, season.id().value()));
        ConstraintConflicts.flush(em, OVERLAP, OVERLAP_MESSAGE);
        changes.season(season.id());
    }

    @Override
    public Optional<Season> find(SeasonId id) {
        return em.createQuery("select s from SeasonEntity s where s.id = :id", SeasonEntity.class)
                .setParameter("id", id.value()).getResultStream().findFirst().map(JpaSeasonRepository::toDomain);
    }

    @Override
    public List<Season> listNewestFirst() {
        return em.createQuery("select s from SeasonEntity s order by s.startDate desc, s.id", SeasonEntity.class)
                .getResultStream().map(JpaSeasonRepository::toDomain).toList();
    }

    @Override
    public List<Season> notEndedOn(LocalDate day) {
        return em.createQuery("select s from SeasonEntity s where s.endDate >= :day order by s.startDate", SeasonEntity.class)
                .setParameter("day", day).getResultStream().map(JpaSeasonRepository::toDomain).toList();
    }

    @Override
    public long count() {
        return em.createQuery("select count(s) from SeasonEntity s", Long.class).getSingleResult();
    }

    private static void copy(Season season, SeasonEntity row) {
        row.name = season.name();
        row.startDate = season.startsOn();
        row.endDate = season.endsOn();
        row.referenceYear = season.referenceYear();
    }

    static Season toDomain(SeasonEntity row) {
        return new Season(new SeasonId(row.id), row.name, row.startDate, row.endDate, row.referenceYear);
    }
}
