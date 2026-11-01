package com.hoopsacademy.athlete.adapters.out.client;

import io.quarkus.test.junit.QuarkusTestProfile;
import java.util.Map;

/** Removes the test-jar's resolver so the production RosterAuthzResolver (backed by WireMock core) answers. */
public class RealResolverProfile implements QuarkusTestProfile {

    @Override
    public Map<String, String> getConfigOverrides() {
        return Map.of("quarkus.arc.exclude-types", "com.hoopsacademy.common.testing.TestAuthzContextResolver");
    }
}
