package com.hoopsacademy.core.application.me;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.identity.AppUser;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.tenant.TenantStatus;
import java.util.List;

/** The caller with their memberships in ACTIVE tenants. */
public record MeView(AppUser user, Caller caller, AppLocale locale, List<Membership> memberships) {

    public record TenantSummary(TenantId id, String slug, String name, TenantStatus status, AppLocale defaultLocale,
            boolean hasLogo) {}

    /** The caller's person in one academy: what it is, what it may do there, and its name as the academy stores it. */
    public record Membership(TenantSummary tenant, AuthzContext authz, OwnName name) {}

    /** The caller's given and family name in one academy (decision 84); the rest of the person stays out of /me. */
    public record OwnName(String givenName, String familyName) {}

    public MeView {
        memberships = List.copyOf(memberships);
    }
}
