package com.hoopsacademy.core.application.members;

import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.ProvisionedIdentity;
import com.hoopsacademy.core.application.port.TemporaryPasswordLogins;
import com.hoopsacademy.core.application.port.TemporaryPasswordSweeps;
import com.hoopsacademy.core.domain.identity.TemporaryPassword;
import com.hoopsacademy.core.domain.membership.PersonId;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.util.Optional;

/**
 * Gives a login a temporary password (ADR-0024). Always the LAST step of the caller's transaction: the audit row
 * ({@code member.temporary_password_issued}, without the value) is written first, then Keycloak is called, so a
 * Keycloak failure rolls the whole transaction back. The value is returned once and never stored or logged.
 * Every issue also records its time on the login, enables a login the sweep disabled when its previous temporary
 * password expired, and asks for a background sweep after the commit (ADR-0028) — here, so no caller can forget.
 */
@ApplicationScoped
public class TemporaryPasswords {

    private final TemporaryPasswordGenerator generator;
    private final IdentityProviderPort identityProvider;
    private final AuditLog audit;
    private final TemporaryPasswordLogins logins;
    private final TemporaryPasswordSweeps sweeps;
    private final Clock clock;

    public TemporaryPasswords(TemporaryPasswordGenerator generator, IdentityProviderPort identityProvider,
            AuditLog audit, TemporaryPasswordLogins logins, TemporaryPasswordSweeps sweeps, Clock clock) {
        this.generator = generator;
        this.identityProvider = identityProvider;
        this.audit = audit;
        this.logins = logins;
        this.sweeps = sweeps;
        this.clock = clock;
    }

    /** For a login created by this request only; an existing login keeps its password (empty). */
    public Optional<TemporaryPassword> forCreated(PersonId person, Optional<ProvisionedIdentity> login) {
        return login.filter(ProvisionedIdentity::created).map(created -> issue(person, created.subject()));
    }

    public TemporaryPassword issue(PersonId person, String subject) {
        TemporaryPassword password = generator.next();
        audit.record(AuditEvent.of(AuditAction.MEMBER_TEMPORARY_PASSWORD_ISSUED, person.value()));
        boolean wasExpired = logins.issued(subject, clock.instant());
        identityProvider.setTemporaryPassword(subject, password);
        if (wasExpired) {
            identityProvider.enable(subject);
        }
        sweeps.request();
        return password;
    }
}
