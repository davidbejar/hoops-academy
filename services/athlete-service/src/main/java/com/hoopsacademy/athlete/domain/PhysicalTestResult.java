package com.hoopsacademy.athlete.domain;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Objects;

/** A player's result in a physical test, in the unit of the test type. The expected band is derived at read time. */
public record PhysicalTestResult(
        TestResultId id,
        PlayerId playerId,
        TestTypeId testTypeId,
        LocalDate measuredOn,
        BigDecimal value,
        String notes,
        Actor recordedBy,
        Instant createdAt,
        Instant updatedAt) {

    private static final BigDecimal LIMIT = new BigDecimal("1000000000");

    public PhysicalTestResult {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(playerId, "playerId");
        Objects.requireNonNull(testTypeId, "testTypeId");
        Objects.requireNonNull(measuredOn, "measuredOn");
        Objects.requireNonNull(value, "value");
        Objects.requireNonNull(recordedBy, "recordedBy");
        Objects.requireNonNull(createdAt, "createdAt");
        Objects.requireNonNull(updatedAt, "updatedAt");
        if (value.signum() < 0) {
            throw new DomainRuleViolation("A result must not be negative", "RESULT_VALUE_NEGATIVE");
        }
        if (value.compareTo(LIMIT) >= 0 || (notes != null && notes.length() > 1000)) {
            throw new DomainRuleViolation("Value or notes out of range", "RESULT_OUT_OF_RANGE");
        }
    }

    public static PhysicalTestResult record(PlayerId player, TestTypeId type, LocalDate measuredOn, BigDecimal value,
            String notes, Actor recordedBy, Instant now) {
        return new PhysicalTestResult(TestResultId.random(), player, type, measuredOn, scaled(value), notes, recordedBy, now, now);
    }

    public PhysicalTestResult changedTo(LocalDate newMeasuredOn, BigDecimal newValue, String newNotes, Instant now) {
        return new PhysicalTestResult(id, playerId, testTypeId, newMeasuredOn, scaled(newValue), newNotes, recordedBy,
                createdAt, now);
    }

    private static BigDecimal scaled(BigDecimal value) {
        return value.setScale(3, RoundingMode.HALF_UP);
    }
}
