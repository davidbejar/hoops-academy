package com.hoopsacademy.core.domain.tenant;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Require;
import java.time.ZoneId;

/** The academy profile as its members see and its ADMIN edits it. */
public record TenantProfile(
        TenantId id,
        String slug,
        String name,
        ZoneId timezone,
        AppLocale defaultLocale,
        String contactEmail,
        String websiteUrl,
        TenantStatus status) {

    public TenantProfile {
        name = Require.text(name, "name", Tenant.MAX_NAME);
        Require.present(timezone, "timezone");
        Require.present(defaultLocale, "defaultLocale");
    }

    public TenantProfile apply(TenantProfileChanges changes) {
        return new TenantProfile(id, slug, changes.name().applyTo(name), changes.timezone().applyTo(timezone),
                changes.defaultLocale().applyTo(defaultLocale), changes.contactEmail().applyTo(contactEmail),
                changes.websiteUrl().applyTo(websiteUrl), status);
    }
}
