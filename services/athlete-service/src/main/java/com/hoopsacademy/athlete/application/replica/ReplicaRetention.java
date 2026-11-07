package com.hoopsacademy.athlete.application.replica;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.quarkus.runtime.Startup;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * Replica housekeeping (WP82, ADR-0037 amendment): deletes the applied event ids older than
 * {@code hoops.roster.replica.retention.applied-events} in every tenant (in batches, each in its own transaction bound
 * to that tenant), and the parked records an operator inspected longer than
 * {@code hoops.roster.replica.retention.parked-events} ago. Uninspected parked records are kept.
 *
 * <p>An applied id only has to outlive the redeliveries of its event: core's topics keep a removal's tombstone, the
 * last record a replay could deliver twice, for {@link #TOMBSTONE_RETENTION}, so the retention is never shorter (the
 * service refuses to start). An older redelivery is still harmless: the row's {@code occurred_at} guard makes it stale.
 */
@ApplicationScoped
@Startup
public class ReplicaRetention {

    /** The topics' {@code delete.retention.ms} (ADR-0036): how long a tombstone, and so a redelivery, can come. */
    public static final Duration TOMBSTONE_RETENTION = Duration.ofDays(7);

    private static final Logger LOG = Logger.getLogger(ReplicaRetention.class);

    /** What one run deleted. */
    public record Report(Instant appliedBefore, long appliedEvents, int tenants, int failedTenants,
            Instant inspectedBefore, List<ParkedPosition> parkedEvents) {

        public Report {
            parkedEvents = List.copyOf(parkedEvents);
        }
    }

    private final ReplicaHistory history;
    private final TenantScope tenantScope;
    private final Clock clock;
    private final Duration appliedEvents;
    private final Duration parkedEvents;
    private final int batchSize;

    @Inject
    public ReplicaRetention(ReplicaHistory history, TenantScope tenantScope, Clock clock,
            @ConfigProperty(name = "hoops.roster.replica.retention.applied-events", defaultValue = "P7D")
            Duration appliedEvents,
            @ConfigProperty(name = "hoops.roster.replica.retention.parked-events", defaultValue = "P30D")
            Duration parkedEvents,
            @ConfigProperty(name = "hoops.roster.replica.retention.batch-size", defaultValue = "1000") int batchSize) {
        require(appliedEvents.compareTo(TOMBSTONE_RETENTION) >= 0, "hoops.roster.replica.retention.applied-events "
                + appliedEvents + " is below the topics' tombstone retention (" + TOMBSTONE_RETENTION.toDays() + " days)");
        require(!parkedEvents.isNegative(), "hoops.roster.replica.retention.parked-events must not be negative");
        require(batchSize >= 1, "hoops.roster.replica.retention.batch-size must be at least 1");
        this.history = history;
        this.tenantScope = tenantScope;
        this.clock = clock;
        this.appliedEvents = appliedEvents;
        this.parkedEvents = parkedEvents;
        this.batchSize = batchSize;
    }

    public Report prune() {
        Instant now = clock.instant();
        Instant appliedBefore = now.minus(appliedEvents);
        List<TenantId> tenants = history.tenants();
        long deleted = 0;
        int failed = 0;
        for (TenantId tenant : tenants) {
            try {
                deleted += pruneApplied(tenant, appliedBefore);
            } catch (RuntimeException e) {
                failed++;
                LOG.errorf(e, "Pruning the applied events of tenant %s failed", tenant);
            }
        }
        Instant inspectedBefore = now.minus(parkedEvents);
        return new Report(appliedBefore, deleted, tenants.size(), failed, inspectedBefore,
                history.deleteParkedInspectedBefore(inspectedBefore));
    }

    private long pruneApplied(TenantId tenant, Instant before) {
        long total = 0;
        int batch;
        do {
            batch = tenantScope.runAs(tenant, () -> history.deleteAppliedBefore(before, batchSize));
            total += batch;
        } while (batch == batchSize);
        return total;
    }

    private static void require(boolean condition, String message) {
        if (!condition) {
            throw new IllegalArgumentException(message);
        }
    }
}
