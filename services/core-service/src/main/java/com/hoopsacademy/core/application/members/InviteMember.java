package com.hoopsacademy.core.application.members;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.core.application.port.EntitlementService;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalData;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.util.Optional;

/**
 * Invites a member: validate → (optional) provision the login in Keycloak → create person/roles/player in one
 * tenant transaction (setup e-mail last) → on failure delete the login this call created (saga, see
 * {@link LoginProvisioning}).
 */
@ApplicationScoped
public class InviteMember {

    public static final String INVITATION_REQUIRES_EMAIL = "INVITATION_REQUIRES_EMAIL";

    private final TenantContext tenantContext;
    private final EntitlementService entitlements;
    private final MemberProvisioning provisioning;
    private final LoginProvisioning logins;
    private final MemberQueries queries;
    private final Clock clock;

    public InviteMember(TenantContext tenantContext, EntitlementService entitlements, MemberProvisioning provisioning,
            LoginProvisioning logins, MemberQueries queries, Clock clock) {
        this.tenantContext = tenantContext;
        this.entitlements = entitlements;
        this.provisioning = provisioning;
        this.logins = logins;
        this.queries = queries;
        this.clock = clock;
    }

    public MemberView handle(InviteMemberCommand command) {
        entitlements.check(tenantContext.requireTenantId(), EntitlementService.Limit.MEMBERS);
        Person draft = Person.create(PersonId.random(), command.data(), command.roles(), clock.instant());
        PersonalData data = draft.data();
        if (command.sendInvitation() && data.email() == null) {
            throw new DomainRuleViolation("An invitation needs an e-mail address", INVITATION_REQUIRES_EMAIL);
        }
        provisioning.requireEmailAvailable(data.email());
        if (!command.sendInvitation()) {
            return queries.view(provisioning.create(draft, Optional.empty()));
        }
        ProvisionedIdentity login = logins.provision(
                new NewIdentity(data.email(), data.givenName(), data.familyName(), data.locale()));
        Person created = logins.compensateOnFailure(login, () -> provisioning.create(draft, Optional.of(login)));
        return queries.view(created);
    }
}
