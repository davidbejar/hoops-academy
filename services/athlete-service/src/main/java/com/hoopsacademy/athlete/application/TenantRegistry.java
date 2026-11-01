package com.hoopsacademy.athlete.application;

import com.hoopsacademy.common.tenancy.TenantId;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

/** Global list of tenants with training data and their time zone (table {@code athlete.tenant_registry}). */
public interface TenantRegistry {

    /** Inserts or replaces the zone of the tenant. */
    void register(TenantId tenant, ZoneId zone);

    /** Inserts the tenant with {@code zone} unless it is already known (an existing zone is kept). */
    void registerIfAbsent(TenantId tenant, ZoneId zone);

    Optional<ZoneId> zoneOf(TenantId tenant);

    List<TenantId> tenants();
}
