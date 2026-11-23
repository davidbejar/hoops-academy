package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.AbsenceRepository;
import com.hoopsacademy.athlete.application.PageResult;
import com.hoopsacademy.athlete.domain.AbsenceId;
import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlannedAbsence;
import com.hoopsacademy.athlete.domain.PlayerId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

@ApplicationScoped
class AbsenceJpaRepository implements AbsenceRepository {

    private final EntityManager em;

    AbsenceJpaRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public void save(PlannedAbsence absence) {
        AbsenceEntity entity = em.find(AbsenceEntity.class, absence.id().value());
        boolean created = false;
        if (entity == null) {
            entity = new AbsenceEntity();
            entity.id = absence.id().value();
            created = true;
        }
        entity.playerId = absence.playerId().value();
        entity.fromDate = absence.fromDate();
        entity.toDate = absence.toDate();
        entity.reason = absence.reason();
        entity.createdByPersonId = absence.createdBy().personId().value();
        entity.createdByName = absence.createdBy().displayName();
        entity.createdAt = absence.createdAt();
        if (created) {
            em.persist(entity);
        }
    }

    @Override
    public Optional<PlannedAbsence> find(AbsenceId id) {
        return Optional.ofNullable(em.find(AbsenceEntity.class, id.value())).map(AbsenceJpaRepository::toDomain);
    }

    @Override
    public void delete(AbsenceId id) {
        AbsenceEntity entity = em.find(AbsenceEntity.class, id.value());
        if (entity != null) {
            em.remove(entity);
        }
    }

    @Override
    public PageResult<PlannedAbsence> search(Collection<PlayerId> players, LocalDate from, LocalDate to, int page,
            int size) {
        if (players != null && players.isEmpty()) {
            return new PageResult<>(List.of(), page, size, 0);
        }
        PagedQuery<AbsenceEntity> query = PagedQuery.over(em, AbsenceEntity.class, "a")
                .where("a.toDate >= :from and a.fromDate <= :to").bind("from", from).bind("to", to);
        if (players != null) {
            query.where("a.playerId in :players").bind("players", players.stream().map(PlayerId::value).toList());
        }
        return query.page("a.fromDate, a.id", page, size, AbsenceJpaRepository::toDomain);
    }

    @Override
    public List<PlannedAbsence> covering(Collection<PlayerId> players, LocalDate date) {
        if (players.isEmpty()) {
            return List.of();
        }
        return em.createQuery("select a from AbsenceEntity a where a.playerId in :players and a.fromDate <= :d "
                        + "and a.toDate >= :d order by a.createdAt", AbsenceEntity.class)
                .setParameter("players", players.stream().map(PlayerId::value).toList())
                .setParameter("d", date)
                .getResultList().stream().map(AbsenceJpaRepository::toDomain).toList();
    }

    @Override
    public long count() {
        return em.createQuery("select count(a) from AbsenceEntity a", Long.class).getSingleResult();
    }

    private static PlannedAbsence toDomain(AbsenceEntity e) {
        return new PlannedAbsence(new AbsenceId(e.id), new PlayerId(e.playerId), e.fromDate, e.toDate, e.reason,
                new Actor(new PersonId(e.createdByPersonId), e.createdByName), e.createdAt);
    }
}
