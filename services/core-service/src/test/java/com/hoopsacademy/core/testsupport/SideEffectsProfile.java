package com.hoopsacademy.core.testsupport;

import io.quarkus.test.junit.QuarkusTestProfile;
import java.util.Map;

/**
 * The two side effects the default test configuration switches off. Both are read when their beans are created, so
 * they need a configuration of their own; one profile for both keeps it to one extra Quarkus start (CORET-01):
 * <ul>
 *   <li>temporary-password sweeps start on their events ({@code TemporaryPasswordSweepTriggerTest});</li>
 *   <li>mail goes through a real SMTP client to a port nobody listens on ({@code AcademyRequestMailFailureTest}).</li>
 * </ul>
 * Neither class meets the side effect of the other: the sweep tests send no academy-request mail, and the mail test
 * issues no temporary password.
 */
public class SideEffectsProfile implements QuarkusTestProfile {

    @Override
    public Map<String, String> getConfigOverrides() {
        return Map.of(
                "hoops.temporary-password.sweep-on-events", "true",
                "quarkus.mailer.mock", "false",
                "quarkus.mailer.host", "127.0.0.1",
                "quarkus.mailer.port", "1");
    }
}
