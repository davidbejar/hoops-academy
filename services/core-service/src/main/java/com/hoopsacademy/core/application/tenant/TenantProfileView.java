package com.hoopsacademy.core.application.tenant;

import com.hoopsacademy.core.domain.tenant.TenantProfile;
import java.util.Optional;

/** The profile plus the logo's ETag (empty: no logo). */
public record TenantProfileView(TenantProfile profile, Optional<String> logoEtag) {

    public boolean hasLogo() {
        return logoEtag.isPresent();
    }
}
