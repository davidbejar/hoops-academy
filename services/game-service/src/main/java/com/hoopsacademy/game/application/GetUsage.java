package com.hoopsacademy.game.application;

import jakarta.enterprise.context.ApplicationScoped;

/** Usage counters of the bound tenant; call inside {@code TenantScope.runAs}. */
@ApplicationScoped
public class GetUsage {

    private final UsageCounter counter;

    public GetUsage(UsageCounter counter) {
        this.counter = counter;
    }

    public UsageCounter.Usage handle() {
        return counter.usage();
    }
}
