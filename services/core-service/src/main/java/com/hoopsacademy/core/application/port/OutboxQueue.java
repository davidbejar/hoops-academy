package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

/** The bound tenant's unpublished roster events (default datasource, tenant policy), for the publisher. */
public interface OutboxQueue {

    /** One unpublished row: {@code payloadJson} is the stored payload object, verbatim. */
    record PendingEvent(UUID eventId, String topic, String type, TenantId tenant, String aggregateId,
            Instant occurredAt, String payloadJson) {}

    /**
     * Locks and returns up to {@code limit} of the oldest unpublished rows (outbox order), skipping rows another
     * publisher holds ({@code FOR UPDATE SKIP LOCKED}) and every row of an aggregate whose earlier unpublished row is
     * held there, so the events of one aggregate are never sent out of order. The locks last until the caller's
     * transaction ends.
     */
    List<PendingEvent> lockNext(int limit);

    void markPublished(Collection<UUID> eventIds);
}
