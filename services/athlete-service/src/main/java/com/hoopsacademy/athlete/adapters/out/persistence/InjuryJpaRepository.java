package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.InjuryRepository;
import com.hoopsacademy.athlete.application.PageResult;
import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.Injury;
import com.hoopsacademy.athlete.domain.InjuryId;
import com.hoopsacademy.athlete.domain.InjurySeverity;
import com.hoopsacademy.athlete.domain.InjuryStatus;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.common.paging.PageOffset;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

@ApplicationScoped
class InjuryJpaRepository implements InjuryRepository {

    private final EntityManager em;

    InjuryJpaRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public void save(Injury injury) {
        InjuryEntity entity = em.find(InjuryEntity.class, injury.id().value());
        boolean created = entity == null;
        if (created) {
            entity = new InjuryEntity();
            entity.id = injury.id().value();
            entity.reportedByPersonId = injury.reportedBy().personId().value();
            entity.reportedByName = injury.reportedBy().displayName();
            entity.createdAt = injury.createdAt();
        }
        entity.playerId = injury.playerId().value();
        entity.occurredOn = injury.occurredOn();
        entity.bodyPart = injury.bodyPart();
        entity.description = injury.description();
        entity.severity = injury.severity().name();
        entity.expectedReturnOn = injury.expectedReturnOn().orElse(null);
        entity.actualReturnOn = injury.actualReturnOn().orElse(null);
        entity.status = injury.status().name();
        entity.updatedAt = injury.updatedAt();
        if (created) {
            em.persist(entity);
        }
    }

    @Override
    public Optional<Injury> find(InjuryId id) {
        return Optional.ofNullable(em.find(InjuryEntity.class, id.value())).map(InjuryJpaRepository::toDomain);
    }

    @Override
    public void delete(InjuryId id) {
        InjuryEntity entity = em.find(InjuryEntity.class, id.value());
        if (entity != null) {
            em.remove(entity);
        }
    }

    @Override
    public PageResult<Injury> search(Collection<PlayerId> players, Optional<InjuryStatus> status,
            Optional<LocalDate> occurredUntil, int page, int size) {
        if (players != null && players.isEmpty()) {
            return new PageResult<>(List.of(), page, size, 0);
        }
        String where = " where 1 = 1" + (players != null ? " and i.playerId in :players" : "")
                + (status.isPresent() ? " and i.status = :status" : "")
                + (occurredUntil.isPresent() ? " and i.occurredOn <= :until" : "");
        TypedQuery<InjuryEntity> select = em.createQuery(
                "select i from InjuryEntity i" + where + " order by i.occurredOn desc, i.id", InjuryEntity.class);
        TypedQuery<Long> count = em.createQuery("select count(i) from InjuryEntity i" + where, Long.class);
        for (TypedQuery<?> q : List.of(select, count)) {
            if (players != null) {
                q.setParameter("players", players.stream().map(PlayerId::value).toList());
            }
            status.ifPresent(s -> q.setParameter("status", s.name()));
            occurredUntil.ifPresent(until -> q.setParameter("until", until));
        }
        List<Injury> items = select.setFirstResult(PageOffset.of(page, size)).setMaxResults(size).getResultList().stream()
                .map(InjuryJpaRepository::toDomain).toList();
        return new PageResult<>(items, page, size, count.getSingleResult());
    }

    @Override
    public List<Injury> openOf(PlayerId player) {
        return em.createQuery("select i from InjuryEntity i where i.playerId = :player and i.status = 'OPEN' "
                        + "order by i.occurredOn desc, i.id", InjuryEntity.class)
                .setParameter("player", player.value()).getResultList().stream().map(InjuryJpaRepository::toDomain).toList();
    }

    @Override
    public long count() {
        return em.createQuery("select count(i) from InjuryEntity i", Long.class).getSingleResult();
    }

    private static Injury toDomain(InjuryEntity e) {
        return new Injury(new InjuryId(e.id), new PlayerId(e.playerId), e.occurredOn, e.bodyPart, e.description,
                InjurySeverity.valueOf(e.severity), Optional.ofNullable(e.expectedReturnOn), Optional.ofNullable(e.actualReturnOn),
                InjuryStatus.valueOf(e.status), new Actor(new PersonId(e.reportedByPersonId), e.reportedByName), e.createdAt,
                e.updatedAt);
    }
}
