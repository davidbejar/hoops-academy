package com.hoopsacademy.athlete.adapters.in.messaging;

import io.quarkus.test.junit.QuarkusTestProfile;
import java.util.Map;

/**
 * athlete as it runs with hoops.roster.source=replica: the consumer reads the Dev Services Redpanda, the RosterPort and
 * the tenant filter's membership come from the replica (the test-jar's resolver is removed), and no core-service exists.
 */
public class ReplicaProfile implements QuarkusTestProfile {

    @Override
    public Map<String, String> getConfigOverrides() {
        return Map.of(
                "hoops.roster.source", "replica",
                "hoops.roster.consumer.enabled", "true",
                "quarkus.arc.exclude-types", "com.hoopsacademy.common.testing.TestAuthzContextResolver",
                "hoops.core.url", "http://localhost:1");
    }
}
