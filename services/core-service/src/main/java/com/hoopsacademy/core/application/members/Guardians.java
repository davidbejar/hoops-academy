package com.hoopsacademy.core.application.members;

import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.members.GuardianLinkService.LinkView;
import com.hoopsacademy.core.application.port.EntitlementService;
import com.hoopsacademy.core.application.port.NewIdentity;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.application.shared.WithTemporaryPassword;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PersonalData;
import com.hoopsacademy.core.domain.membership.PlayerId;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.util.Optional;
import java.util.Set;

/**
 * Logins for guardians (WP58, ADR-0024 amendment). A guardian added with an e-mail gets a login like an invited member,
 * and a guardian added earlier without one gets it from the "issue temporary password" action. Both run the
 * invitation saga of {@link LoginProvisioning}: Keycloak first (an e-mail that already signs in — another academy,
 * ADR-0025 — is linked and keeps its password), then one tenant transaction whose last step is the temporary password
 * of a login this request created; on failure that login is deleted again.
 */
@ApplicationScoped
public class Guardians {

    /** A new guardian (PARENT member) of {@code player}; {@code data.email()} null = no login. */
    public record NewGuardian(PersonalData data, PlayerId player) {}

    private final TenantContext tenantContext;
    private final EntitlementService entitlements;
    private final GuardianLinkService links;
    private final MemberProvisioning provisioning;
    private final LoginProvisioning logins;
    private final IssueTemporaryPassword reissue;
    private final MemberQueries queries;
    private final Clock clock;

    public Guardians(TenantContext tenantContext, EntitlementService entitlements, GuardianLinkService links,
            MemberProvisioning provisioning, LoginProvisioning logins, IssueTemporaryPassword reissue,
            MemberQueries queries, Clock clock) {
        this.tenantContext = tenantContext;
        this.entitlements = entitlements;
        this.links = links;
        this.provisioning = provisioning;
        this.logins = logins;
        this.reissue = reissue;
        this.queries = queries;
        this.clock = clock;
    }

    /** Unknown player (404) and a taken e-mail (409) are refused before Keycloak is called. */
    public WithTemporaryPassword<LinkView> add(NewGuardian guardian) {
        entitlements.check(tenantContext.requireTenantId(), EntitlementService.Limit.MEMBERS);
        Person draft = Person.create(PersonId.random(), guardian.data(), Set.of(TenantRole.PARENT), clock.instant());
        PersonalData data = draft.data();
        links.requirePlayer(guardian.player());
        provisioning.requireEmailAvailable(data.email());
        if (data.email() == null) {
            return links.createWithNewGuardian(draft, guardian.player(), Optional.empty());
        }
        ProvisionedIdentity login = logins.provision(
                new NewIdentity(data.email(), data.givenName(), data.familyName(), data.locale()));
        return logins.compensateOnFailure(login,
                () -> links.createWithNewGuardian(draft, guardian.player(), Optional.of(login)));
    }

    /**
     * The academy ADMIN's "issue temporary password" on a member: a guardian without a login gets a first one (see
     * {@link MemberProvisioning#missingGuardianLogin}); everyone else follows the re-issue rules of
     * {@link IssueTemporaryPassword}.
     */
    public WithTemporaryPassword<MemberView> issueTemporaryPassword(PersonId id) {
        Optional<NewIdentity> missing = provisioning.missingGuardianLogin(id);
        if (missing.isEmpty()) {
            return reissue.handle(id);
        }
        ProvisionedIdentity login = logins.provision(missing.get());
        return logins.compensateOnFailure(login, () -> provisioning.grantLogin(id, login)).map(queries::view);
    }
}
