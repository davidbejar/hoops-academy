package com.hoopsacademy.athlete.domain;

import java.time.LocalDate;
import java.time.Period;

/** Age in full years on a given day. */
public final class AgeAt {

    private AgeAt() {}

    /** Never negative: a date before the birth date counts as age 0. */
    public static int years(LocalDate birthDate, LocalDate on) {
        return Math.max(0, Period.between(birthDate, on).getYears());
    }
}
