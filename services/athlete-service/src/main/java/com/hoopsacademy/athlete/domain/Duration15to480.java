package com.hoopsacademy.athlete.domain;

/** Validates the session/slot length bounds shared by the contract and the database. */
final class Duration15to480 {

    static final int MIN_MINUTES = 15;
    static final int MAX_MINUTES = 480;

    private Duration15to480() {}

    static int require(int minutes) {
        if (minutes < MIN_MINUTES || minutes > MAX_MINUTES) {
            throw new TrainingRuleViolation(
                    "Duration must be between " + MIN_MINUTES + " and " + MAX_MINUTES + " minutes", "INVALID_DURATION");
        }
        return minutes;
    }
}
