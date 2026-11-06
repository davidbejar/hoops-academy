package com.hoopsacademy.common.testing;

import io.quarkus.test.junit.QuarkusTestProfile;
import java.util.Map;

/**
 * Production bearer-token validation instead of {@code @TestSecurity}: Quarkus OIDC verifies every token against the
 * Keycloak of {@link RealmKeycloakResource} (signature, issuer, expiry and the service's configured audience) and a
 * token without {@code sub} is refused, as in production.
 */
public class RealBearerTokensProfile implements QuarkusTestProfile {

    @Override
    public Map<String, String> getConfigOverrides() {
        return Map.of("quarkus.oidc.tenant-enabled", "true", "hoops.security.require-sub", "true");
    }
}
