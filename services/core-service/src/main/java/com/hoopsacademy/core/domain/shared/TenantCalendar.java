package com.hoopsacademy.core.domain.shared;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;

/** Calendar dates as a tenant experiences them: "today" starts at local midnight of the academy's time zone. */
public final class TenantCalendar {

    private TenantCalendar() {}

    public static LocalDate today(Instant now, ZoneId tenantZone) {
        return LocalDate.ofInstant(now, tenantZone);
    }
}
