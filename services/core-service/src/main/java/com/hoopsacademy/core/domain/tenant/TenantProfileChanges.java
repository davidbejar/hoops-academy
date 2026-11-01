package com.hoopsacademy.core.domain.tenant;

import com.hoopsacademy.core.domain.shared.AppLocale;
import com.hoopsacademy.core.domain.shared.Patch;
import java.time.ZoneId;

/** A partial update of the academy profile. */
public record TenantProfileChanges(
        Patch<String> name,
        Patch<ZoneId> timezone,
        Patch<AppLocale> defaultLocale,
        Patch<String> contactEmail,
        Patch<String> websiteUrl) {}
