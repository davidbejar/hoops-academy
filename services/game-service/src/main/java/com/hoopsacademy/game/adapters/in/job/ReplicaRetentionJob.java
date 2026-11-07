package com.hoopsacademy.game.adapters.in.job;

import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.game.application.replica.ReplicaRetention;
import com.hoopsacademy.game.application.replica.ReplicaRetention.Report;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;
import org.jboss.logging.Logger;

/**
 * Runs the replica housekeeping ({@link ReplicaRetention}) on {@code hoops.roster.replica.retention.cron} (daily by
 * default, {@code off} disables it). With several pods only the one holding the advisory lock {@link #LOCK} runs it
 * ({@link TenantScope#runExclusive}). What it deleted is logged and counted:
 * {@code hoops_roster_replica_pruned_total{table="applied_event"|"parked_event"}}.
 */
@ApplicationScoped
public class ReplicaRetentionJob {

    /** Cluster-wide lock name of the job. */
    public static final String LOCK = "game.replica-retention";

    private static final Logger LOG = Logger.getLogger(ReplicaRetentionJob.class);

    private final ReplicaRetention retention;
    private final TenantScope tenantScope;
    private final Counter appliedEvents;
    private final Counter parkedEvents;

    ReplicaRetentionJob(ReplicaRetention retention, TenantScope tenantScope, MeterRegistry metrics) {
        this.retention = retention;
        this.tenantScope = tenantScope;
        this.appliedEvents = pruned(metrics, "applied_event");
        this.parkedEvents = pruned(metrics, "parked_event");
    }

    @Scheduled(cron = "{hoops.roster.replica.retention.cron}", identity = "game-replica-retention",
            concurrentExecution = Scheduled.ConcurrentExecution.SKIP)
    void scheduled() {
        run();
    }

    /** @return false when another pod was running it (this run is skipped) */
    public boolean run() {
        return tenantScope.runExclusive(LOCK, () -> record(retention.prune()));
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
