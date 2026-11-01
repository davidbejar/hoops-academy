package com.hoopsacademy.core.adapters.in.scheduler;

import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.platform.RepairOnboarding;
import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;
import org.jboss.logging.Logger;

/** Removes half-onboarded tenants ({@code hoops.core.onboarding-repair-cron}, every 10 min); one replica at a time. */
@ApplicationScoped
public class OnboardingRepairJob {

    /** Cluster-wide lock name ({@code TenantScope.runExclusive}). */
    public static final String LOCK = "core.onboarding-repair";

    private static final Logger LOG = Logger.getLogger(OnboardingRepairJob.class);

    private final RepairOnboarding repair;
    private final TenantScope tenantScope;

    public OnboardingRepairJob(RepairOnboarding repair, TenantScope tenantScope) {
        this.repair = repair;
        this.tenantScope = tenantScope;
    }

    @Scheduled(identity = "onboarding-repair", cron = "{hoops.core.onboarding-repair-cron}",
            concurrentExecution = Scheduled.ConcurrentExecution.SKIP)
    public void run() {
        tenantScope.runExclusive(LOCK, () -> {
            RepairOnboarding.Summary summary = repair.run();
            if (summary.removed() > 0 || summary.failed() > 0) {
                LOG.infof("Onboarding repair: %d examined, %d removed, %d failed", summary.examined(),
                        summary.removed(), summary.failed());
            }
        });
    }
}
