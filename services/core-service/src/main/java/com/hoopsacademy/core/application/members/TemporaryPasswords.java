package com.hoopsacademy.core.application.members;

import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.domain.identity.TemporaryPassword;
import com.hoopsacademy.core.domain.membership.PersonId;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Optional;

/**
 * Gives a login a temporary password (ADR-0024). Always the LAST step of the caller's transaction: the audit row
 * ({@code member.temporary_password_issued}, without the value) is written first, then Keycloak is called, so a
 * Keycloak failure rolls the whole transaction back. The value is returned once and never stored or logged.
 */
@ApplicationScoped
public class TemporaryPasswords {

    public static final String ISSUED = "member.temporary_password_issued";

    private final TemporaryPasswordGenerator generator;
    private final IdentityProviderPort identityProvider;
    private final AuditLog audit;

    public TemporaryPasswords(TemporaryPasswordGenerator generator, IdentityProviderPort identityProvider,
            AuditLog audit) {
        this.generator = generator;
        this.identityProvider = identityProvider;
        this.audit = audit;
    }

    /** For a login created by this request only; an existing login keeps its password (empty). */
    public Optional<TemporaryPassword> forCreated(PersonId person, Optional<ProvisionedIdentity> login) {
        return login.filter(ProvisionedIdentity::created).map(created -> issue(person, created.subject()));
    }

    public TemporaryPassword issue(PersonId person, String subject) {
        TemporaryPassword password = generator.next();
        audit.record(AuditEvent.of(ISSUED, "person", person.value()));
        identityProvider.setTemporaryPassword(subject, password);
        return password;
    }
}
