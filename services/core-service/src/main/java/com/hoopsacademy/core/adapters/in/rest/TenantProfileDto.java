package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.application.tenant.TenantProfileView;
import com.hoopsacademy.core.domain.tenant.TenantProfile;
import java.util.UUID;

/** Contract {@code TenantProfile}. */
public record TenantProfileDto(UUID id, String slug, String name, String timezone, String defaultLocale,
        String contactEmail, String websiteUrl, boolean hasLogo, String logoEtag) {

    static TenantProfileDto of(TenantProfileView view) {
        TenantProfile profile = view.profile();
        return new TenantProfileDto(profile.id().value(), profile.slug(), profile.name(), profile.timezone().getId(),
                profile.defaultLocale().code(), profile.contactEmail(), profile.websiteUrl(), view.hasLogo(),
                view.logoEtag().orElse(null));
    }
}
