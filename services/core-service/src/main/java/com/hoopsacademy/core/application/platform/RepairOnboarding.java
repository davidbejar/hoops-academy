package com.hoopsacademy.core.application.platform;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.port.TenantRepository;
import com.hoopsacademy.core.application.port.TenantSettingsRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * Closes the onboarding crash window of the CreateTenant saga (ADR-0013, WP17): a registry row older than the grace
 * period whose tenant has no settings never finished provisioning (the process died between the platform and the
 * tenant transaction) — its registry row and subscription are deleted, so the slug becomes free again. Only rows
 * created within the look-back window are examined. The Keycloak login of such an attempt cannot be identified here
 * (its id was never stored) and is logged for manual clean-up.
 */
@ApplicationScoped
public class RepairOnboarding {

    private static final Logger LOG = Logger.getLogger(RepairOnboarding.class);

    public record Summary(int examined, int removed, int failed) {}

    private final TenantRepository tenants;
    private final TenantSettingsRepository settings;
    private final TenantRegistration registration;
    private final TenantScope tenantScope;
    private final Clock clock;
    private final Duration grace;
    private final Duration lookBack;

    public RepairOnboarding(TenantRepository tenants, TenantSettingsRepository settings,
            TenantRegistration registration, TenantScope tenantScope, Clock clock,
            @ConfigProperty(name = "hoops.core.onboarding-repair.grace", defaultValue = "PT15M") Duration grace,
            @ConfigProperty(name = "hoops.core.onboarding-repair.look-back", defaultValue = "P7D") Duration lookBack) {
        this.tenants = tenants;
        this.settings = settings;
        this.registration = registration;
        this.tenantScope = tenantScope;
        this.clock = clock;
        this.grace = grace;
        this.lookBack = lookBack;
    }

    public Summary run() {
        Instant now = clock.instant();
        List<TenantId> candidates = candidates(now.minus(lookBack), now.minus(grace));
        int removed = 0;
        int failed = 0;
        for (TenantId tenant : candidates) {
            try {
                if (!provisioned(tenant)) {
                    registration.unregister(tenant);
                    removed++;
                    LOG.warnf("Removed tenant %s left behind by an interrupted onboarding; its Keycloak login (if any) "
                            + "must be deleted manually", tenant);
                }
            } catch (RuntimeException e) {
                failed++;
                LOG.errorf(e, "Onboarding repair failed for tenant %s", tenant);
            }
        }
        return new Summary(candidates.size(), removed, failed);
    }

    @Transactional
    List<TenantId> candidates(Instant from, Instant to) {
        return tenants.createdBetween(from, to);
    }

    private boolean provisioned(TenantId tenant) {
        return tenantScope.runAs(tenant, () -> settings.findCurrent().isPresent());
    }
}
