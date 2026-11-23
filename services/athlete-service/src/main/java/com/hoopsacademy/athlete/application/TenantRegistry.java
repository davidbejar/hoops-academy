package com.hoopsacademy.athlete.application;

import com.hoopsacademy.common.tenancy.TenantId;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

/** Global list of tenants with training data and their time zone (table {@code athlete.tenant_registry}). */
public interface TenantRegistry {

    /** Inserts the tenant or replaces its zone; writes nothing when the zone is unchanged. */
    void register(TenantId tenant, ZoneId zone);

    Optional<ZoneId> zoneOf(TenantId tenant);

    List<TenantId> tenants();
}
