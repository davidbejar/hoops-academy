package com.hoopsacademy.core.testsupport;

import com.hoopsacademy.common.testing.RealBearerTokensProfile;
import java.util.HashMap;
import java.util.Map;

/**
 * Production authentication and tenant resolution: bearer tokens are validated against the Keycloak of
 * {@link KeycloakContainerResource} (instead of {@code @TestSecurity}: common's {@link RealBearerTokensProfile}), and
 * the tenant + roles come from core's real database-backed resolver ({@link RealResolverProfile}). Pair with both
 * container resources.
 */
public class RealLoginProfile extends RealResolverProfile {

    @Override
    public Map<String, String> getConfigOverrides() {
        Map<String, String> overrides = new HashMap<>(super.getConfigOverrides());
        overrides.putAll(new RealBearerTokensProfile().getConfigOverrides());
        return overrides;
    }
}
