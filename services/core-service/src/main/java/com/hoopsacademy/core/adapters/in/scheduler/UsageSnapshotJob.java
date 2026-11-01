package com.hoopsacademy.core.adapters.in.scheduler;

import com.hoopsacademy.core.application.usage.SnapshotTenantUsage;
import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;
import org.jboss.logging.Logger;

/** Writes one usage snapshot per ACTIVE tenant and day ({@code hoops.core.usage-snapshot-cron}, 02:30 UTC by default). */
@ApplicationScoped
public class UsageSnapshotJob {

    private static final Logger LOG = Logger.getLogger(UsageSnapshotJob.class);

    private final SnapshotTenantUsage snapshots;

    public UsageSnapshotJob(SnapshotTenantUsage snapshots) {
        this.snapshots = snapshots;
    }

    @Scheduled(identity = "usage-snapshot", cron = "{hoops.core.usage-snapshot-cron}",
            timeZone = "UTC", concurrentExecution = Scheduled.ConcurrentExecution.SKIP)
    public void run() {
        SnapshotTenantUsage.Summary summary = snapshots.run();
        LOG.infof("Usage snapshot: %d tenants, %d failed, %d partial", summary.tenants(), summary.failedTenants(),
                summary.partial());
    }
}
