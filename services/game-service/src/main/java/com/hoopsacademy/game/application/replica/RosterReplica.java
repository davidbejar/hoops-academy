package com.hoopsacademy.game.application.replica;

/**
 * game's replica of core's roster (ADR-0037), in the tenant bound to the current transaction (RLS). Writes are
 * idempotent and order-safe; the replica holds one row per aggregate.
 */
public interface RosterReplica {

    /** Records the event's id; false when it was already applied (a redelivery). */
    boolean markApplied(EventEnvelope envelope, String topic);

    /**
     * Upserts the aggregate's row unless the stored row was written by a newer event.
     *
     * @return false when the stored row is newer (the event is stale)
     */
    boolean save(RosterEvent event);
}
