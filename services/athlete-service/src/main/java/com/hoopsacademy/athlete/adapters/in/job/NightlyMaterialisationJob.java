package com.hoopsacademy.athlete.adapters.in.job;

import com.hoopsacademy.athlete.application.NightlyMaterialisation;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;

/**
 * Triggers the nightly materialisation on the configured cron ({@code hoops.athlete.materialise.cron}). With several
 * replicas only the one holding the advisory lock {@link #LOCK} runs it ({@link TenantScope#runExclusive}), so an API
 * call never races a second replica's materialisation into a unique violation.
 */
@ApplicationScoped
public class NightlyMaterialisationJob {

    /** Cluster-wide lock name of the job. */
    public static final String LOCK = "athlete.materialisation";

    private final NightlyMaterialisation materialisation;
    private final TenantScope tenantScope;

    NightlyMaterialisationJob(NightlyMaterialisation materialisation, TenantScope tenantScope) {
        this.materialisation = materialisation;
        this.tenantScope = tenantScope;
    }

    @Scheduled(cron = "{hoops.athlete.materialise.cron}", identity = "athlete-materialise",
            concurrentExecution = Scheduled.ConcurrentExecution.SKIP)
    void scheduled() {
        run();
    }

    /** @return false when another replica was running it (this run is skipped) */
    public boolean run() {
        return tenantScope.runExclusive(LOCK, materialisation::run);
    }
}
