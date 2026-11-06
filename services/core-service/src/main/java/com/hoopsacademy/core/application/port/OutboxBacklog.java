package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import java.time.Instant;
import java.util.List;

/**
 * The tenants with unpublished roster events, across tenants (platform datasource: the queue columns only, never a
 * payload; V14).
 */
public interface OutboxBacklog {

    record TenantBacklog(TenantId tenant, long pending, Instant oldest) {}

    /** Oldest backlog first. */
    List<TenantBacklog> pendingByTenant();
}
