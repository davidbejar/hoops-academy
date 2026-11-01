package com.hoopsacademy.core.testsupport;

import io.quarkus.test.junit.QuarkusTestProfile;
import java.util.Map;

/** Uses core's real database-backed AuthzContextResolver instead of the test-jar's registry-backed one. */
public class RealResolverProfile implements QuarkusTestProfile {

    @Override
    public Map<String, String> getConfigOverrides() {
        return Map.of(
                "quarkus.arc.exclude-types", "com.hoopsacademy.common.testing.TestAuthzContextResolver",
                // rows are arranged with plain SQL in these tests, which the in-process invalidation cannot see
                "hoops.authz.cache-ttl", "PT0S");
    }
}
