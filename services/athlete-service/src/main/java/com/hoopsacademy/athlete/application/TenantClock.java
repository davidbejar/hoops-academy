package com.hoopsacademy.athlete.application;

import com.hoopsacademy.common.tenancy.TenantId;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;

/** Time as seen by a tenant: the current instant and the tenant's time zone. */
public interface TenantClock {

    Instant now();

    ZoneId zoneOf(TenantId tenant);

    default LocalDate today(TenantId tenant) {
        return now().atZone(zoneOf(tenant)).toLocalDate();
    }
}
