package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;

/**
 * An integration event appended to {@code core.outbox} in the same transaction as the change it describes.
 * {@code topic} present: a roster event the publisher sends to that topic (WP67, libs/contracts/events). Absent: an
 * internal v1 notification that stays in the outbox (tenant.created, tenant.suspended, tenant.reactivated,
 * tenant.withdrawn, member.invited, membership.changed, player.requested / approved / rejected / withdrawn). Payload
 * values may be null (the contracts spell an absent value as an explicit null).
 */
public record OutboxEvent(TenantId tenant, String type, String aggregateType, String aggregateId,
        Map<String, Object> payload, String topic) {

    public OutboxEvent {
        Objects.requireNonNull(tenant, "tenant");
        Objects.requireNonNull(type, "type");
        payload = Collections.unmodifiableMap(new LinkedHashMap<>(payload));
    }

    /** An internal notification (not published). */
    public OutboxEvent(TenantId tenant, String type, String aggregateType, String aggregateId,
            Map<String, Object> payload) {
        this(tenant, type, aggregateType, aggregateId, payload, null);
    }
}
