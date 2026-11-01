package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.common.tenancy.TenantContext;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.UUID;

/** The tenant bound to the current request/job, for rows keyed by the tenant id itself. */
@ApplicationScoped
class BoundTenant {

    private final TenantContext tenantContext;

    BoundTenant(TenantContext tenantContext) {
        this.tenantContext = tenantContext;
    }

    UUID id() {
        return tenantContext.requireTenantId().value();
    }

    boolean isBound() {
        return tenantContext.tenantId().isPresent();
    }
}
