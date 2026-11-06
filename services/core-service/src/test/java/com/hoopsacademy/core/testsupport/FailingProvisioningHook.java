package com.hoopsacademy.core.testsupport;

import com.hoopsacademy.core.application.tenant.TenantProvisioningHook;
import com.hoopsacademy.core.domain.tenant.Tenant;
import jakarta.enterprise.context.ApplicationScoped;

/** Simulates a database failure in the tenant-scoped part of CreateTenant for slugs starting with {@code fail-db}. */
@ApplicationScoped
public class FailingProvisioningHook implements TenantProvisioningHook {

    public static final String SLUG_PREFIX = "fail-db";

    /** The id of the last tenant whose provisioning this hook failed. */
    public static volatile String lastFailed;

    @Override
    public void onTenantCreated(Tenant tenant) {
        if (tenant.slug().value().startsWith(SLUG_PREFIX)) {
            lastFailed = tenant.id().toString();
            throw new IllegalStateException("simulated database failure while provisioning " + tenant.slug());
        }
    }
}
