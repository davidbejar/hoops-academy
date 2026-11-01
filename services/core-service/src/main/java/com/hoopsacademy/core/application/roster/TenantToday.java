package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.domain.shared.TenantCalendar;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;

/** "Today" in the bound tenant's time zone. */
@ApplicationScoped
public class TenantToday {

    private final TenantProfileRepository profiles;
    private final Clock clock;

    public TenantToday(TenantProfileRepository profiles, Clock clock) {
        this.profiles = profiles;
        this.clock = clock;
    }

    public LocalDate today() {
        return at(clock.instant());
    }

    public LocalDate at(Instant instant) {
        TenantProfile profile = profiles.findCurrent().orElseThrow(() -> new NotFoundException("Tenant not found"));
        return TenantCalendar.today(instant, profile.timezone());
    }
}
