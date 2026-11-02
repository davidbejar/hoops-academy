package com.hoopsacademy.core.application.members;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.core.application.port.AppUserRepository;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.LoginUpdate;
import com.hoopsacademy.core.application.port.MembershipRepository;
import com.hoopsacademy.core.domain.identity.AppUser;
import com.hoopsacademy.core.domain.membership.InvitationStatus;
import com.hoopsacademy.core.domain.membership.Person;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

/**
 * Keeps the login of a member on the member's e-mail (ADR-0023): when the e-mail of a person with a login changes,
 * {@code core.app_user.email} and the Keycloak user (username = e-mail) follow, inside the member's transaction with
 * the Keycloak call last, so a Keycloak failure rolls the database back.
 */
@ApplicationScoped
public class LoginEmailSync {

    public static final String LOGIN_SHARED = "LOGIN_SHARED";
    public static final String LOGIN_REQUIRES_EMAIL = "LOGIN_REQUIRES_EMAIL";

    /** Who may move a login that is also linked to a person of another tenant. */
    public enum SharedLogin {
        /** Academy admins: refused with 409 {@value #LOGIN_SHARED} (no cross-tenant account takeover). */
        REFUSE,
        /** The platform super admin: always synced. */
        SYNC
    }

    /** A login move validated by {@link #plan} and performed by {@link #apply}. */
    public record LoginMove(Person person, AppUser login) {}

    private final AppUserRepository appUsers;
    private final MembershipRepository memberships;
    private final IdentityProviderPort identityProvider;
    private final AuditLog audit;

    public LoginEmailSync(AppUserRepository appUsers, MembershipRepository memberships,
            IdentityProviderPort identityProvider, AuditLog audit) {
        this.appUsers = appUsers;
        this.memberships = memberships;
        this.identityProvider = identityProvider;
        this.audit = audit;
    }

    /** Validates before any write; empty when the change leaves the login alone (no login, same e-mail). */
    public Optional<LoginMove> plan(Person before, Person after, SharedLogin rule) {
        if (after.userId() == null || sameAddress(before.data().email(), after.data().email())) {
            return Optional.empty();
        }
        if (after.data().email() == null) {
            throw new DomainRuleViolation("A member with a login needs an e-mail address", LOGIN_REQUIRES_EMAIL);
        }
        AppUser login = appUsers.findById(after.userId())
                .orElseThrow(() -> new IllegalStateException("Person " + after.id() + " links a missing login"));
        if (rule == SharedLogin.REFUSE && memberships.linkedInAnotherTenant(login.subject())) {
            throw new ConflictException("This login is also used in another academy; only the platform administrator "
                    + "can change its e-mail address", LOGIN_SHARED);
        }
        return Optional.of(new LoginMove(after, login));
    }

    /** The last step of the member transaction: core's login row, the audit event, then Keycloak. */
    public void apply(LoginMove move) {
        Person person = move.person();
        appUsers.save(move.login().withEmail(person.data().email()));
        audit.record(AuditEvent.of("member.login_email_changed", "person", person.id().value(), Map.of()));
        identityProvider.updateLogin(new LoginUpdate(move.login().subject(), person.data().email(),
                person.data().givenName(), person.data().familyName(),
                person.invitationStatus() == InvitationStatus.PENDING));
    }

    private static boolean sameAddress(String before, String after) {
        return Objects.equals(lower(before), lower(after));
    }

    private static String lower(String email) {
        return email == null ? null : email.toLowerCase(Locale.ROOT);
    }
}
