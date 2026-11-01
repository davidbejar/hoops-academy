package com.hoopsacademy.athlete.domain;

import java.time.Instant;
import java.util.Objects;

/** The recorded attendance of one player at one session. {@code minutesLate} exists iff the status is LATE. */
public record Attendance(
        SessionId sessionId,
        PlayerId playerId,
        AttendanceStatus status,
        Integer minutesLate,
        String note,
        Actor recordedBy,
        Instant recordedAt) {

    private static final int MAX_MINUTES_LATE = 480;

    public Attendance {
        Objects.requireNonNull(sessionId, "sessionId");
        Objects.requireNonNull(playerId, "playerId");
        Objects.requireNonNull(status, "status");
        Objects.requireNonNull(recordedBy, "recordedBy");
        Objects.requireNonNull(recordedAt, "recordedAt");
        if (status == AttendanceStatus.LATE) {
            if (minutesLate == null || minutesLate < 1 || minutesLate > MAX_MINUTES_LATE) {
                throw new TrainingRuleViolation("minutesLate (1..480) is required for LATE", "MINUTES_LATE_REQUIRED");
            }
        } else if (minutesLate != null) {
            throw new TrainingRuleViolation("minutesLate is only allowed for LATE", "MINUTES_LATE_NOT_ALLOWED");
        }
    }
}
