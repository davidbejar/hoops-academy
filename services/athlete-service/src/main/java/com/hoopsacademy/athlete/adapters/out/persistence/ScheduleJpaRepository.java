package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.ScheduleRepository;
import com.hoopsacademy.athlete.domain.ScheduleId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.domain.TrainingSchedule;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@ApplicationScoped
class ScheduleJpaRepository implements ScheduleRepository {

    private final EntityManager em;

    ScheduleJpaRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public void save(TrainingSchedule schedule) {
        ScheduleEntity entity = em.find(ScheduleEntity.class, schedule.id().value());
        boolean created = false;
        if (entity == null) {
            entity = new ScheduleEntity();
            entity.id = schedule.id().value();
            created = true;
        }
        entity.teamId = schedule.teamId().value();
        entity.weekday = (short) schedule.dayOfWeek().getValue();
        entity.startTime = schedule.startTime();
        entity.durationMin = schedule.durationMinutes();
        entity.location = schedule.location();
        entity.validFrom = schedule.validFrom();
        entity.validTo = schedule.validUntil();
        entity.active = schedule.active();
        if (created) {
            em.persist(entity);
        }
    }

    @Override
    public Optional<TrainingSchedule> find(ScheduleId id) {
        return Optional.ofNullable(em.find(ScheduleEntity.class, id.value()))
                .filter(e -> e.active)
                .map(ScheduleJpaRepository::toDomain);
    }

    @Override
    public List<TrainingSchedule> findActive(Optional<TeamId> team, Optional<LocalDate> validOn) {
        StringBuilder jpql = new StringBuilder("select s from ScheduleEntity s where s.active = true");
        team.ifPresent(t -> jpql.append(" and s.teamId = :team"));
        validOn.ifPresent(d -> jpql.append(" and s.validFrom <= :on and (s.validTo is null or s.validTo >= :on)"));
        jpql.append(" order by s.weekday, s.startTime, s.id");
        var query = em.createQuery(jpql.toString(), ScheduleEntity.class);
        team.ifPresent(t -> query.setParameter("team", t.value()));
        validOn.ifPresent(d -> query.setParameter("on", d));
        return query.getResultList().stream().map(ScheduleJpaRepository::toDomain).toList();
    }

    @Override
    public long count() {
        return em.createQuery("select count(s) from ScheduleEntity s", Long.class).getSingleResult();
    }

    private static TrainingSchedule toDomain(ScheduleEntity e) {
        return new TrainingSchedule(new ScheduleId(e.id), new TeamId(e.teamId), DayOfWeek.of(e.weekday), e.startTime,
                e.durationMin, e.location, e.validFrom, e.validTo, e.active);
    }
}
