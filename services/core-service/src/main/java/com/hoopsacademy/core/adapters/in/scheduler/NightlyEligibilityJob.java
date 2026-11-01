package com.hoopsacademy.core.adapters.in.scheduler;

import com.hoopsacademy.core.application.roster.EligibilitySweep;
import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import org.jboss.logging.Logger;

/**
 * Triggers the eligibility sweep over all ACTIVE tenants ({@code hoops.core.eligibility-cron}, hourly by default so
 * every tenant is evaluated shortly after its own local midnight; the sweep is idempotent).
 */
@ApplicationScoped
public class NightlyEligibilityJob {

    private static final Logger LOG = Logger.getLogger(NightlyEligibilityJob.class);

    private final EligibilitySweep sweep;
    private final Clock clock;

    public NightlyEligibilityJob(EligibilitySweep sweep, Clock clock) {
        this.sweep = sweep;
        this.clock = clock;
    }

    @Scheduled(identity = "eligibility-sweep", cron = "{hoops.core.eligibility-cron}",
            concurrentExecution = Scheduled.ConcurrentExecution.SKIP)
    public void run() {
        EligibilitySweep.Summary summary = sweep.sweepActiveTenants(clock.instant());
        LOG.infof("Eligibility sweep: %d tenants, %d failed, %d cases opened", summary.tenants(),
                summary.failedTenants(), summary.openedCases());
    }
}
