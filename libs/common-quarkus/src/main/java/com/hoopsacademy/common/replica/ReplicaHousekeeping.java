package com.hoopsacademy.common.replica;

import com.hoopsacademy.common.replica.ReplicaRetention.Report;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.jboss.logging.Logger;

/**
 * One run of the replica housekeeping ({@link ReplicaRetention}) as each service's scheduled job does it: only in the
 * pod that holds the service's advisory lock ({@link TenantScope#runExclusive}), with what it deleted logged and counted
 * in {@code hoops_roster_replica_pruned_total{table="applied_event"|"parked_event"}}. The {@code @Scheduled} method
 * stays in each service (WP98: the scheduler is not a dependency of this library, which core uses too).
 */
public final class ReplicaHousekeeping {

    private static final Logger LOG = Logger.getLogger(ReplicaHousekeeping.class);

    private final ReplicaRetention retention;
    private final TenantScope tenantScope;
    private final String lock;
    private final Counter appliedEvents;
    private final Counter parkedEvents;

    /** @param lock the cluster-wide lock name, {@code <service>.replica-retention} */
    public ReplicaHousekeeping(ReplicaRetention retention, TenantScope tenantScope, MeterRegistry metrics, String lock) {
        this.retention = retention;
        this.tenantScope = tenantScope;
        this.lock = lock;
        this.appliedEvents = pruned(metrics, "applied_event");
        this.parkedEvents = pruned(metrics, "parked_event");
    }

    /** @return false when another pod was running it (this run is skipped) */
    public boolean run() {
        return tenantScope.runExclusive(lock, () -> record(retention.prune()));
    }

    private void record(Report report) {
        appliedEvents.increment(report.appliedEvents());
        parkedEvents.increment(report.parkedEvents().size());
        LOG.infof("Replica retention: deleted %d applied event ids recorded before %s in %d tenants (%d failed); "
                + "%d parked records inspected before %s: %s", report.appliedEvents(), report.appliedBefore(),
                report.tenants(), report.failedTenants(), report.parkedEvents().size(), report.inspectedBefore(),
                report.parkedEvents());
    }

    private static Counter pruned(MeterRegistry metrics, String table) {
        return Counter.builder("hoops.roster.replica.pruned").description("Replica bookkeeping rows deleted by retention")
                .tag("table", table).register(metrics);
    }
}
