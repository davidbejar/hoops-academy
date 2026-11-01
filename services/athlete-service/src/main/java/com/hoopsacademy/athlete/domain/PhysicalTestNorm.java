package com.hoopsacademy.athlete.domain;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.math.BigDecimal;
import java.util.Objects;
import java.util.Optional;

/**
 * One band of a reference table: players of {@code gender} aged {@code minAge..maxAge} (both inclusive) whose result
 * lies in [minValue, maxValue) are in {@code band}. A missing bound is open. {@code global} rows are platform
 * reference data; tenant rows override them.
 */
public record PhysicalTestNorm(NormId id, TestTypeId testTypeId, Gender gender, int minAge, int maxAge, NormBand band,
        Optional<BigDecimal> minValue, Optional<BigDecimal> maxValue, boolean referencePending, String source,
        boolean global) {

    public PhysicalTestNorm {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(testTypeId, "testTypeId");
        Objects.requireNonNull(gender, "gender");
        Objects.requireNonNull(band, "band");
        if (minAge > maxAge) {
            throw new DomainRuleViolation("minAge must not exceed maxAge", "NORM_INVALID_AGE_RANGE");
        }
        if (minValue.isPresent() && maxValue.isPresent() && minValue.get().compareTo(maxValue.get()) >= 0) {
            throw new DomainRuleViolation("minValue must be below maxValue", "NORM_INVALID_VALUE_RANGE");
        }
        if (source != null && source.length() > 500) {
            throw new DomainRuleViolation("source is at most 500 characters", "INVALID_NORM");
        }
    }

    public static PhysicalTestNorm of(NormId id, TestTypeId type, Gender gender, int minAge, int maxAge, NormBand band,
            BigDecimal minValue, BigDecimal maxValue, boolean referencePending, String source, boolean global) {
        return new PhysicalTestNorm(id, type, gender, minAge, maxAge, band, Optional.ofNullable(minValue),
                Optional.ofNullable(maxValue), referencePending, source, global);
    }

    public boolean covers(Gender g, int age) {
        return gender == g && age >= minAge && age <= maxAge;
    }

    public boolean containsValue(BigDecimal value) {
        return minValue.map(m -> value.compareTo(m) >= 0).orElse(true) && maxValue.map(m -> value.compareTo(m) < 0).orElse(true);
    }

    public boolean overlapsAges(PhysicalTestNorm other) {
        return minAge <= other.maxAge && other.minAge <= maxAge;
    }
}
