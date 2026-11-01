package com.hoopsacademy.game.application;

import java.time.Instant;
import java.util.Map;

/** Counts a tenant's data for the platform usage report (runs inside a bound tenant transaction). */
public interface UsageCounter {

    Usage usage();

    /** @param lastActivityAt latest change, null when the tenant has no matches */
    record Usage(Map<String, Long> counters, Instant lastActivityAt) {

        public Usage {
            counters = Map.copyOf(counters);
        }
    }
}
