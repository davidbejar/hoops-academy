package com.hoopsacademy.core.application.tenant;

import java.util.Map;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
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
    private final AuditLog audit;
    private final TenantContext tenantContext;

    public TenantSettingsService(TenantSettingsRepository settings, Instance<TenantSettingsListener> listeners,
            AuditLog audit, TenantContext tenantContext) {
        this.settings = settings;
        this.listeners = listeners;
        this.audit = audit;
        this.tenantContext = tenantContext;
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
        audit.record(AuditEvent.of(AuditAction.TENANT_SETTINGS_CHANGED, tenantContext.requireTenantId(),
                Map.of("eligibilityRulesChanged", before.eligibilityRulesDifferFrom(next))));
        return next;
    }
}
