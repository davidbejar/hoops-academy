package com.hoopsacademy.core.application.platform;

import com.hoopsacademy.core.application.shared.ChangedFields;
import com.hoopsacademy.core.application.port.PlatformAuditLog;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.authz.AuthzCache;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.application.port.PlatformOutboxWriter;
import com.hoopsacademy.core.application.port.TenantRepository;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Patch;
import com.hoopsacademy.core.domain.tenant.Tenant;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.time.Period;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.Map;
import java.util.function.UnaryOperator;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/** Super-admin lifecycle and master-data changes (platform datasource); status changes are published to the outbox. */
@ApplicationScoped
public class TenantLifecycle {

    private final TenantRepository tenants;
    private final PlatformOutboxWriter outbox;
    private final AuthzCache authzCache;
    private final PlatformAuditLog audit;
    private final Clock clock;
    private final Period withdrawnRetention;

    public TenantLifecycle(TenantRepository tenants, PlatformOutboxWriter outbox, AuthzCache authzCache,
            PlatformAuditLog audit, Clock clock,
            @ConfigProperty(name = "hoops.tenant.withdrawn-retention", defaultValue = "P365D") String retention) {
        this.tenants = tenants;
        this.outbox = outbox;
        this.authzCache = authzCache;
        this.audit = audit;
        this.clock = clock;
        this.withdrawnRetention = Period.parse(retention);
    }

    @Transactional
    public Tenant suspend(TenantId id, String reason) {
        return transition(id, AuditAction.TENANT_SUSPENDED, reason, tenant -> tenant.suspend(reason, clock.instant()));
    }

    @Transactional
    public Tenant reactivate(TenantId id) {
        return transition(id, AuditAction.TENANT_REACTIVATED, null, Tenant::reactivate);
    }

    @Transactional
    public Tenant withdraw(TenantId id, String reason) {
        return transition(id, AuditAction.TENANT_WITHDRAWN, reason,
                tenant -> tenant.withdraw(reason, clock.instant(), withdrawnRetention));
    }

    /** An edit that changes no stored value writes nothing (no audit row) and returns the tenant as it is. */
    @Transactional
    public Tenant changeMasterData(TenantId id, Patch<String> name, Patch<ZoneId> timezone, Patch<AppLocale> locale) {
        Tenant before = load(id);
        Tenant changed = before.changeMasterData(name, timezone, locale);
        ChangedFields fields = new ChangedFields().field("name", before.name(), changed.name())
                .field("timezone", before.timezone(), changed.timezone())
                .field("defaultLocale", before.defaultLocale(), changed.defaultLocale());
        if (fields.isEmpty()) {
            return before;
        }
        tenants.update(changed);
        audit.record(id, AuditEvent.of(AuditAction.TENANT_MASTER_DATA_CHANGED, id, Map.of("fields", fields.names())));
        return changed;
    }

    private Tenant transition(TenantId id, AuditAction action, String reason, UnaryOperator<Tenant> change) {
        Tenant changed = change.apply(load(id));
        tenants.update(changed);
        Map<String, Object> payload = new HashMap<>(Map.of("status", changed.status().name()));
        if (reason != null) {
            payload.put("reason", reason);
        }
        outbox.write(new OutboxEvent(id, action.wireName(), "tenant", id.toString(), payload));
        audit.record(id, AuditEvent.of(action, id, payload));
        authzCache.invalidate(id);
        return changed;
    }

    private Tenant load(TenantId id) {
        return tenants.find(id).orElseThrow(() -> new NotFoundException("Tenant not found"));
    }
}
