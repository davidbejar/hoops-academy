package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.PageResult;
import com.hoopsacademy.athlete.application.TestResultRepository;
import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PhysicalTestResult;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TestResultId;
import com.hoopsacademy.athlete.domain.TestTypeId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

@ApplicationScoped
class TestResultJpaRepository implements TestResultRepository {

    private final EntityManager em;

    TestResultJpaRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public void save(PhysicalTestResult result) {
        TestResultEntity entity = em.find(TestResultEntity.class, result.id().value());
        boolean created = entity == null;
        if (created) {
            entity = new TestResultEntity();
            entity.id = result.id().value();
            entity.recordedByPersonId = result.recordedBy().personId().value();
            entity.recordedByName = result.recordedBy().displayName();
            entity.createdAt = result.createdAt();
        }
        entity.playerId = result.playerId().value();
        entity.testTypeId = result.testTypeId().value();
        entity.measuredOn = result.measuredOn();
        entity.value = result.value();
        entity.notes = result.notes();
        entity.updatedAt = result.updatedAt();
        if (created) {
            em.persist(entity);
        }
    }

    @Override
    public Optional<PhysicalTestResult> find(TestResultId id) {
        return Optional.ofNullable(em.find(TestResultEntity.class, id.value())).map(TestResultJpaRepository::toDomain);
    }

    @Override
    public void delete(TestResultId id) {
        TestResultEntity entity = em.find(TestResultEntity.class, id.value());
        if (entity != null) {
            em.remove(entity);
        }
    }

    @Override
    public boolean existsForType(TestTypeId type) {
        return em.createQuery("select count(r) from TestResultEntity r where r.testTypeId = :type", Long.class)
                .setParameter("type", type.value()).getSingleResult() > 0;
    }

    @Override
    public PageResult<PhysicalTestResult> search(Collection<PlayerId> players, Optional<TestTypeId> type, LocalDate from,
            LocalDate to, int page, int size) {
        if (players != null && players.isEmpty()) {
            return new PageResult<>(List.of(), page, size, 0);
        }
        String where = " where r.measuredOn >= :from and r.measuredOn <= :to" + (players != null ? " and r.playerId in :players" : "")
                + (type.isPresent() ? " and r.testTypeId = :type" : "");
        TypedQuery<TestResultEntity> select = em.createQuery(
                "select r from TestResultEntity r" + where + " order by r.measuredOn desc, r.id", TestResultEntity.class);
        TypedQuery<Long> count = em.createQuery("select count(r) from TestResultEntity r" + where, Long.class);
        for (TypedQuery<?> q : List.of(select, count)) {
            q.setParameter("from", from);
            q.setParameter("to", to);
            if (players != null) {
                q.setParameter("players", players.stream().map(PlayerId::value).toList());
            }
            type.ifPresent(t -> q.setParameter("type", t.value()));
        }
        List<PhysicalTestResult> items = select.setFirstResult(page * size).setMaxResults(size).getResultList().stream()
                .map(TestResultJpaRepository::toDomain).toList();
        return new PageResult<>(items, page, size, count.getSingleResult());
    }

    @Override
    public long count() {
        return em.createQuery("select count(r) from TestResultEntity r", Long.class).getSingleResult();
    }

    private static PhysicalTestResult toDomain(TestResultEntity e) {
        return new PhysicalTestResult(new TestResultId(e.id), new PlayerId(e.playerId), new TestTypeId(e.testTypeId),
                e.measuredOn, e.value, e.notes, new Actor(new PersonId(e.recordedByPersonId), e.recordedByName), e.createdAt,
                e.updatedAt);
    }
}
