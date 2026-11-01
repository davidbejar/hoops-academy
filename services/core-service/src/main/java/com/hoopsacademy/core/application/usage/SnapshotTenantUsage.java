package com.hoopsacademy.core.application.usage;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.platform.ActiveTenants;
import jakarta.enterprise.context.ApplicationScoped;
import org.jboss.logging.Logger;

/**
 * The nightly usage snapshot: aggregates every ACTIVE tenant exactly like {@code GET /platform/tenants/{id}/usage}
 * (which stores the day's snapshot as a side effect, an upsert per tenant and UTC day). A failing tenant is logged
 * and skipped; running twice on the same day leaves one snapshot per tenant.
 */
@ApplicationScoped
public class SnapshotTenantUsage {

    private static final Logger LOG = Logger.getLogger(SnapshotTenantUsage.class);

    /** What one run did; {@code partial} counts tenants whose snapshot lacks a service. */
    public record Summary(int tenants, int failedTenants, int partial) {}

    private final ActiveTenants activeTenants;
    private final AggregateTenantUsage aggregate;

    public SnapshotTenantUsage(ActiveTenants activeTenants, AggregateTenantUsage aggregate) {
        this.activeTenants = activeTenants;
        this.aggregate = aggregate;
    }

    public Summary run() {
        int done = 0;
        int failed = 0;
        int partial = 0;
        for (TenantId tenant : activeTenants.list()) {
            try {
                if (!aggregate.of(tenant).unavailableServices().isEmpty()) {
                    partial++;
                }
                done++;
            } catch (RuntimeException e) {
                failed++;
                LOG.errorf(e, "Usage snapshot failed for tenant %s; continuing with the next tenant", tenant);
            }
        }
        return new Summary(done, failed, partial);
    }
}
