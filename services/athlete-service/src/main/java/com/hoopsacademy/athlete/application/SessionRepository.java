package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.ScheduleId;
import com.hoopsacademy.athlete.domain.SessionId;
import com.hoopsacademy.athlete.domain.TrainingSession;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface SessionRepository {

    void save(TrainingSession session);

    void saveAll(Collection<TrainingSession> sessions);

    Optional<TrainingSession> find(SessionId id);

    void delete(Collection<SessionId> ids);

    PageResult<TrainingSession> list(SessionQuery query);

    /** Sessions of the schedules starting in [from, to), whatever their status. */
    List<TrainingSession> findBySchedules(Collection<ScheduleId> schedules, Instant from, Instant to);

    /** Sessions of one schedule starting at or after {@code from}, whatever their status. */
    List<TrainingSession> findFutureBySchedule(ScheduleId schedule, Instant from);

    long count();
}
