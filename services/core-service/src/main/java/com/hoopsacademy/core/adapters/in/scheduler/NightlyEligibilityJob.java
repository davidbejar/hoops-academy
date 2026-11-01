package com.hoopsacademy.core.adapters.in.scheduler;

import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.roster.EligibilitySweep;
import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import org.jboss.logging.Logger;

/**
 * Triggers the eligibility sweep over all ACTIVE tenants ({@code hoops.core.eligibility-cron}, hourly by default so
 * every tenant is evaluated shortly after its own local midnight; the sweep is idempotent). With several replicas only
 * the one that gets the advisory lock {@link #LOCK} runs it ({@link TenantScope#runExclusive}); the others skip.
 */
@ApplicationScoped
public class NightlyEligibilityJob {

    /** Cluster-wide lock name: one replica runs the job ({@code TenantScope.runExclusive}). */
    public static final String LOCK = "core.eligibility-sweep";

    private static final Logger LOG = Logger.getLogger(NightlyEligibilityJob.class);

    private final EligibilitySweep sweep;
    private final Clock clock;
    private final TenantScope tenantScope;

    public NightlyEligibilityJob(EligibilitySweep sweep, Clock clock, TenantScope tenantScope) {
        this.sweep = sweep;
        this.clock = clock;
        this.tenantScope = tenantScope;
    }

    @Scheduled(identity = "eligibility-sweep", cron = "{hoops.core.eligibility-cron}",
            concurrentExecution = Scheduled.ConcurrentExecution.SKIP)
    public void run() {
        tenantScope.runExclusive(LOCK, () -> {
            EligibilitySweep.Summary summary = sweep.sweepActiveTenants(clock.instant());
            LOG.infof("Eligibility sweep: %d tenants, %d failed, %d cases opened", summary.tenants(),
                    summary.failedTenants(), summary.openedCases());
        });
    }
}
