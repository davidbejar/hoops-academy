package com.hoopsacademy.core.adapters.out.billing;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.EntitlementService;
import io.quarkus.arc.DefaultBean;
import jakarta.enterprise.context.ApplicationScoped;

/** v1: every tenant is on the unlimited FREE plan. A billing module replaces this default bean. */
@DefaultBean
@ApplicationScoped
class NoopEntitlementService implements EntitlementService {

    @Override
    public void check(TenantId tenant, Limit limit) {
        // unlimited in v1
    }
}
