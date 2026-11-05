package com.hoopsacademy.core.testsupport;

import io.quarkus.test.junit.QuarkusTestProfile;
import java.util.Map;

/**
 * Production authentication and tenant resolution: bearer tokens are validated against the Keycloak of
 * {@link KeycloakContainerResource} (instead of {@code @TestSecurity}), and the tenant + roles come from core's real
 * database-backed resolver (instead of the test-jar's registry). Pair with both container resources.
 */
public class RealLoginProfile implements QuarkusTestProfile {

    @Override
    public Map<String, String> getConfigOverrides() {
        return Map.of(
                "quarkus.oidc.tenant-enabled", "true",
                "hoops.security.require-sub", "true",
                "quarkus.arc.exclude-types", "com.hoopsacademy.common.testing.TestAuthzContextResolver",
                // rows are arranged with plain SQL, which the in-process invalidation cannot see
                "hoops.authz.cache-ttl", "PT0S");
    }
}
