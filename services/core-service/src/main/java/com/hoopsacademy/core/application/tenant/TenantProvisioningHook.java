package com.hoopsacademy.core.application.tenant;

import com.hoopsacademy.core.domain.tenant.Tenant;

/**
 * Extension point called inside the new tenant's transaction while it is being onboarded (WP4 seeds the default
 * age categories here). A failing hook rolls back the whole onboarding.
 */
public interface TenantProvisioningHook {

    void onTenantCreated(Tenant tenant);
}
