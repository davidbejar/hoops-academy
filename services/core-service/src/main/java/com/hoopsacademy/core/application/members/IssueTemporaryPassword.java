package com.hoopsacademy.core.application.members;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.core.application.members.LoginEmailSync.SharedLogin;
import com.hoopsacademy.core.application.port.AppUserRepository;
import com.hoopsacademy.core.application.port.IdentityProviderPort;
import com.hoopsacademy.core.application.port.MembershipRepository;
import com.hoopsacademy.core.application.shared.WithTemporaryPassword;
import com.hoopsacademy.core.domain.identity.AppUser;
import com.hoopsacademy.core.domain.identity.TemporaryPassword;
import com.hoopsacademy.core.domain.membership.InvitationStatus;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Optional;

/**
 * Issues a new temporary password for a member whose invitation is still PENDING (ADR-0024) — also repairs a pending
 * login that never got a password. Refused (409 {@value #INVITATION_NOT_PENDING}) for a member without a login, an
 * inactive member, an ACCEPTED invitation, and a login whose owner has already chosen a password (e.g. signed in
 * through another academy): resetting it would lock the person out and hand their account to the caller. Academy
 * admins may not reset a login also used in another academy (409 {@code LOGIN_SHARED}, as ADR-0023 for e-mail moves);
 * the platform super admin may. Keycloak is the last step of the transaction.
 */
@ApplicationScoped
public class IssueTemporaryPassword {

    public static final String INVITATION_NOT_PENDING = "INVITATION_NOT_PENDING";

    private final MemberQueries queries;
    private final AppUserRepository appUsers;
    private final MembershipRepository memberships;
    private final IdentityProviderPort identityProvider;
    private final TemporaryPasswords temporaryPasswords;

    public IssueTemporaryPassword(MemberQueries queries, AppUserRepository appUsers, MembershipRepository memberships,
            IdentityProviderPort identityProvider, TemporaryPasswords temporaryPasswords) {
        this.queries = queries;
        this.appUsers = appUsers;
        this.memberships = memberships;
        this.identityProvider = identityProvider;
        this.temporaryPasswords = temporaryPasswords;
    }

    /** An academy ADMIN's request: a login shared with another tenant is refused. */
    @Transactional
    public WithTemporaryPassword<MemberView> handle(PersonId id) {
        return handle(id, SharedLogin.REFUSE);
    }

    @Transactional
    public WithTemporaryPassword<MemberView> handle(PersonId id, SharedLogin sharedLogin) {
        Person person = queries.load(id);
        if (!person.active() || person.userId() == null || person.invitationStatus() != InvitationStatus.PENDING) {
            throw notPending();
        }
        AppUser login = appUsers.findById(person.userId())
                .orElseThrow(() -> new IllegalStateException("Person " + id + " links a missing login"));
        if (sharedLogin == SharedLogin.REFUSE && memberships.linkedInAnotherTenant(login.subject())) {
            throw new ConflictException("This login is also used in another academy; only the platform administrator "
                    + "can issue a new password for it", LoginEmailSync.LOGIN_SHARED);
        }
        if (identityProvider.hasOwnPassword(login.subject())) {
            throw notPending();
        }
        TemporaryPassword password = temporaryPasswords.issue(person.id(), login.subject());
        return new WithTemporaryPassword<>(queries.view(person), Optional.of(password));
    }

    private static ConflictException notPending() {
        return new ConflictException("Only a pending invitation whose person has not chosen a password yet can get a "
                + "new temporary password", INVITATION_NOT_PENDING);
    }
}
