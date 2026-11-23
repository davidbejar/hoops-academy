package com.hoopsacademy.athlete.application;

import com.hoopsacademy.common.tenancy.AuthzContext;
import jakarta.enterprise.context.ApplicationScoped;

/**
 * Remembers the caller's tenant in the registry with the zone its requests use ({@link TenantClock#zoneOf(AuthzContext)}),
 * so the nightly job materialises the tenant's sessions in the same zone.
 */
@ApplicationScoped
public class TenantZones {

    private final TenantRegistry registry;
    private final TenantClock clock;

    public TenantZones(TenantRegistry registry, TenantClock clock) {
        this.registry = registry;
        this.clock = clock;
    }

    public void remember(AuthzContext caller) {
        registry.register(caller.tenantId(), clock.zoneOf(caller));
    }
}
