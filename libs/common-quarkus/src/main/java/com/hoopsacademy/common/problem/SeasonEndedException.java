package com.hoopsacademy.common.problem;

/**
 * A write on a team whose season has ended (academy time zone): past seasons are read-only history (ADR-0042). 409
 * with {@code code} = {@value #CODE} for every caller who could write the team otherwise. Pure Java.
 */
public class SeasonEndedException extends ConflictException {

    public static final String CODE = "SEASON_ENDED";

    public SeasonEndedException(String message) {
        super(message, CODE);
    }
}
