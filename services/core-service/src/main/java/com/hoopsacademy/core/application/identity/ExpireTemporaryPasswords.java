package com.hoopsacademy.core.application.identity;

import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.PendingLoginPersons;
import com.hoopsacademy.core.application.port.TemporaryPasswordLogins;
import com.hoopsacademy.core.domain.identity.UserId;
import io.quarkus.narayana.jta.QuarkusTransaction;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * Expires temporary passwords nobody used within {@code hoops.temporary-password.ttl} (default 3 days, ADR-0028).
 * Each due login gets its own transaction with no tenant bound: its {@code core.app_user} row is locked and re-checked
 * (a concurrent re-issue wins), then
 * <ul>
 *   <li>the person chose a password of their own (Keycloak) ⇒ the issue time is only forgotten, nothing expires;</li>
 *   <li>otherwise ⇒ expired: the expiry time is set, every academy where the login has a PENDING person gets the
 *       audit row {@value #EXPIRED} (target that person, no personal data), and the Keycloak login is disabled LAST,
 *       so a Keycloak failure rolls the login's transaction back and the next sweep retries it.</li>
 * </ul>
 * Runs from {@code TemporaryPasswordSweepJob} under its cluster lock; a failure of one login never stops the others.
 */
@ApplicationScoped
public class ExpireTemporaryPasswords {

    public static final String EXPIRED = "member.temporary_password_expired";

    private static final Logger LOG = Logger.getLogger(ExpireTemporaryPasswords.class);

    /** What one sweep did: logins found due, expired, forgotten (own password) and failed (retried next time). */
    public record Summary(int examined, int expired, int forgotten, int failed) {}

    private enum Outcome { EXPIRED, FORGOTTEN, NOT_DUE }

    private final TemporaryPasswordLogins logins;
    private final PendingLoginPersons pendingPersons;
    private final IdentityProviderPort identityProvider;
    private final Clock clock;
    private final Duration ttl;

    public ExpireTemporaryPasswords(TemporaryPasswordLogins logins, PendingLoginPersons pendingPersons,
            IdentityProviderPort identityProvider, Clock clock,
            @ConfigProperty(name = "hoops.temporary-password.ttl", defaultValue = "P3D") Duration ttl) {
        this.logins = logins;
        this.pendingPersons = pendingPersons;
        this.identityProvider = identityProvider;
        this.clock = clock;
        this.ttl = ttl;
    }

    public Summary run() {
        Instant now = clock.instant();
        Instant cutoff = now.minus(ttl);
        List<String> due = QuarkusTransaction.requiringNew().call(() -> logins.due(cutoff));
        int expired = 0;
        int forgotten = 0;
        int failed = 0;
        for (String subject : due) {
            try {
                Outcome outcome = QuarkusTransaction.requiringNew().call(() -> expire(subject, cutoff, now));
                expired += outcome == Outcome.EXPIRED ? 1 : 0;
                forgotten += outcome == Outcome.FORGOTTEN ? 1 : 0;
            } catch (RuntimeException e) {
                failed++;
                LOG.warnf("A temporary password could not be expired, the next sweep retries it: %s", e.toString());
            }
        }
        return new Summary(due.size(), expired, forgotten, failed);
    }

    private Outcome expire(String subject, Instant cutoff, Instant now) {
        Optional<UserId> login = logins.lockIfDue(subject, cutoff);
        if (login.isEmpty()) {
            return Outcome.NOT_DUE;
        }
        if (identityProvider.hasOwnPassword(subject)) {
            logins.used(subject);
            return Outcome.FORGOTTEN;
        }
        logins.expired(subject, now);
        pendingPersons.recordForEach(subject, login.get(), person -> AuditEvent.of(EXPIRED, "person", person.value()));
        identityProvider.disable(subject);
        return Outcome.EXPIRED;
    }
}
