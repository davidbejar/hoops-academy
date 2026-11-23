package com.hoopsacademy.athlete.adapters.in.job;

import com.hoopsacademy.common.replica.ReplicaHousekeeping;
import com.hoopsacademy.common.replica.ReplicaRetention;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.micrometer.core.instrument.MeterRegistry;
import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;

/**
 * Runs the replica housekeeping (common's {@link ReplicaHousekeeping}, WP130) on
 * {@code hoops.roster.replica.retention.cron} (daily by default, {@code off} disables it), in the one pod holding the
 * advisory lock {@link #LOCK}; the deletions are counted in {@code hoops_roster_replica_pruned_total{table}}.
 */
@ApplicationScoped
public class ReplicaRetentionJob {

    /** Cluster-wide lock name of the job, also the scheduler's identity. */
    public static final String LOCK = "athlete.replica-retention";

    private final ReplicaHousekeeping housekeeping;

    ReplicaRetentionJob(ReplicaRetention retention, TenantScope tenantScope, MeterRegistry metrics) {
        this.housekeeping = new ReplicaHousekeeping(retention, tenantScope, metrics, LOCK);
    }

    @Scheduled(cron = "{hoops.roster.replica.retention.cron}", identity = LOCK,
            concurrentExecution = Scheduled.ConcurrentExecution.SKIP)
    void scheduled() {
        run();
    }

    /** @return false when another pod was running it (this run is skipped) */
    public boolean run() {
        return housekeeping.run();
    }
}
