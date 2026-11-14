package com.hoopsacademy.core.application.me;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.core.application.authz.MemberAuthz;
import com.hoopsacademy.core.application.authz.MembershipLookup;
import com.hoopsacademy.core.application.port.AppUserRepository;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.LogoRepository;
import com.hoopsacademy.core.application.port.MembershipRepository;
import com.hoopsacademy.core.application.port.MembershipRepository.IndexedMembership;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.TemporaryPasswordLogins;
import com.hoopsacademy.core.application.port.TemporaryPasswordSweeps;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.application.shared.ChangedFields;
import com.hoopsacademy.core.domain.identity.AppUser;
import com.hoopsacademy.core.domain.membership.InvitationStatus;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonalDataChanges;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/** Transactional building blocks of GET/PATCH /me (each call is its own transaction). */
@ApplicationScoped
public class MeLookup {

    private final AppUserRepository appUsers;
    private final MembershipRepository memberships;
    private final MembershipLookup membershipLookup;
    private final TenantProfileRepository profiles;
    private final LogoRepository logos;
    private final PersonRepository persons;
    private final TemporaryPasswordLogins temporaryPasswords;
    private final TemporaryPasswordSweeps sweeps;
    private final AuditLog audit;

    public MeLookup(AppUserRepository appUsers, MembershipRepository memberships, MembershipLookup membershipLookup,
            TenantProfileRepository profiles, LogoRepository logos, PersonRepository persons,
            TemporaryPasswordLogins temporaryPasswords, TemporaryPasswordSweeps sweeps, AuditLog audit) {
        this.appUsers = appUsers;
        this.memberships = memberships;
        this.membershipLookup = membershipLookup;
        this.profiles = profiles;
        this.logos = logos;
        this.persons = persons;
        this.temporaryPasswords = temporaryPasswords;
        this.sweeps = sweeps;
        this.audit = audit;
    }

    /** The caller's login; super admins are registered on first sight, anybody else must have been provisioned. */
    @Transactional
    public AppUser loginOf(Caller caller) {
        Optional<AppUser> user = appUsers.findBySubject(caller.subject());
        if (user.isPresent()) {
            return user.get();
        }
        if (caller.superAdmin()) {
            return appUsers.findOrRegister(caller.subject(), caller.email());
        }
        throw new NotFoundException("User is not provisioned");
    }

    @Transactional
    public AppUser changeLocale(Caller caller, AppLocale locale) {
        AppUser changed = loginOf(caller).withLocale(locale);
        appUsers.save(changed);
        return changed;
    }

    /**
     * Runs inside {@code TenantScope.runAs(tenant)}: the caller's own active person in that ACTIVE academy gets the new
     * name, with what an administrator's edit of the person writes (decision 73): the change, the {@code core.person}
     * event (through the repository) and {@code member.updated} with the changed field names, the person as actor. An
     * unchanged name writes nothing.
     */
    @Transactional
    public void renameOwnPerson(String subject, PersonalDataChanges changes) {
        membershipLookup.find(subject).filter(MemberAuthz::tenantActive)
                .orElseThrow(() -> new NotFoundException("Membership not found"));
        Person current = persons.findActiveByLogin(subject)
                .orElseThrow(() -> new NotFoundException("Membership not found"));
        Person changed = current.withData(changes);
        ChangedFields fields = ChangedFields.of(current.data(), changed.data());
        if (fields.isEmpty()) {
            return;
        }
        persons.update(changed);
        audit.recordAs(current.id(), AuditEvent.of(AuditAction.MEMBER_UPDATED, current.id().value(),
                Map.of("fields", fields.names())));
    }

    /** Cross-tenant index read; must not run inside a tenant-bound transaction. */
    @Transactional(Transactional.TxType.REQUIRES_NEW)
    public List<IndexedMembership> indexedMemberships(String subject) {
        return memberships.ofSubject(subject);
    }

    /**
     * Runs inside {@code TenantScope.runAs(tenant)}: the caller's membership there, if the tenant is ACTIVE, with the
     * own person's name as this academy stores it (decision 84).
     */
    @Transactional
    public Optional<MeView.Membership> membershipInBoundTenant(String subject) {
        Optional<MemberAuthz> authz = membershipLookup.find(subject).filter(MemberAuthz::tenantActive);
        if (authz.isEmpty()) {
            return Optional.empty();
        }
        Person person = persons.findActiveByLogin(subject).orElseThrow();
        acceptPendingInvitation(subject, person);
        TenantProfile profile = profiles.findCurrent().orElseThrow();
        MeView.TenantSummary tenant = new MeView.TenantSummary(profile.id(), profile.slug(), profile.name(),
                profile.status(), profile.defaultLocale(), logos.findEtag().isPresent());
        MeView.OwnName name = new MeView.OwnName(person.data().givenName(), person.data().familyName());
        return Optional.of(new MeView.Membership(tenant, authz.get().context(), name));
    }

    /**
     * The first successful /me in this tenant (after the first sign-in) marks the invitation accepted and records
     * {@code member.invitation_accepted} with the person as actor (WP34). Signing in
     * means the temporary password has been replaced (Keycloak issues no token before), so nothing is left to expire;
     * the acceptance also starts a background sweep of the others (ADR-0028).
     */
    private void acceptPendingInvitation(String subject, Person person) {
        if (person.invitationStatus() != InvitationStatus.PENDING) {
            return;
        }
        persons.update(person.acceptInvitation());
        audit.recordAs(person.id(), AuditEvent.of(AuditAction.MEMBER_INVITATION_ACCEPTED, person.id().value()));
        temporaryPasswords.used(subject);
        sweeps.request();
    }
}
