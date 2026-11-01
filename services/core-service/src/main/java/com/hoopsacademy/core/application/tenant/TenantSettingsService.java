package com.hoopsacademy.core.application.tenant;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.core.application.port.TenantSettingsRepository;
import com.hoopsacademy.core.domain.tenant.TenantSettings;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Instance;
import jakarta.transaction.Transactional;

/** Roster rules and defaults; a change of the eligibility rules notifies the listeners (WP4) in the same tx. */
@ApplicationScoped
public class TenantSettingsService {

    private final TenantSettingsRepository settings;
    private final Instance<TenantSettingsListener> listeners;

    public TenantSettingsService(TenantSettingsRepository settings, Instance<TenantSettingsListener> listeners) {
        this.settings = settings;
        this.listeners = listeners;
    }

    @Transactional
    public TenantSettings get() {
        return settings.findCurrent().orElseThrow(() -> new NotFoundException("Tenant settings not found"));
    }

    @Transactional
    public TenantSettings replace(TenantSettings next) {
        TenantSettings before = get();
        settings.save(next);
        if (before.eligibilityRulesDifferFrom(next)) {
            listeners.forEach(listener -> listener.onEligibilityRulesChanged(before, next));
        }
        return next;
    }
}
