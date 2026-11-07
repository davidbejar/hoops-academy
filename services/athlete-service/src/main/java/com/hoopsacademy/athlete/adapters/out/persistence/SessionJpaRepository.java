package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.PageResult;
import com.hoopsacademy.athlete.application.SessionQuery;
import com.hoopsacademy.athlete.application.SessionRepository;
import com.hoopsacademy.athlete.domain.ScheduleId;
import com.hoopsacademy.athlete.domain.SessionId;
import com.hoopsacademy.athlete.domain.SessionStatus;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.domain.TrainingSession;
import com.hoopsacademy.common.paging.PageOffset;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

@ApplicationScoped
class SessionJpaRepository implements SessionRepository {

    private final EntityManager em;

    SessionJpaRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public void save(TrainingSession session) {
        SessionEntity entity = em.find(SessionEntity.class, session.id().value());
        boolean created = false;
        if (entity == null) {
            entity = new SessionEntity();
            entity.id = session.id().value();
            created = true;
        }
        entity.teamId = session.teamId().value();
        entity.scheduleId = session.schedule().map(ScheduleId::value).orElse(null);
        entity.startsAt = session.startsAt();
        entity.endsAt = session.endsAt();
        entity.location = session.location();
        entity.planId = session.planId();
        entity.status = session.status().name();
        entity.notes = session.notes();
        entity.cancelReason = session.cancelReason();
        entity.manuallyEdited = session.manuallyEdited();
        if (created) {
            em.persist(entity);
        }
    }

    @Override
    public void saveAll(Collection<TrainingSession> sessions) {
        sessions.forEach(this::save);
    }

    @Override
    public Optional<TrainingSession> find(SessionId id) {
        return Optional.ofNullable(em.find(SessionEntity.class, id.value())).map(SessionJpaRepository::toDomain);
    }

    @Override
    public void delete(Collection<SessionId> ids) {
        if (ids.isEmpty()) {
            return;
        }
        em.flush(); // a bulk delete only auto-flushes its own table; keep pending schedule changes ordered before it
        em.createQuery("delete from SessionEntity s where s.id in :ids")
                .setParameter("ids", ids.stream().map(SessionId::value).toList())
                .executeUpdate();
    }

    @Override
    public PageResult<TrainingSession> list(SessionQuery query) {
        if (query.teams() != null && query.teams().isEmpty()) {
            return new PageResult<>(List.of(), query.page(), query.size(), 0);
        }
        StringBuilder where = new StringBuilder(" where s.startsAt >= :from and s.startsAt < :to");
        if (query.teams() != null) {
            where.append(" and s.teamId in :teams");
        }
        query.status().ifPresent(st -> where.append(" and s.status = :status"));
        TypedQuery<SessionEntity> select =
                em.createQuery("select s from SessionEntity s" + where + " order by s.startsAt, s.id", SessionEntity.class);
        TypedQuery<Long> count = em.createQuery("select count(s) from SessionEntity s" + where, Long.class);
        for (TypedQuery<?> q : List.of(select, count)) {
            q.setParameter("from", query.from());
            q.setParameter("to", query.to());
            if (query.teams() != null) {
                q.setParameter("teams", query.teams().stream().map(TeamId::value).toList());
            }
            query.status().ifPresent(st -> q.setParameter("status", st.name()));
        }
        List<TrainingSession> items = select.setFirstResult(PageOffset.of(query.page(), query.size()))
                .setMaxResults(query.size()).getResultList().stream().map(SessionJpaRepository::toDomain).toList();
        return new PageResult<>(items, query.page(), query.size(), count.getSingleResult());
    }

    @Override
    public List<TrainingSession> findBySchedules(Collection<ScheduleId> schedules, Instant from, Instant to) {
        if (schedules.isEmpty()) {
            return List.of();
        }
        return em.createQuery("select s from SessionEntity s where s.scheduleId in :ids and s.startsAt >= :from "
                        + "and s.startsAt < :to order by s.startsAt", SessionEntity.class)
                .setParameter("ids", schedules.stream().map(ScheduleId::value).toList())
                .setParameter("from", from)
                .setParameter("to", to)
                .getResultList().stream().map(SessionJpaRepository::toDomain).toList();
    }

    @Override
    public List<TrainingSession> findFutureBySchedule(ScheduleId schedule, Instant from) {
        return em.createQuery("select s from SessionEntity s where s.scheduleId = :id and s.startsAt >= :from "
                        + "order by s.startsAt", SessionEntity.class)
                .setParameter("id", schedule.value())
                .setParameter("from", from)
                .getResultList().stream().map(SessionJpaRepository::toDomain).toList();
    }

    @Override
    public long count() {
        return em.createQuery("select count(s) from SessionEntity s", Long.class).getSingleResult();
    }

    private static TrainingSession toDomain(SessionEntity e) {
        return new TrainingSession(new SessionId(e.id), new TeamId(e.teamId),
                e.scheduleId == null ? null : new ScheduleId(e.scheduleId), e.startsAt, e.endsAt, e.location,
                e.planId, SessionStatus.valueOf(e.status), e.notes, e.cancelReason, e.manuallyEdited);
    }
}
