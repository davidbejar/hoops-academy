package com.hoopsacademy.core.application.members;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.core.application.port.AppUserRepository;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.LoginUpdate;
import com.hoopsacademy.core.application.port.MembershipRepository;
import com.hoopsacademy.core.application.port.MembershipRepository.IndexedMembership;
import com.hoopsacademy.core.application.port.SharedLoginPersons;
import com.hoopsacademy.core.domain.identity.AppUser;
import com.hoopsacademy.core.domain.membership.Person;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

/**
 * Keeps the login of a member on the member's e-mail (ADR-0023): when the e-mail of a person with a login changes,
 * {@code core.app_user.email} and the Keycloak user (username = e-mail) follow, inside the member's transaction with
 * the Keycloak call last, so a Keycloak failure rolls the database back. No e-mail is sent and the password stays as
 * it is (ADR-0024). One person, one e-mail: when the super admin moves a login that active persons of other academies
 * also link, their {@code core.person.email} follows in the same transaction, with one audit event per academy
 * (ADR-0026).
 */
@ApplicationScoped
public class LoginEmailSync {

    public static final String LOGIN_SHARED = "LOGIN_SHARED";
    public static final String LOGIN_REQUIRES_EMAIL = "LOGIN_REQUIRES_EMAIL";
    private static final String LOGIN_EMAIL_CHANGED = "member.login_email_changed";

    /** Who may move a login that is also linked to a person of another tenant. */
    public enum SharedLogin {
        /** Academy admins: refused with 409 {@value #LOGIN_SHARED} (no cross-tenant account takeover). */
        REFUSE,
        /** The platform super admin: always synced, also in every other academy that uses the login. */
        SYNC
    }

    /**
     * A login move validated by {@link #plan} and performed by {@link #apply}; {@code sharedWith} are the active
     * persons of other academies that link the same login (empty unless the super admin moves a shared login).
     */
    public record LoginMove(Person person, AppUser login, List<IndexedMembership> sharedWith) {

        public LoginMove {
            sharedWith = List.copyOf(sharedWith);
        }
    }

    private final AppUserRepository appUsers;
    private final MembershipRepository memberships;
    private final IdentityProviderPort identityProvider;
    private final SharedLoginPersons sharedLoginPersons;
    private final AuditLog audit;

    public LoginEmailSync(AppUserRepository appUsers, MembershipRepository memberships,
            SharedLoginPersons sharedLoginPersons, IdentityProviderPort identityProvider, AuditLog audit) {
        this.appUsers = appUsers;
        this.memberships = memberships;
        this.sharedLoginPersons = sharedLoginPersons;
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
        return Optional.of(new LoginMove(after, login, sharedWith(login, after.data().email(), rule)));
    }

    private List<IndexedMembership> sharedWith(AppUser login, String email, SharedLogin rule) {
        if (rule == SharedLogin.REFUSE) {
            if (memberships.linkedInAnotherTenant(login.subject())) {
                throw new ConflictException("This login is also used in another academy; only the platform "
                        + "administrator can change its e-mail address", LOGIN_SHARED);
            }
            return List.of();
        }
        List<IndexedMembership> others = memberships.inOtherTenants(login.subject());
        if (others.stream().anyMatch(other -> sharedLoginPersons.emailTaken(other, email))) {
            throw new ConflictException("Another member of an academy that also uses this login already has this "
                    + "e-mail address", "EMAIL_TAKEN");
        }
        return others;
    }

    /**
     * The last step of the member transaction: core's login row and audit event, the same person in the other
     * academies that use the login (with their own audit event), then Keycloak.
     */
    public void apply(LoginMove move) {
        Person person = move.person();
        String email = person.data().email();
        appUsers.save(move.login().withEmail(email));
        audit.record(AuditEvent.of(LOGIN_EMAIL_CHANGED, "person", person.id().value(), Map.of()));
        for (IndexedMembership other : move.sharedWith()) {
            sharedLoginPersons.changeEmail(other, move.login().id(), email,
                    AuditEvent.of(LOGIN_EMAIL_CHANGED, "person", other.person().value(), Map.of()));
        }
        identityProvider.updateLogin(new LoginUpdate(move.login().subject(), email,
                person.data().givenName(), person.data().familyName()));
    }

    private static boolean sameAddress(String before, String after) {
        return Objects.equals(lower(before), lower(after));
    }

    private static String lower(String email) {
        return email == null ? null : email.toLowerCase(Locale.ROOT);
    }
}
