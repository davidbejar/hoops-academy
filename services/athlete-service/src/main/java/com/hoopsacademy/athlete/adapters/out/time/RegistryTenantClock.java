package com.hoopsacademy.athlete.adapters.out.time;

import com.hoopsacademy.athlete.application.TenantClock;
import com.hoopsacademy.athlete.application.TenantRegistry;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Tenant time: the system clock, the zone of the caller's context on the request path and the tenant registry's zone in
 * the jobs; the configured zone is the last resort for a zone nobody knows.
 */
@ApplicationScoped
class RegistryTenantClock implements TenantClock {

    private final Clock clock;
    private final TenantRegistry registry;
    private final ZoneId lastResort;

    RegistryTenantClock(Clock clock, TenantRegistry registry,
            @ConfigProperty(name = "hoops.athlete.default-timezone") String lastResort) {
        this.clock = clock;
        this.registry = registry;
        this.lastResort = ZoneId.of(lastResort);
    }

    @Override
    public Instant now() {
        return clock.instant();
    }

    @Override
    public ZoneId zoneOf(AuthzContext caller) {
        return caller.timezone().orElse(lastResort);
    }

    @Override
    public ZoneId zoneOf(TenantId tenant) {
        return registry.zoneOf(tenant).orElse(lastResort);
    }
}
