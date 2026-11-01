package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.core.application.port.AgeCategoryRepository;
import com.hoopsacademy.core.application.tenant.TenantProvisioningHook;
import com.hoopsacademy.core.domain.roster.DefaultAgeCategories;
import com.hoopsacademy.core.domain.tenant.Tenant;
import jakarta.enterprise.context.ApplicationScoped;

/** Seeds U8 … SENIOR in the new tenant's onboarding transaction (editable afterwards). */
@ApplicationScoped
public class DefaultCategoriesOnOnboarding implements TenantProvisioningHook {

    private final AgeCategoryRepository categories;

    public DefaultCategoriesOnOnboarding(AgeCategoryRepository categories) {
        this.categories = categories;
    }

    @Override
    public void onTenantCreated(Tenant tenant) {
        DefaultAgeCategories.create().forEach(categories::insert);
    }
}
