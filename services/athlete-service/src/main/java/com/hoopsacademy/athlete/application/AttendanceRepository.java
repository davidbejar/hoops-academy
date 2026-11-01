package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.Attendance;
import com.hoopsacademy.athlete.domain.SessionId;
import java.util.Collection;
import java.util.List;
import java.util.Set;

public interface AttendanceRepository {

    List<Attendance> findBySession(SessionId session);

    /** Inserts or replaces the attendance of each (session, player). */
    void upsertAll(Collection<Attendance> attendance);

    /** The subset of {@code sessions} that has at least one attendance row. */
    Set<SessionId> sessionsWithAttendance(Collection<SessionId> sessions);

    long count();
}
