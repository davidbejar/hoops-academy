package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.athlete.application.AttendanceRepository;
import com.hoopsacademy.athlete.domain.Actor;
import com.hoopsacademy.athlete.domain.Attendance;
import com.hoopsacademy.athlete.domain.AttendanceStatus;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.SessionId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@ApplicationScoped
class AttendanceJpaRepository implements AttendanceRepository {

    private final EntityManager em;

    AttendanceJpaRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public List<Attendance> findBySession(SessionId session) {
        return em.createQuery("select a from AttendanceEntity a where a.sessionId = :s order by a.playerId",
                        AttendanceEntity.class)
                .setParameter("s", session.value())
                .getResultList().stream().map(AttendanceJpaRepository::toDomain).toList();
    }

    @Override
    public void upsertAll(Collection<Attendance> attendance) {
        for (Attendance a : attendance) {
            AttendanceKey key = new AttendanceKey(a.sessionId().value(), a.playerId().value());
            AttendanceEntity entity = em.find(AttendanceEntity.class, key);
            boolean created = false;
            if (entity == null) {
                entity = new AttendanceEntity();
                entity.sessionId = key.sessionId;
                entity.playerId = key.playerId;
                created = true;
            }
            entity.status = a.status().name();
            entity.minutesLate = a.minutesLate();
            entity.note = a.note();
            entity.recordedByPersonId = a.recordedBy().personId().value();
            entity.recordedByName = a.recordedBy().displayName();
            entity.recordedAt = a.recordedAt();
            if (created) {
                em.persist(entity);
            }
        }
        em.flush();
    }

    @Override
    public Set<SessionId> sessionsWithAttendance(Collection<SessionId> sessions) {
        if (sessions.isEmpty()) {
            return Set.of();
        }
        List<UUID> ids = em.createQuery("select distinct a.sessionId from AttendanceEntity a where a.sessionId in :ids",
                        UUID.class)
                .setParameter("ids", sessions.stream().map(SessionId::value).toList())
                .getResultList();
        Set<SessionId> result = new HashSet<>();
        ids.forEach(id -> result.add(new SessionId(id)));
        return result;
    }

    @Override
    public long count() {
        return em.createQuery("select count(a) from AttendanceEntity a", Long.class).getSingleResult();
    }

    private static Attendance toDomain(AttendanceEntity e) {
        return new Attendance(new SessionId(e.sessionId), new PlayerId(e.playerId), AttendanceStatus.valueOf(e.status),
                e.minutesLate, e.note, new Actor(new PersonId(e.recordedByPersonId), e.recordedByName), e.recordedAt);
    }
}
