package com.hoopsacademy.core.application.me;

import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.port.MembershipRepository.IndexedMembership;
import com.hoopsacademy.core.domain.identity.AppUser;
import com.hoopsacademy.core.domain.shared.AppLocale;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import java.util.Optional;

/**
 * GET/PATCH /api/core/me: the caller's login plus, for every tenant listed for their subject in the membership
 * index, the membership read inside that tenant's own RLS scope (one short transaction per tenant — users belong
 * to a handful of academies). Memberships of SUSPENDED/WITHDRAWN tenants and deactivated persons are omitted.
 */
@ApplicationScoped
public class GetMe {

    private final MeLookup lookup;
    private final TenantScope tenantScope;

    public GetMe(MeLookup lookup, TenantScope tenantScope) {
        this.lookup = lookup;
        this.tenantScope = tenantScope;
    }

    public MeView handle(Caller caller) {
        return viewOf(caller, lookup.loginOf(caller));
    }

    /**
     * The own name first, inside the named academy's scope (404 when the caller is no active member of an ACTIVE
     * academy there, before anything is stored), then the locale.
     */
    public MeView update(Caller caller, MeChanges changes) {
        changes.ownName().ifPresent(name -> tenantScope.runAs(name.tenant(),
                () -> lookup.renameOwnPerson(caller.subject(), name.changes())));
        AppUser user = changes.locale().map(locale -> lookup.changeLocale(caller, locale))
                .orElseGet(() -> lookup.loginOf(caller));
        return viewOf(caller, user);
    }

    private MeView viewOf(Caller caller, AppUser user) {
        List<MeView.Membership> memberships = lookup.indexedMemberships(caller.subject()).stream()
                .map(indexed -> membershipIn(indexed, caller.subject()))
                .flatMap(Optional::stream)
                .toList();
        AppLocale locale = Optional.ofNullable(user.locale())
                .or(() -> memberships.stream().findFirst().map(m -> m.tenant().defaultLocale()))
                .orElse(AppLocale.ES);
        return new MeView(user, caller, locale, memberships);
    }

    private Optional<MeView.Membership> membershipIn(IndexedMembership indexed, String subject) {
        return tenantScope.runAs(indexed.tenant(), () -> lookup.membershipInBoundTenant(subject));
    }
}
