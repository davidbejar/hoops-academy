package com.hoopsacademy.core.testsupport;

import com.hoopsacademy.common.testing.RealmKeycloakResource;
import com.hoopsacademy.common.testing.RealmTokens;
import com.hoopsacademy.common.testing.TestRealm;
import dasniko.testcontainers.keycloak.KeycloakContainer;

/**
 * One Keycloak with common's test realm for the realm tests that do not start Quarkus (CORET-02): it starts on first
 * use and serves every such class of the test JVM, which stops it on exit (Ryuk is off under Podman). Tests that read
 * its log or its event store must pick their own lines, by user or by a value of their own.
 */
public final class RealmKeycloak {

    private static KeycloakContainer keycloak;

    private RealmKeycloak() {}

    public static synchronized KeycloakContainer container() {
        if (keycloak == null) {
            KeycloakContainer started = RealmKeycloakResource.start(TestRealm.patched(), "realm-tests/realm-academy.json");
            Runtime.getRuntime().addShutdownHook(new Thread(started::stop, "realm-keycloak-stop"));
            keycloak = started;
        }
        return keycloak;
    }

    /** The realm's URL, e.g. {@code http://localhost:32768/realms/academy}. */
    public static String realmUrl() {
        return container().getAuthServerUrl() + "/realms/" + TestRealm.REALM;
    }

    public static RealmTokens tokens() {
        return new RealmTokens(realmUrl() + "/protocol/openid-connect/token");
    }
}
