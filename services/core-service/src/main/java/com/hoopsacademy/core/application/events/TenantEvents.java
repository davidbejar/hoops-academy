package com.hoopsacademy.core.application.events;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.domain.tenant.Tenant;
import java.util.Map;

/**
 * The {@code tenant.changed} event of a change the platform makes (lifecycle, master data) on the platform datasource,
 * where no tenant is bound and {@link RosterChanges} cannot read the tenant's state: the registry row the use case just
 * updated is that state (and its update holds the row lock until the commit).
 */
public final class TenantEvents {

    private TenantEvents() {}

    /**
     * {@code tenant.removed} (WP81): the registry row of an onboarding that never finished is deleted. The identity is
     * the tenant id, the payload empty.
     */
    public static OutboxEvent removed(TenantId tenant) {
        EventTopic topic = EventTopic.TENANT;
        return new OutboxEvent(tenant, topic.removedType(), topic.aggregate(), tenant.value().toString(), Map.of(),
                topic.topic());
    }

    public static OutboxEvent changed(Tenant tenant) {
        EventTopic topic = EventTopic.TENANT;
        return new OutboxEvent(tenant.id(), topic.changedType(), topic.aggregate(), tenant.id().toString(),
                RosterPayloads.tenant(tenant), topic.topic());
    }
}
