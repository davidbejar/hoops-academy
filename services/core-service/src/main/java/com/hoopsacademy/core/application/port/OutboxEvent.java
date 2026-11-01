package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import java.util.Map;
import java.util.Objects;

/**
 * An integration event appended to {@code core.outbox} in the same transaction as the change it describes.
 * Types in v1: tenant.created, tenant.suspended, tenant.reactivated, tenant.withdrawn, member.invited,
 * membership.changed.
 */
public record OutboxEvent(TenantId tenant, String type, String aggregateType, String aggregateId,
        Map<String, Object> payload) {

    public OutboxEvent {
        Objects.requireNonNull(tenant, "tenant");
        Objects.requireNonNull(type, "type");
        payload = Map.copyOf(payload);
    }
}
