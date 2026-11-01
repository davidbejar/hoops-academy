package com.hoopsacademy.game.application;

import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantId;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.UUID;

/** The caller and tenant of the current request, as the use cases need them. */
@ApplicationScoped
public class CurrentCaller {

    private final TenantContext tenantContext;

    public CurrentCaller(TenantContext tenantContext) {
        this.tenantContext = tenantContext;
    }

    public TenantId tenantId() {
        return tenantContext.requireTenantId();
    }

    public UUID personId() {
        return tenantContext.requireAuthz().personId();
    }
}
