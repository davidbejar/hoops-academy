package com.hoopsacademy.core.application.platform;

import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.tenant.TenantSlug;
import java.time.ZoneId;

/** Onboarding request: tenant master data plus the first ADMIN. */
public record CreateTenantCommand(
        TenantSlug slug,
        String name,
        ZoneId timezone,
        AppLocale defaultLocale,
        FirstAdmin firstAdmin) {

    public record FirstAdmin(String email, String givenName, String familyName, AppLocale locale) {}
}
