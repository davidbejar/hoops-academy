package com.hoopsacademy.core.application.platform;

import com.hoopsacademy.core.application.members.MemberProvisioning;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.application.port.OutboxWriter;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.application.port.TenantSettingsRepository;
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

    public TenantContentProvisioning(TenantSettingsRepository settings, OutboxWriter outbox,
            MemberProvisioning members, Instance<TenantProvisioningHook> hooks) {
        this.settings = settings;
        this.outbox = outbox;
        this.members = members;
        this.hooks = hooks;
    }

    @Transactional
    public Person provision(Tenant tenant, Person firstAdmin, ProvisionedIdentity login) {
        settings.create(TenantSettings.defaults());
        hooks.forEach(hook -> hook.onTenantCreated(tenant));
        outbox.write(new OutboxEvent(tenant.id(), "tenant.created", "tenant", tenant.id().toString(),
                Map.of("slug", tenant.slug().value(), "name", tenant.name())));
        return members.create(firstAdmin, Optional.of(login));
    }
}
