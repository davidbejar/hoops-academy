package com.hoopsacademy.athlete.domain;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Objects;

/**
 * A recurring weekly training slot of a team. {@code startTime} is wall-clock time in the tenant time zone;
 * {@code validUntil} is inclusive and null for an open-ended schedule.
 */
public record TrainingSchedule(
        ScheduleId id,
        TeamId teamId,
        DayOfWeek dayOfWeek,
        LocalTime startTime,
        int durationMinutes,
        String location,
        LocalDate validFrom,
        LocalDate validUntil,
        boolean active) {

    public TrainingSchedule {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(teamId, "teamId");
        Objects.requireNonNull(dayOfWeek, "dayOfWeek");
        Objects.requireNonNull(startTime, "startTime");
        Objects.requireNonNull(validFrom, "validFrom");
        Duration15to480.require(durationMinutes);
        if (validUntil != null && validUntil.isBefore(validFrom)) {
            throw new TrainingRuleViolation("validUntil must not be before validFrom", "INVALID_VALIDITY_RANGE");
        }
        startTime = startTime.withSecond(0).withNano(0);
    }

    public static TrainingSchedule create(TeamId teamId, DayOfWeek dayOfWeek, LocalTime startTime,
            int durationMinutes, String location, LocalDate validFrom, LocalDate validUntil) {
        return new TrainingSchedule(ScheduleId.random(), teamId, dayOfWeek, startTime, durationMinutes, location,
                validFrom, validUntil, true);
    }

    /** Applies a change; every argument is the NEW value (callers pass the old one for untouched fields). */
    public TrainingSchedule changedTo(DayOfWeek newDay, LocalTime newStart, int newDuration, String newLocation,
            LocalDate newFrom, LocalDate newUntil) {
        return new TrainingSchedule(id, teamId, newDay, newStart, newDuration, newLocation, newFrom, newUntil, active);
    }

    public TrainingSchedule ended() {
        return new TrainingSchedule(id, teamId, dayOfWeek, startTime, durationMinutes, location, validFrom,
                validUntil, false);
    }

    /** True when the slot applies on {@code date} (weekday matches and the date is inside the validity range). */
    public boolean occursOn(LocalDate date) {
        return active
                && date.getDayOfWeek() == dayOfWeek
                && !date.isBefore(validFrom)
                && (validUntil == null || !date.isAfter(validUntil));
    }

    public boolean isValidOn(LocalDate date) {
        return active && !date.isBefore(validFrom) && (validUntil == null || !date.isAfter(validUntil));
    }
}
