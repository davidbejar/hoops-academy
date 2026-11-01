package com.hoopsacademy.athlete.application;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import jakarta.enterprise.context.ApplicationScoped;
import org.jboss.logging.Logger;

/**
 * Keeps the 8-week horizon filled: for every tenant in the registry, materialise inside that tenant's scope. A
 * failing tenant is logged and skipped so it cannot block the others.
 */
@ApplicationScoped
public class NightlyMaterialisation {

    private static final Logger LOG = Logger.getLogger(NightlyMaterialisation.class);

    private final TenantRegistry registry;
    private final TenantScope tenantScope;
    private final MaterialiseSessions materialise;

    public NightlyMaterialisation(TenantRegistry registry, TenantScope tenantScope, MaterialiseSessions materialise) {
        this.registry = registry;
        this.tenantScope = tenantScope;
        this.materialise = materialise;
    }

    /** @return the number of sessions created over all tenants */
    public int run() {
        int created = 0;
        for (TenantId tenant : registry.tenants()) {
            try {
                created += tenantScope.runAs(tenant, materialise::forAllSchedules);
            } catch (RuntimeException e) {
                LOG.errorf(e, "Materialisation failed for tenant %s", tenant);
            }
        }
        LOG.infof("Nightly materialisation created %d sessions", created);
        return created;
    }
}
