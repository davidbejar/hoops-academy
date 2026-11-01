package com.hoopsacademy.core.application.me;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.core.application.authz.MemberAuthz;
import com.hoopsacademy.core.application.authz.MembershipLookup;
import com.hoopsacademy.core.application.port.AppUserRepository;
import com.hoopsacademy.core.application.port.LogoRepository;
import com.hoopsacademy.core.application.port.MembershipRepository;
import com.hoopsacademy.core.application.port.MembershipRepository.IndexedMembership;
import com.hoopsacademy.core.application.port.PersonRepository;
import com.hoopsacademy.core.application.port.TenantProfileRepository;
import com.hoopsacademy.core.domain.identity.AppUser;
import com.hoopsacademy.core.domain.membership.InvitationStatus;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;
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

    public MeLookup(AppUserRepository appUsers, MembershipRepository memberships, MembershipLookup membershipLookup,
            TenantProfileRepository profiles, LogoRepository logos, PersonRepository persons) {
        this.appUsers = appUsers;
        this.memberships = memberships;
        this.membershipLookup = membershipLookup;
        this.profiles = profiles;
        this.logos = logos;
        this.persons = persons;
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

    /** Cross-tenant index read; must not run inside a tenant-bound transaction. */
    @Transactional(Transactional.TxType.REQUIRES_NEW)
    public List<IndexedMembership> indexedMemberships(String subject) {
        return memberships.ofSubject(subject);
    }

    /** Runs inside {@code TenantScope.runAs(tenant)}: the caller's membership there, if the tenant is ACTIVE. */
    @Transactional
    public Optional<MeView.Membership> membershipInBoundTenant(String subject) {
        Optional<MemberAuthz> authz = membershipLookup.find(subject).filter(MemberAuthz::tenantActive);
        if (authz.isEmpty()) {
            return Optional.empty();
        }
        acceptPendingInvitation(subject);
        TenantProfile profile = profiles.findCurrent().orElseThrow();
        MeView.TenantSummary tenant = new MeView.TenantSummary(profile.id(), profile.slug(), profile.name(),
                profile.status(), profile.defaultLocale(), logos.findEtag().isPresent());
        return Optional.of(new MeView.Membership(tenant, authz.get().context()));
    }

    /** The first successful /me after the setup e-mail marks the invitation accepted. */
    private void acceptPendingInvitation(String subject) {
        persons.findActiveByLogin(subject)
                .filter(person -> person.invitationStatus() == InvitationStatus.PENDING)
                .ifPresent(person -> persons.update(person.acceptInvitation()));
    }
}
