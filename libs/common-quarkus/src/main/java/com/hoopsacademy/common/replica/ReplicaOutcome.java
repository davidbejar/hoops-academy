package com.hoopsacademy.common.replica;

import java.util.Locale;

/** What applying one valid event did to a replica (ADR-0037). */
public enum ReplicaOutcome {
    /** The replica now holds the event's state. */
    APPLIED,
    /** The event id was applied before (a redelivery); nothing changed. */
    DUPLICATE,
    /** The replica holds a newer state of the aggregate; nothing changed. */
    STALE;

    /** The {@code outcome} tag of {@code hoops_roster_replica_events_total}. */
    public String label() {
        return name().toLowerCase(Locale.ROOT);
    }
}
