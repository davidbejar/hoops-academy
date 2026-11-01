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

    public record Membership(TenantSummary tenant, AuthzContext authz) {}

    public MeView {
        memberships = List.copyOf(memberships);
    }
}
