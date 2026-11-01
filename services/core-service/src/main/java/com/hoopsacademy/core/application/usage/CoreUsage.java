package com.hoopsacademy.core.application.usage;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.application.port.UsageCounter;
import com.hoopsacademy.core.application.port.UsageReport;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Instance;
import java.time.Clock;
import java.util.Map;
import java.util.TreeMap;

/** core's own usage counters of one tenant ({@code /internal/usage/{tenantId}}); counts only, never content. */
@ApplicationScoped
public class CoreUsage {

    public static final String SERVICE = "core";

    private final TenantScope tenantScope;
    private final TenantProfileRepository profiles;
    private final Instance<UsageCounter> counters;
    private final Clock clock;

    public CoreUsage(TenantScope tenantScope, TenantProfileRepository profiles, Instance<UsageCounter> counters,
            Clock clock) {
        this.tenantScope = tenantScope;
        this.profiles = profiles;
        this.counters = counters;
        this.clock = clock;
    }

    public UsageReport of(TenantId tenant) {
        return tenantScope.runAs(tenant, () -> {
            profiles.findCurrent().orElseThrow(() -> new NotFoundException("Tenant not found"));
            Map<String, Long> all = new TreeMap<>();
            counters.forEach(counter -> all.putAll(counter.counters()));
            return new UsageReport(tenant, SERVICE, clock.instant(), null, all);
        });
    }
}
