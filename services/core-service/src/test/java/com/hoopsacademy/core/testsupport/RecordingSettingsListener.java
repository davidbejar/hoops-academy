package com.hoopsacademy.core.testsupport;

import com.hoopsacademy.core.application.tenant.TenantSettingsListener;
import com.hoopsacademy.core.domain.tenant.TenantSettings;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.concurrent.atomic.AtomicInteger;

/** Counts eligibility-rule changes (stands in for WP4's re-evaluation). */
@ApplicationScoped
public class RecordingSettingsListener implements TenantSettingsListener {

    private final AtomicInteger calls = new AtomicInteger();

    @Override
    public void onEligibilityRulesChanged(TenantSettings before, TenantSettings after) {
        calls.incrementAndGet();
    }

    public int calls() {
        return calls.get();
    }
}
