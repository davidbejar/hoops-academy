package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.MeasurementRepository;
import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.BodyMeasurement;
import com.hoopsacademy.athlete.domain.BodyMeasurementId;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@ApplicationScoped
class MeasurementJpaRepository implements MeasurementRepository {

    private final EntityManager em;

    MeasurementJpaRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public void save(BodyMeasurement measurement) {
        MeasurementEntity entity = em.find(MeasurementEntity.class, measurement.id().value());
        boolean created = entity == null;
        if (created) {
            entity = new MeasurementEntity();
            entity.id = measurement.id().value();
            entity.recordedByPersonId = measurement.recordedBy().personId().value();
            entity.recordedByName = measurement.recordedBy().displayName();
            entity.createdAt = measurement.createdAt();
        }
        entity.playerId = measurement.playerId().value();
        entity.measuredOn = measurement.measuredOn();
        entity.heightCm = measurement.heightCm().orElse(null);
        entity.weightKg = measurement.weightKg().orElse(null);
        entity.updatedAt = measurement.updatedAt();
        if (created) {
            em.persist(entity);
        }
    }

    @Override
    public Optional<BodyMeasurement> find(BodyMeasurementId id) {
        return Optional.ofNullable(em.find(MeasurementEntity.class, id.value())).map(MeasurementJpaRepository::toDomain);
    }

    @Override
    public void delete(BodyMeasurementId id) {
        MeasurementEntity entity = em.find(MeasurementEntity.class, id.value());
        if (entity != null) {
            em.remove(entity);
        }
    }

    @Override
    public boolean existsOn(PlayerId player, LocalDate day, Optional<BodyMeasurementId> except) {
        var query = em.createQuery("select count(m) from MeasurementEntity m where m.playerId = :player and m.measuredOn = :day"
                + (except.isPresent() ? " and m.id <> :except" : ""), Long.class)
                .setParameter("player", player.value()).setParameter("day", day);
        except.ifPresent(id -> query.setParameter("except", id.value()));
        return query.getSingleResult() > 0;
    }

    @Override
    public List<BodyMeasurement> history(PlayerId player, LocalDate from, LocalDate to) {
        return em.createQuery("select m from MeasurementEntity m where m.playerId = :player and m.measuredOn >= :from "
                        + "and m.measuredOn <= :to order by m.measuredOn, m.id", MeasurementEntity.class)
                .setParameter("player", player.value()).setParameter("from", from).setParameter("to", to)
                .getResultList().stream().map(MeasurementJpaRepository::toDomain).toList();
    }

    @Override
    public long count() {
        return em.createQuery("select count(m) from MeasurementEntity m", Long.class).getSingleResult();
    }

    private static BodyMeasurement toDomain(MeasurementEntity e) {
        return new BodyMeasurement(new BodyMeasurementId(e.id), new PlayerId(e.playerId), e.measuredOn,
                Optional.ofNullable(e.heightCm), Optional.ofNullable(e.weightKg),
                new Actor(new PersonId(e.recordedByPersonId), e.recordedByName), e.createdAt, e.updatedAt);
    }
}
