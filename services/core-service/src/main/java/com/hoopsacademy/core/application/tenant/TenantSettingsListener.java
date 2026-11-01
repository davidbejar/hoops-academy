package com.hoopsacademy.core.application.tenant;

import com.hoopsacademy.core.domain.tenant.TenantSettings;

/** Extension point: WP4 re-evaluates eligibility when the age rule or play-up limit changes. Same transaction. */
public interface TenantSettingsListener {

    void onEligibilityRulesChanged(TenantSettings before, TenantSettings after);
}
