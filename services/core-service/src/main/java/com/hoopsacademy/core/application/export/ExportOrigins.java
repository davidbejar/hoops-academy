package com.hoopsacademy.core.application.export;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.domain.shared.TenantCalendar;
import com.hoopsacademy.core.domain.tenant.Tenant;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;

/** The origin of an export (ADR-0048): an academy's slug, zone and today there, or the platform's in UTC. */
@ApplicationScoped
public class ExportOrigins {

    /** The slug of an export of every academy. */
    public static final String PLATFORM = "platform";

    private final TenantProfileRepository profiles;
    private final Clock clock;

    public ExportOrigins(TenantProfileRepository profiles, Clock clock) {
        this.profiles = profiles;
        this.clock = clock;
    }

    /** The bound academy. */
    public ExportOrigin current() {
        TenantProfile profile = profiles.findCurrent().orElseThrow(() -> new NotFoundException("Tenant not found"));
        return of(profile.slug(), profile.timezone());
    }

    /** An academy of the registry (platform path). */
    public ExportOrigin of(Tenant tenant) {
        return of(tenant.slug().value(), tenant.timezone());
    }

    /** Every academy: the day in UTC. */
    public ExportOrigin platform() {
        return of(PLATFORM, ZoneOffset.UTC);
    }

    public Instant now() {
        return clock.instant();
    }

    private ExportOrigin of(String slug, ZoneId zone) {
        return new ExportOrigin(slug, zone, TenantCalendar.today(clock.instant(), zone));
    }
}
