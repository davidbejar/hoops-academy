package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.port.TenantRepository;
import com.hoopsacademy.core.application.port.TenantSettingsRepository;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.tenant.Tenant;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import io.quarkus.narayana.jta.QuarkusTransaction;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.jboss.logging.Logger;

/**
 * Re-evaluates every ACTIVE tenant (listed through the platform datasource) in its own {@link TenantScope}
 * transaction, as of {@code now} in that tenant's time zone. A failing tenant is logged and skipped; it never blocks
 * the others. Idempotent (see {@link EligibilityEngine}).
 */
@ApplicationScoped
public class EligibilitySweep {

    private static final Logger LOG = Logger.getLogger(EligibilitySweep.class);
    private static final int PAGE_SIZE = 200;

    /** What one sweep did. */
    public record Summary(int tenants, int failedTenants, int openedCases) {}

    private final TenantRepository registry;
    private final TenantScope tenantScope;
    private final EligibilityEngine engine;
    private final TenantSettingsRepository settings;
    private final TenantToday calendar;

    public EligibilitySweep(TenantRepository registry, TenantScope tenantScope, EligibilityEngine engine,
            TenantSettingsRepository settings, TenantToday calendar) {
        this.registry = registry;
        this.tenantScope = tenantScope;
        this.engine = engine;
        this.settings = settings;
        this.calendar = calendar;
    }

    public Summary sweepActiveTenants(Instant now) {
        int swept = 0;
        int failed = 0;
        int opened = 0;
        for (TenantId tenant : activeTenants()) {
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

    private List<TenantId> activeTenants() {
        List<TenantId> ids = new ArrayList<>();
        PageResult<Tenant> page;
        int number = 0;
        do {
            PageRequest request = new PageRequest(number++, PAGE_SIZE);
            page = QuarkusTransaction.requiringNew().call(
                    () -> registry.list(Optional.of(TenantStatus.ACTIVE), Optional.empty(), request));
            page.items().forEach(tenant -> ids.add(tenant.id()));
        } while (number < page.totalPages());
        return ids;
    }
}
