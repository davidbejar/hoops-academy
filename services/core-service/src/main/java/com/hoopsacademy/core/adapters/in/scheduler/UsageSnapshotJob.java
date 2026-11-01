package com.hoopsacademy.core.adapters.in.scheduler;

import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.usage.SnapshotTenantUsage;
import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;
import org.jboss.logging.Logger;

/**
 * Writes one usage snapshot per ACTIVE tenant and day ({@code hoops.core.usage-snapshot-cron}, 02:30 UTC by default);
 * one replica at a time ({@link TenantScope#runExclusive} on {@link #LOCK}).
 */
@ApplicationScoped
public class UsageSnapshotJob {

    /** Cluster-wide lock name: one replica runs the job ({@code TenantScope.runExclusive}). */
    public static final String LOCK = "core.usage-snapshot";

    private static final Logger LOG = Logger.getLogger(UsageSnapshotJob.class);

    private final SnapshotTenantUsage snapshots;
    private final TenantScope tenantScope;

    public UsageSnapshotJob(SnapshotTenantUsage snapshots, TenantScope tenantScope) {
        this.snapshots = snapshots;
        this.tenantScope = tenantScope;
    }

    @Scheduled(identity = "usage-snapshot", cron = "{hoops.core.usage-snapshot-cron}",
            timeZone = "UTC", concurrentExecution = Scheduled.ConcurrentExecution.SKIP)
    public void run() {
        tenantScope.runExclusive(LOCK, () -> {
            SnapshotTenantUsage.Summary summary = snapshots.run();
            LOG.infof("Usage snapshot: %d tenants, %d failed, %d partial", summary.tenants(), summary.failedTenants(),
                    summary.partial());
        });
    }
}
