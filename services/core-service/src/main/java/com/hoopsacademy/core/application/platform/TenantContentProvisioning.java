package com.hoopsacademy.core.application.platform;

import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.events.RosterChanges;
import com.hoopsacademy.core.application.members.MemberProvisioning;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.application.port.OutboxWriter;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.application.port.TenantSettingsRepository;
import com.hoopsacademy.core.application.shared.WithTemporaryPassword;
import com.hoopsacademy.core.application.tenant.TenantProvisioningHook;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.tenant.Tenant;
import com.hoopsacademy.core.domain.tenant.TenantSettings;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Instance;
import jakarta.transaction.Transactional;
import java.util.Map;
import java.util.Optional;

/** Tenant-scoped step of onboarding (runs inside {@code TenantScope.runAs(newTenant)} as core_app). */
@ApplicationScoped
public class TenantContentProvisioning {

    private final TenantSettingsRepository settings;
    private final OutboxWriter outbox;
    private final MemberProvisioning members;
    private final Instance<TenantProvisioningHook> hooks;
    private final AuditLog audit;
    private final RosterChanges changes;

    public TenantContentProvisioning(TenantSettingsRepository settings, OutboxWriter outbox,
            MemberProvisioning members, Instance<TenantProvisioningHook> hooks, AuditLog audit, RosterChanges changes) {
        this.changes = changes;
        this.settings = settings;
        this.outbox = outbox;
        this.members = members;
        this.hooks = hooks;
        this.audit = audit;
    }

    /** The first admin's temporary password (a created login only) is the last step, see {@link MemberProvisioning}. */
    @Transactional
    public WithTemporaryPassword<Person> provision(Tenant tenant, Person firstAdmin, ProvisionedIdentity login) {
        settings.create(TenantSettings.defaults());
        hooks.forEach(hook -> hook.onTenantCreated(tenant));
        changes.tenant();
        outbox.write(new OutboxEvent(tenant.id(), "tenant.created", "tenant", tenant.id().toString(),
                Map.of("slug", tenant.slug().value(), "name", tenant.name())));
        audit.record(AuditEvent.of(AuditAction.TENANT_CREATED, tenant.id(), Map.of("slug", tenant.slug().value())));
        return members.create(firstAdmin, Optional.of(login));
    }
}
