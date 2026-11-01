package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.platform.ActiveTenants;
import com.hoopsacademy.core.application.port.TenantSettingsRepository;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Instant;
import org.jboss.logging.Logger;

/**
 * Re-evaluates every ACTIVE tenant (listed through the platform datasource) in its own {@link TenantScope}
 * transaction, as of {@code now} in that tenant's time zone. A failing tenant is logged and skipped; it never blocks
 * the others. Idempotent (see {@link EligibilityEngine}).
 */
@ApplicationScoped
public class EligibilitySweep {

    private static final Logger LOG = Logger.getLogger(EligibilitySweep.class);

    /** What one sweep did. */
    public record Summary(int tenants, int failedTenants, int openedCases) {}

    private final ActiveTenants activeTenants;
    private final TenantScope tenantScope;
    private final EligibilityEngine engine;
    private final TenantSettingsRepository settings;
    private final TenantToday calendar;

    public EligibilitySweep(ActiveTenants activeTenants, TenantScope tenantScope, EligibilityEngine engine,
            TenantSettingsRepository settings, TenantToday calendar) {
        this.activeTenants = activeTenants;
        this.tenantScope = tenantScope;
        this.engine = engine;
        this.settings = settings;
        this.calendar = calendar;
    }

    public Summary sweepActiveTenants(Instant now) {
        int swept = 0;
        int failed = 0;
        int opened = 0;
        for (TenantId tenant : activeTenants.list()) {
            try {
                opened += tenantScope.runAs(tenant, () -> engine.reevaluateTenant(calendar.at(now),
                        settings.findCurrent().orElseThrow(() -> new NotFoundException("Tenant settings not found")))
                        .size());
                swept++;
            } catch (RuntimeException e) {
                failed++;
                LOG.errorf(e, "Eligibility sweep failed for tenant %s; continuing with the next tenant", tenant);
            }
        }
        return new Summary(swept, failed, opened);
    }
}
