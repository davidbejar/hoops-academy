package com.hoopsacademy.core.application.platform;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.members.LoginProvisioning;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.tenant.Tenant;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.util.Objects;
import java.util.Set;

/**
 * Onboards a tenant atomically across Keycloak, the platform datasource and the tenant's own data (saga, see
 * {@link LoginProvisioning} and docs/wp/WP3 handover):
 * <ol>
 *   <li>validate, check the slug (409 before any side effect);</li>
 *   <li>provision the first ADMIN's login in Keycloak (failure → 502, nothing written);</li>
 *   <li>platform tx: registry row + subscription (failure → delete the created login);</li>
 *   <li>tenant tx as core_app: settings, hooks, person + ADMIN, index, outbox, setup e-mail last
 *       (failure → delete the registry row and the created login).</li>
 * </ol>
 */
@ApplicationScoped
public class CreateTenant {

    private final TenantRegistration registration;
    private final TenantContentProvisioning content;
    private final LoginProvisioning logins;
    private final TenantScope tenantScope;
    private final Clock clock;

    public CreateTenant(TenantRegistration registration, TenantContentProvisioning content, LoginProvisioning logins,
            TenantScope tenantScope, Clock clock) {
        this.registration = registration;
        this.content = content;
        this.logins = logins;
        this.tenantScope = tenantScope;
        this.clock = clock;
    }

    public Tenant handle(CreateTenantCommand command) {
        Tenant tenant = Tenant.onboard(TenantId.random(), command.slug(), command.name(), command.timezone(),
                command.defaultLocale(), clock.instant());
        Person firstAdmin = firstAdmin(command);
        registration.requireSlugAvailable(tenant.slug());

        ProvisionedIdentity login = logins.provision(new NewIdentity(firstAdmin.data().email(),
                firstAdmin.data().givenName(), firstAdmin.data().familyName(), firstAdmin.data().locale()));
        logins.compensateOnFailure(login, () -> {
            registration.register(tenant);
            provisionContent(tenant, firstAdmin, login);
            return tenant;
        });
        return tenant;
    }

    private void provisionContent(Tenant tenant, Person firstAdmin, ProvisionedIdentity login) {
        try {
            tenantScope.runAs(tenant.id(), () -> content.provision(tenant, firstAdmin, login));
        } catch (RuntimeException failure) {
            registration.unregister(tenant.id());
            throw failure;
        }
    }

    private Person firstAdmin(CreateTenantCommand command) {
        CreateTenantCommand.FirstAdmin admin = command.firstAdmin();
        AppLocale locale = Objects.requireNonNullElse(admin.locale(), command.defaultLocale());
        PersonalData data = new PersonalData(admin.givenName(), admin.familyName(), admin.email(), null, null, null,
                locale);
        return Person.create(PersonId.random(), data, Set.of(TenantRole.ADMIN), clock.instant());
    }
}
