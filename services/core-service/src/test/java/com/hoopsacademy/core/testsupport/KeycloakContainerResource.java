package com.hoopsacademy.core.testsupport;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import dasniko.testcontainers.keycloak.KeycloakContainer;
import io.quarkus.test.common.QuarkusTestResourceLifecycleManager;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.Network;
import org.testcontainers.utility.MountableFile;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Real Keycloak (same image as infra/compose) with {@code infra/keycloak/realm-academy.json} imported. The realm copy
 * gets a known client secret and grants the {@code core-service} service account realm-management
 * {@code manage-users}/{@code view-users}, which the Admin API needs (not yet in the realm export — WP3 handover).
 * The copy also gets a test-only public client {@value #DIRECT_GRANT_CLIENT} with direct access grants, so tests can
 * try a password without a browser (the realm's own clients have direct grants disabled).
 * The login theme {@code hoops} is copied into the container, so browser-flow tests see the branded pages.
 * With the init arg {@code mail=true} a MailHog container joins Keycloak's network under the realm's SMTP host name
 * ({@code mailhog}) and its HTTP API is exposed as {@value #MAILHOG_URL}; without it, Keycloak cannot send e-mail.
 */
public class KeycloakContainerResource implements QuarkusTestResourceLifecycleManager {

    public static final String SECRET = "kc-it-secret";
    public static final String DIRECT_GRANT_CLIENT = "kc-it-direct-grant";
    /** Config key of the realm's token endpoint (direct grants with {@value #DIRECT_GRANT_CLIENT}). */
    public static final String TOKEN_URL = "test.keycloak.token-url";
    private static final String IMAGE = "quay.io/keycloak/keycloak:26.8.1";
    public static final String MAILHOG_URL = "test.mailhog.url";
    private static final String IMPORT = "keycloak-it/realm-academy.json";
    /** The realm's login theme (ADR-0022), copied in so the login pages and their messages are the real ones. */
    private static final String THEME = "infra/keycloak/themes/hoops";
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
        writePatchedRealm();
        keycloak = new KeycloakContainer(IMAGE).withRealmImportFile("/" + IMPORT)
                .withCopyFileToContainer(MountableFile.forHostPath(locate(THEME)), "/opt/keycloak/themes/hoops");
        Map<String, String> config = new HashMap<>();
        if (withMail) {
            network = Network.newNetwork();
            mailhog = new GenericContainer<>(MAILHOG_IMAGE).withNetwork(network).withNetworkAliases("mailhog")
                    .withExposedPorts(MAILHOG_API);
            mailhog.start();
            keycloak.withNetwork(network);
            config.put(MAILHOG_URL, "http://" + mailhog.getHost() + ":" + mailhog.getMappedPort(MAILHOG_API));
        }
        keycloak.start();
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

    private static void writePatchedRealm() {
        try {
            ObjectMapper json = new ObjectMapper();
            String raw = Files.readString(locate("infra/keycloak/realm-academy.json"))
                    .replace("${CORE_SERVICE_CLIENT_SECRET}", SECRET)
                    .replaceAll("\\$\\{[A-Z_]+}", "unused-in-test");
            ObjectNode realm = (ObjectNode) json.readTree(raw);
            realm.withArray("clients").add(json.valueToTree(Map.of("clientId", DIRECT_GRANT_CLIENT,
                    "enabled", true, "publicClient", true, "standardFlowEnabled", false,
                    "directAccessGrantsEnabled", true)));
            realm.withArray("users").forEach(user -> {
                if ("service-account-core-service".equals(user.path("username").asText())) {
                    ((ObjectNode) user).set("clientRoles", json.valueToTree(
                            Map.of("realm-management", List.of("manage-users", "view-users"))));
                }
            });
            Path target = Path.of("target/test-classes").resolve(IMPORT);
            Files.createDirectories(target.getParent());
            json.writeValue(target.toFile(), realm);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static Path locate(String relative) {
        for (Path dir = Path.of("").toAbsolutePath(); dir != null; dir = dir.getParent()) {
            if (Files.exists(dir.resolve(relative))) {
                return dir.resolve(relative);
            }
        }
        throw new IllegalStateException(relative + " not found");
    }
}
