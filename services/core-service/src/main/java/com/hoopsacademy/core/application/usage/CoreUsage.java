package com.hoopsacademy.core.application.usage;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.port.UsageCounter;
import com.hoopsacademy.core.application.port.UsageReport;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Instance;
import java.time.Clock;
import java.util.Map;
import java.util.TreeMap;

/**
 * core's own usage counters of one tenant ({@code /internal/usage/{tenantId}}); counts only, never content. An unknown
 * tenant has zero counters (contract: like game and athlete); the platform endpoint checks existence itself.
 */
@ApplicationScoped
public class CoreUsage {

    public static final String SERVICE = "core";

    private final TenantScope tenantScope;
    private final Instance<UsageCounter> counters;
    private final Clock clock;

    public CoreUsage(TenantScope tenantScope, Instance<UsageCounter> counters,
            Clock clock) {
        this.tenantScope = tenantScope;
        this.counters = counters;
        this.clock = clock;
    }

    public UsageReport of(TenantId tenant) {
        return tenantScope.runAs(tenant, () -> {
            Map<String, Long> all = new TreeMap<>();
            counters.forEach(counter -> all.putAll(counter.counters()));
            return new UsageReport(tenant, SERVICE, clock.instant(), null, all);
        });
    }
}
