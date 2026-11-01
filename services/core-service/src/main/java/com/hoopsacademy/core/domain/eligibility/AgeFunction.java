package com.hoopsacademy.core.domain.eligibility;

import com.hoopsacademy.core.domain.tenant.AgeRule;
import java.time.LocalDate;
import java.time.Period;

/** How old a player counts as for categories (ADR-0010), one strategy per tenant {@link AgeRule}. */
public enum AgeFunction {

    /** Season reference year − birth year; the evaluation date is irrelevant. */
    BIRTH_YEAR {
        @Override
        public int ageOf(LocalDate birthDate, int referenceYear, LocalDate asOf) {
            return referenceYear - birthDate.getYear();
        }
    },

    /**
     * Completed years on {@code asOf} (a date in the tenant's time zone). A 29 February birthday is reached on
     * 1 March in non-leap years ({@link Period#between} semantics).
     */
    BIRTHDAY {
        @Override
        public int ageOf(LocalDate birthDate, int referenceYear, LocalDate asOf) {
            return Period.between(birthDate, asOf).getYears();
        }
    };

    public abstract int ageOf(LocalDate birthDate, int referenceYear, LocalDate asOf);

    public static AgeFunction of(AgeRule rule) {
        return switch (rule) {
            case BIRTH_YEAR -> BIRTH_YEAR;
            case BIRTHDAY -> BIRTHDAY;
        };
    }
}
