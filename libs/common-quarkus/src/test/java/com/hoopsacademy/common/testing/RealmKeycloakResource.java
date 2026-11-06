package com.hoopsacademy.common.testing;

import com.fasterxml.jackson.databind.node.ObjectNode;
import dasniko.testcontainers.keycloak.KeycloakContainer;
import io.quarkus.test.common.QuarkusTestResourceLifecycleManager;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Map;
import org.testcontainers.utility.MountableFile;

/**
 * A real Keycloak with the test realm of {@link TestRealm} imported, for tests that validate real bearer tokens
 * (pair with a test profile that sets {@code quarkus.oidc.tenant-enabled=true}). Only bearer validation is pointed at
 * it ({@code quarkus.oidc.auth-server-url}); the service's own outgoing client-credentials client stays as its test
 * configuration has it. Tokens: {@link RealmTokens} with the token endpoint under {@value #TOKEN_URL}.
 */
public class RealmKeycloakResource implements QuarkusTestResourceLifecycleManager {

    /** Config key of the realm's token endpoint. */
    public static final String TOKEN_URL = "test.keycloak.token-url";
    private static final String IMPORT = "realm-keycloak/realm-academy.json";

    private KeycloakContainer keycloak;

    @Override
    public Map<String, String> start() {
        keycloak = start(TestRealm.patched(), IMPORT);
        String realm = keycloak.getAuthServerUrl() + "/realms/" + TestRealm.REALM;
        return Map.of("quarkus.oidc.auth-server-url", realm, TOKEN_URL, realm + "/protocol/openid-connect/token");
    }

    /**
     * Starts a Keycloak with {@code realm} imported, the hoops login theme copied in. The realm is written to the test
     * classpath first, as {@code classpathImport} (a module-unique name).
     */
    public static KeycloakContainer start(ObjectNode realm, String classpathImport) {
        KeycloakContainer container = container(realm, classpathImport);
        ContainerStarts.start(container);   // WP87: survives Docker API connections closed while idle
        return container;
    }

    /**
     * A Keycloak like the compose one, not started: {@code realm} imported from the test classpath (written there as
     * {@code classpathImport}), the hoops login theme and the realm's password blocklist (ADR-0038) copied in, with
     * the blocklist's false-positive rate of compose.
     */
    public static KeycloakContainer container(ObjectNode realm, String classpathImport) {
        TestRealm.write(realm, Path.of("target/test-classes").resolve(classpathImport));
        return new KeycloakContainer(TestRealm.KEYCLOAK_IMAGE)
                .withRealmImportFile("/" + classpathImport)
                .withCopyFileToContainer(MountableFile.forHostPath(TestRealm.locate(TestRealm.THEME)),
                        "/opt/keycloak/themes/hoops")
                .withCopyFileToContainer(MountableFile.forHostPath(TestRealm.locate(TestRealm.PASSWORD_BLOCKLIST)),
                        "/opt/keycloak/data/password-blacklists")
                .withEnv(TestRealm.BLOCKLIST_FALSE_POSITIVE_ENV, TestRealm.BLOCKLIST_FALSE_POSITIVE_RATE)
                // Podman under parallel builds can take longer than the 2-minute default to answer /health/ready
                .withStartupTimeout(Duration.ofMinutes(5));
    }

    @Override
    public void stop() {
        if (keycloak != null) {
            keycloak.stop();
        }
    }
}
