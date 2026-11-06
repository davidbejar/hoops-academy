package com.hoopsacademy.core.application.events;

import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.domain.tenant.Tenant;

/**
 * The {@code tenant.changed} event of a change the platform makes (lifecycle, master data) on the platform datasource,
 * where no tenant is bound and {@link RosterChanges} cannot read the tenant's state: the registry row the use case just
 * updated is that state (and its update holds the row lock until the commit).
 */
public final class TenantEvents {

    private TenantEvents() {}

    public static OutboxEvent changed(Tenant tenant) {
        EventTopic topic = EventTopic.TENANT;
        return new OutboxEvent(tenant.id(), topic.changedType(), topic.aggregate(), tenant.id().toString(),
                RosterPayloads.tenant(tenant), topic.topic());
    }
}
