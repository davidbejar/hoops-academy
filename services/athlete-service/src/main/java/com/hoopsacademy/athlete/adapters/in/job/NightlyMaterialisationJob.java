package com.hoopsacademy.athlete.adapters.in.job;

import com.hoopsacademy.athlete.application.NightlyMaterialisation;
import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;

/** Triggers the nightly materialisation on the configured cron ({@code hoops.athlete.materialise.cron}). */
@ApplicationScoped
public class NightlyMaterialisationJob {

    private final NightlyMaterialisation materialisation;

    NightlyMaterialisationJob(NightlyMaterialisation materialisation) {
        this.materialisation = materialisation;
    }

    @Scheduled(cron = "{hoops.athlete.materialise.cron}", identity = "athlete-materialise",
            concurrentExecution = Scheduled.ConcurrentExecution.SKIP)
    void run() {
        materialisation.run();
    }
}
