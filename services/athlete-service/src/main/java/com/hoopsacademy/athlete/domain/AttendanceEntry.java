package com.hoopsacademy.athlete.domain;

import java.util.Optional;

/** One line of a session's attendance sheet: the recorded attendance (if any) plus the planned-absence overlay. */
public record AttendanceEntry(PlayerId playerId, Optional<Attendance> recorded, Optional<PlannedAbsence> plannedAbsence) {

    public boolean expectedAbsent() {
        return plannedAbsence.isPresent();
    }
}
