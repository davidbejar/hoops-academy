package com.hoopsacademy.core.testsupport;

import com.hoopsacademy.common.testing.ContainerStarts;
import com.hoopsacademy.common.testing.RealmKeycloakResource;
import com.hoopsacademy.common.testing.TestRealm;
import dasniko.testcontainers.keycloak.KeycloakContainer;
import io.quarkus.test.common.QuarkusTestResourceLifecycleManager;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.Network;
import java.util.HashMap;
import java.util.Map;

/**
 * Real Keycloak (same image as infra/compose) with the test realm of common's {@link TestRealm} imported: the real
 * {@code infra/keycloak/realm-academy.json} with a known client secret for every service client, plus the test-only
 * clients {@value #DIRECT_GRANT_CLIENT} (a copy of {@code web} with direct access grants, so tests can try a password
 * without a browser and get the web client's audiences) and {@link TestRealm#OTHER_AUDIENCE}. The login theme
 * {@code hoops} and the password blocklist are copied into the container ({@link RealmKeycloakResource#container}), so
 * browser-flow tests see the branded pages and the realm's whole password policy.
 * With the init arg {@code mail=true} a MailHog container joins Keycloak's network under the realm's SMTP host name
 * ({@code mailhog}) and its HTTP API is exposed as {@value #MAILHOG_URL}; without it, Keycloak cannot send e-mail.
 */
public class KeycloakContainerResource implements QuarkusTestResourceLifecycleManager {

    public static final String SECRET = TestRealm.SECRET;
    public static final String DIRECT_GRANT_CLIENT = TestRealm.WEB_DIRECT_GRANT;
    /** Config key of the realm's token endpoint (direct grants with {@value #DIRECT_GRANT_CLIENT}). */
    public static final String TOKEN_URL = "test.keycloak.token-url";
    public static final String MAILHOG_URL = "test.mailhog.url";
    private static final String IMPORT = "keycloak-it/realm-academy.json";
    private static final String MAILHOG_IMAGE = "docker.io/mailhog/mailhog:latest";
    private static final int MAILHOG_API = 8025;

    private boolean withMail;
    private Network network;
    private GenericContainer<?> mailhog;
    private KeycloakContainer keycloak;

    @Override
    public void init(Map<String, String> initArgs) {
        withMail = Boolean.parseBoolean(initArgs.getOrDefault("mail", "false"));
    }

    @Override
    public Map<String, String> start() {
        keycloak = RealmKeycloakResource.container(TestRealm.patched(), IMPORT);
        Map<String, String> config = new HashMap<>();
        if (withMail) {
            network = Network.newNetwork();
            mailhog = new GenericContainer<>(MAILHOG_IMAGE).withNetwork(network).withNetworkAliases("mailhog")
                    .withExposedPorts(MAILHOG_API);
            ContainerStarts.start(mailhog);   // WP87: survives Docker API connections closed while idle
            keycloak.withNetwork(network);
            config.put(MAILHOG_URL, "http://" + mailhog.getHost() + ":" + mailhog.getMappedPort(MAILHOG_API));
        }
        ContainerStarts.start(keycloak);
        String server = keycloak.getAuthServerUrl();
        config.putAll(Map.of(
                "quarkus.keycloak.admin-client.server-url", server,
                "quarkus.keycloak.admin-client.client-secret", SECRET,
                "quarkus.oidc-client.auth-server-url", server + "/realms/academy",
                // bearer validation; only active with quarkus.oidc.tenant-enabled=true (RealLoginProfile)
                "quarkus.oidc.auth-server-url", server + "/realms/academy",
                "quarkus.oidc-client.credentials.secret", SECRET,
                TOKEN_URL, server + "/realms/academy/protocol/openid-connect/token"));
        return config;
    }

    @Override
    public void stop() {
        if (keycloak != null) {
            keycloak.stop();
        }
        if (mailhog != null) {
            mailhog.stop();
        }
        if (network != null) {
            network.close();
        }
    }
}
