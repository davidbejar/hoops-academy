package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.tenancy.TenantId;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * The envelope every core roster event carries (libs/contracts/events): the event id (equal on every redelivery), the
 * tenant the event belongs to (the replica binds it, never a request's), the aggregate and when core wrote the change.
 */
public record EventEnvelope(UUID eventId, TenantId tenantId, UUID aggregateId, Instant occurredAt) {

    public EventEnvelope {
        Objects.requireNonNull(eventId, "eventId");
        Objects.requireNonNull(tenantId, "tenantId");
        Objects.requireNonNull(aggregateId, "aggregateId");
        Objects.requireNonNull(occurredAt, "occurredAt");
    }
}
