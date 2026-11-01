package com.hoopsacademy.athlete.domain;

import java.time.Instant;
import java.time.LocalDate;
import java.util.Objects;

/** A player (or guardian, or staff) announced that the player will miss trainings between two dates, inclusive. */
public record PlannedAbsence(
        AbsenceId id,
        PlayerId playerId,
        LocalDate fromDate,
        LocalDate toDate,
        String reason,
        Actor createdBy,
        Instant createdAt) {

    public PlannedAbsence {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(playerId, "playerId");
        Objects.requireNonNull(fromDate, "fromDate");
        Objects.requireNonNull(toDate, "toDate");
        Objects.requireNonNull(createdBy, "createdBy");
        Objects.requireNonNull(createdAt, "createdAt");
        if (toDate.isBefore(fromDate)) {
            throw new TrainingRuleViolation("toDate must not be before fromDate", "INVALID_DATE_RANGE");
        }
    }

    public static PlannedAbsence announce(PlayerId playerId, LocalDate from, LocalDate to, String reason,
            Actor createdBy, Instant now) {
        return new PlannedAbsence(AbsenceId.random(), playerId, from, to, reason, createdBy, now);
    }

    public PlannedAbsence changedTo(LocalDate newFrom, LocalDate newTo, String newReason) {
        return new PlannedAbsence(id, playerId, newFrom, newTo, newReason, createdBy, createdAt);
    }

    public boolean covers(LocalDate date) {
        return !date.isBefore(fromDate) && !date.isAfter(toDate);
    }

    public boolean overlaps(LocalDate from, LocalDate to) {
        return !toDate.isBefore(from) && !fromDate.isAfter(to);
    }
}
