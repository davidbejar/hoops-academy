package com.hoopsacademy.common.tenancy;

import io.quarkus.hibernate.orm.PersistenceUnitExtension;
import io.quarkus.hibernate.orm.runtime.tenant.TenantResolver;
import jakarta.enterprise.context.ApplicationScoped;

/**
 * Feeds the context tenant to Hibernate discriminator multitenancy
 * ({@code quarkus.hibernate-orm.multitenant=DISCRIMINATOR}, entities annotate their column with
 * {@code @org.hibernate.annotations.TenantId}). Without a bound tenant it returns the nil UUID, which matches no
 * rows — and the RLS policy raises anyway, so a forgotten tenant is loud.
 */
@PersistenceUnitExtension
@ApplicationScoped
public class HibernateTenantResolver implements TenantResolver {

    static final String NO_TENANT = "00000000-0000-0000-0000-000000000000";

    private final CurrentTenant currentTenant;

    public HibernateTenantResolver(CurrentTenant currentTenant) {
        this.currentTenant = currentTenant;
    }

    @Override
    public String getDefaultTenantId() {
        return NO_TENANT;
    }

    @Override
    public String resolveTenantId() {
        return currentTenant.tenantId().map(TenantId::toString).orElse(NO_TENANT);
    }
}
