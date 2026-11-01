package com.hoopsacademy.athlete.domain;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Objects;
import java.util.Optional;

/**
 * An injury of a player. Invariants: a body part is named; neither the expected nor the actual return precedes the day
 * of the injury; a RECOVERED injury has an actual return date.
 */
public record Injury(
        InjuryId id,
        PlayerId playerId,
        LocalDate occurredOn,
        String bodyPart,
        String description,
        InjurySeverity severity,
        Optional<LocalDate> expectedReturnOn,
        Optional<LocalDate> actualReturnOn,
        InjuryStatus status,
        Actor reportedBy,
        Instant createdAt,
        Instant updatedAt) {

    public static final int MAX_BODY_PART = 80;
    public static final int MAX_DESCRIPTION = 2000;

    public Injury {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(playerId, "playerId");
        Objects.requireNonNull(occurredOn, "occurredOn");
        Objects.requireNonNull(severity, "severity");
        Objects.requireNonNull(status, "status");
        Objects.requireNonNull(reportedBy, "reportedBy");
        Objects.requireNonNull(createdAt, "createdAt");
        Objects.requireNonNull(updatedAt, "updatedAt");
        if (bodyPart == null || bodyPart.isBlank() || bodyPart.length() > MAX_BODY_PART
                || (description != null && description.length() > MAX_DESCRIPTION)) {
            throw new DomainRuleViolation("An injury needs a body part (max " + MAX_BODY_PART + " characters)", "INVALID_INJURY");
        }
        if (expectedReturnOn.filter(d -> d.isBefore(occurredOn)).isPresent()
                || actualReturnOn.filter(d -> d.isBefore(occurredOn)).isPresent()) {
            throw new DomainRuleViolation("The return date must not be before the day of the injury",
                    "INJURY_RETURN_BEFORE_OCCURRENCE");
        }
        if (status == InjuryStatus.RECOVERED && actualReturnOn.isEmpty()) {
            throw new DomainRuleViolation("A recovered injury needs the actual return date", "RECOVERY_DATE_REQUIRED");
        }
    }

    public static Injury report(PlayerId player, LocalDate occurredOn, String bodyPart, String description,
            InjurySeverity severity, LocalDate expectedReturnOn, Actor reportedBy, Instant now) {
        return new Injury(InjuryId.random(), player, occurredOn, bodyPart, description, severity,
                Optional.ofNullable(expectedReturnOn), Optional.empty(), InjuryStatus.OPEN, reportedBy, now, now);
    }

    public Injury changedTo(LocalDate newOccurredOn, String newBodyPart, String newDescription, InjurySeverity newSeverity,
            LocalDate newExpectedReturnOn, LocalDate newActualReturnOn, InjuryStatus newStatus, Instant now) {
        return new Injury(id, playerId, newOccurredOn, newBodyPart, newDescription, newSeverity,
                Optional.ofNullable(newExpectedReturnOn), Optional.ofNullable(newActualReturnOn), newStatus, reportedBy,
                createdAt, now);
    }

    /**
     * Does the injury keep the player unavailable on {@code today}? An OPEN injury does while no actual return is
     * recorded, or while the expected return day has not passed.
     */
    public boolean blocksAvailability(LocalDate today) {
        if (status != InjuryStatus.OPEN) {
            return false;
        }
        return actualReturnOn.isEmpty() || expectedReturnOn.filter(d -> !d.isBefore(today)).isPresent();
    }
}
