package com.hoopsacademy.core.testsupport;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import dasniko.testcontainers.keycloak.KeycloakContainer;
import io.quarkus.test.common.QuarkusTestResourceLifecycleManager;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;

/**
 * Real Keycloak (same image as infra/compose) with {@code infra/keycloak/realm-academy.json} imported. The realm copy
 * gets a known client secret and grants the {@code core-service} service account realm-management
 * {@code manage-users}/{@code view-users}, which the Admin API needs (not yet in the realm export — WP3 handover).
 */
public class KeycloakContainerResource implements QuarkusTestResourceLifecycleManager {

    public static final String SECRET = "kc-it-secret";
    private static final String IMAGE = "quay.io/keycloak/keycloak:26.8.1";
    private static final String IMPORT = "keycloak-it/realm-academy.json";

    private KeycloakContainer keycloak;

    @Override
    public Map<String, String> start() {
        writePatchedRealm();
        keycloak = new KeycloakContainer(IMAGE).withRealmImportFile("/" + IMPORT);
        keycloak.start();
        String server = keycloak.getAuthServerUrl();
        return Map.of(
                "quarkus.keycloak.admin-client.server-url", server,
                "quarkus.keycloak.admin-client.client-secret", SECRET,
                "quarkus.oidc-client.auth-server-url", server + "/realms/academy",
                "quarkus.oidc-client.credentials.secret", SECRET);
    }

    @Override
    public void stop() {
        if (keycloak != null) {
            keycloak.stop();
        }
    }

    private static void writePatchedRealm() {
        try {
            ObjectMapper json = new ObjectMapper();
            String raw = Files.readString(locate("infra/keycloak/realm-academy.json"))
                    .replace("${CORE_SERVICE_CLIENT_SECRET}", SECRET)
                    .replaceAll("\\$\\{[A-Z_]+}", "unused-in-test");
            ObjectNode realm = (ObjectNode) json.readTree(raw);
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
