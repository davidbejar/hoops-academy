package com.hoopsacademy.athlete.domain;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Objects;
import java.util.Optional;

/** Height and/or weight of a player on a day (one measurement per player and day is enforced by the use case and the database). */
public record BodyMeasurement(
        BodyMeasurementId id,
        PlayerId playerId,
        LocalDate measuredOn,
        Optional<BigDecimal> heightCm,
        Optional<BigDecimal> weightKg,
        Actor recordedBy,
        Instant createdAt,
        Instant updatedAt) {

    private static final BigDecimal MIN_HEIGHT = new BigDecimal("50");
    private static final BigDecimal MAX_HEIGHT = new BigDecimal("250");
    private static final BigDecimal MIN_WEIGHT = new BigDecimal("10");
    private static final BigDecimal MAX_WEIGHT = new BigDecimal("250");

    public BodyMeasurement {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(playerId, "playerId");
        Objects.requireNonNull(measuredOn, "measuredOn");
        Objects.requireNonNull(recordedBy, "recordedBy");
        Objects.requireNonNull(createdAt, "createdAt");
        Objects.requireNonNull(updatedAt, "updatedAt");
        if (heightCm.isEmpty() && weightKg.isEmpty()) {
            throw new DomainRuleViolation("Give at least a height or a weight", "MEASUREMENT_EMPTY");
        }
        if (heightCm.filter(h -> h.compareTo(MIN_HEIGHT) < 0 || h.compareTo(MAX_HEIGHT) > 0).isPresent()
                || weightKg.filter(w -> w.compareTo(MIN_WEIGHT) < 0 || w.compareTo(MAX_WEIGHT) > 0).isPresent()) {
            throw new DomainRuleViolation("Height must be 50-250 cm and weight 10-250 kg", "MEASUREMENT_OUT_OF_RANGE");
        }
    }

    /** Height is stored with one decimal, weight with two. */
    public static BodyMeasurement record(PlayerId player, LocalDate measuredOn, BigDecimal heightCm, BigDecimal weightKg,
            Actor recordedBy, Instant now) {
        return new BodyMeasurement(BodyMeasurementId.random(), player, measuredOn, scaled(heightCm, 1), scaled(weightKg, 2),
                recordedBy, now, now);
    }

    public BodyMeasurement changedTo(LocalDate newMeasuredOn, BigDecimal newHeightCm, BigDecimal newWeightKg, Instant now) {
        return new BodyMeasurement(id, playerId, newMeasuredOn, scaled(newHeightCm, 1), scaled(newWeightKg, 2), recordedBy,
                createdAt, now);
    }

    private static Optional<BigDecimal> scaled(BigDecimal value, int scale) {
        return Optional.ofNullable(value).map(v -> v.setScale(scale, RoundingMode.HALF_UP));
    }
}
