package com.hoopsacademy.core.application.roster;

import com.hoopsacademy.core.application.tenant.TenantSettingsListener;
import com.hoopsacademy.core.domain.tenant.TenantSettings;
import jakarta.enterprise.context.ApplicationScoped;

/** A new age rule or play-up limit re-evaluates the tenant's open assignments in the same transaction. */
@ApplicationScoped
public class ReevaluateOnRuleChange implements TenantSettingsListener {

    private final EligibilityEngine engine;
    private final TenantToday calendar;

    public ReevaluateOnRuleChange(EligibilityEngine engine, TenantToday calendar) {
        this.engine = engine;
        this.calendar = calendar;
    }

    @Override
    public void onEligibilityRulesChanged(TenantSettings before, TenantSettings after) {
        engine.reevaluateTenant(calendar.today(), after);
    }
}
