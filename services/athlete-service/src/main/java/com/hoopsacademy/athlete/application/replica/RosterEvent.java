package com.hoopsacademy.athlete.application.replica;

import com.hoopsacademy.common.tenancy.TenantId;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * One validated core roster event (envelope of libs/contracts/events): the replica applies it in its own tenant, never
 * the one of a request.
 */
public record RosterEvent(UUID eventId, TenantId tenant, UUID aggregateId, Instant occurredAt, RosterChange change) {

    public RosterEvent {
        Objects.requireNonNull(eventId, "eventId");
        Objects.requireNonNull(tenant, "tenant");
        Objects.requireNonNull(aggregateId, "aggregateId");
        Objects.requireNonNull(occurredAt, "occurredAt");
        Objects.requireNonNull(change, "change");
    }

    public RosterTopic topic() {
        return change.topic();
    }
}
