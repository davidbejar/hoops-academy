package com.hoopsacademy.athlete.adapters.out.time;

import com.hoopsacademy.athlete.application.TenantClock;
import com.hoopsacademy.athlete.application.TenantRegistry;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/** Tenant time: the system clock plus the zone stored in the tenant registry (configured default when unknown). */
@ApplicationScoped
class RegistryTenantClock implements TenantClock {

    private final Clock clock;
    private final TenantRegistry registry;
    private final ZoneId defaultZone;

    RegistryTenantClock(Clock clock, TenantRegistry registry,
            @ConfigProperty(name = "hoops.athlete.default-timezone", defaultValue = "Europe/Madrid") String defaultZone) {
        this.clock = clock;
        this.registry = registry;
        this.defaultZone = ZoneId.of(defaultZone);
    }

    @Override
    public Instant now() {
        return clock.instant();
    }

    @Override
    public ZoneId zoneOf(TenantId tenant) {
        return registry.zoneOf(tenant).orElse(defaultZone);
    }
}
