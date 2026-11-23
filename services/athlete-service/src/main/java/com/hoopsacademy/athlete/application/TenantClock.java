package com.hoopsacademy.athlete.application;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;

/** Time as seen by a tenant: the current instant and the tenant's time zone. */
public interface TenantClock {

    Instant now();

    /**
     * The zone of the caller's tenant: the one its {@link AuthzContext} carries (core always sends it, ADR-0037's
     * replica too), else a configured last resort (core sent a zone this JVM does not know). Reads nothing.
     */
    ZoneId zoneOf(AuthzContext caller);

    /** The zone a job uses for a tenant: the one the tenant registry holds, else the same last resort. */
    ZoneId zoneOf(TenantId tenant);

    default LocalDate today(AuthzContext caller) {
        return now().atZone(zoneOf(caller)).toLocalDate();
    }
}
