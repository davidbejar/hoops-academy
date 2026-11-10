package com.hoopsacademy.athlete.adapters.config;

import java.util.Locale;

/** Where athlete reads core's roster and memberships from (hoops.roster.source, ADR-0037). */
public enum RosterSource {
    /** core's /internal REST API, cached 30 s (ADR-0008 v1); the fallback since the flip (WP98). */
    REST,
    /** The local replica fed by core's events (needs hoops.roster.consumer.enabled=true); the default since WP98. */
    REPLICA;

    /** @throws IllegalStateException for an unknown source, or a replica nothing would ever fill */
    public static RosterSource of(String source, boolean consume) {
        RosterSource parsed;
        try {
            parsed = valueOf(source.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            throw new IllegalStateException("hoops.roster.source must be rest or replica, not '" + source + "'", e);
        }
        if (parsed == REPLICA && !consume) {
            throw new IllegalStateException(
                    "hoops.roster.source=replica needs hoops.roster.consumer.enabled=true, or the replica never changes");
        }
        return parsed;
    }
}
