package com.hoopsacademy.core.adapters.out.audit;

import com.hoopsacademy.common.tenancy.TenantContext;
import io.quarkus.arc.Arc;
import io.quarkus.security.identity.SecurityIdentity;
import java.security.Principal;
import java.util.Optional;
import java.util.UUID;
import org.eclipse.microprofile.jwt.JsonWebToken;

/** Who performed an audited action: the JWT {@code sub} (or {@code system} for jobs) and the tenant person, if any. */
record AuditActor(String subject, UUID personId) {

    static final String SYSTEM = "system";

    static AuditActor current(TenantContext tenantContext) {
        UUID person = tenantContext.authz().map(authz -> authz.personId()).orElse(null);
        return new AuditActor(callerSubject().orElse(SYSTEM), person);
    }

    /** The same caller acting as {@code person} of the bound tenant. */
    AuditActor as(UUID person) {
        return new AuditActor(subject, person);
    }

    /** The same caller in another tenant's trail, where the bound tenant's person id means nothing. */
    AuditActor withoutPerson() {
        return new AuditActor(subject, null);
    }

    private static Optional<String> callerSubject() {
        if (!Arc.container().requestContext().isActive()) {
            return Optional.empty();
        }
        SecurityIdentity identity = Arc.container().instance(SecurityIdentity.class).get();
        if (identity == null || identity.isAnonymous()) {
            return Optional.empty();
        }
        Principal principal = identity.getPrincipal();
        if (principal instanceof JsonWebToken jwt && jwt.getSubject() != null) {
            return Optional.of(jwt.getSubject());
        }
        return Optional.ofNullable(principal.getName());
    }
}
