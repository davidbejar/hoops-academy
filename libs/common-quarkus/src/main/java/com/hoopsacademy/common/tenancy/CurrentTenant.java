package com.hoopsacademy.common.tenancy;

import io.quarkus.arc.Arc;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Optional;

/** Safe read access to the bound tenant from any thread: empty when no request context is active. */
@ApplicationScoped
public class CurrentTenant {

    private final TenantContext tenantContext;

    public CurrentTenant(TenantContext tenantContext) {
        this.tenantContext = tenantContext;
    }

    public Optional<TenantId> tenantId() {
        if (!Arc.container().requestContext().isActive()) {
            return Optional.empty();
        }
        return tenantContext.tenantId();
    }
}
