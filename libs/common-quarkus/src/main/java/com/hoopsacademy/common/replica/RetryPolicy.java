package com.hoopsacademy.common.replica;

import java.time.Duration;

/**
 * How often the consumer tries the database work of one record (apply or park) before the failure stops it
 * ({@code hoops.roster.replica.max-attempts}), and the pause after the first failed attempt
 * ({@code hoops.roster.replica.first-backoff}), doubling after each further one (ADR-0062).
 */
public record RetryPolicy(int maxAttempts, Duration firstBackoff) {

    public RetryPolicy {
        if (maxAttempts < 1) {
            throw new IllegalArgumentException("hoops.roster.replica.max-attempts must be at least 1");
        }
        if (firstBackoff.isNegative()) {
            throw new IllegalArgumentException("hoops.roster.replica.first-backoff must not be negative");
        }
    }

    /** @param attempt the attempt that failed, from 1 */
    public Duration backoffAfter(int attempt) {
        return firstBackoff.multipliedBy(1L << (attempt - 1));
    }
}
