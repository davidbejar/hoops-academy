package com.hoopsacademy.common.testing;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * The real realm {@code infra/keycloak/realm-academy.json}, prepared for a Testcontainers Keycloak: every
 * {@code ${..._CLIENT_SECRET}} placeholder becomes {@link #SECRET}, and two test-only clients are added.
 * <ul>
 *   <li>{@value #WEB_DIRECT_GRANT}: a copy of the public client {@code web} (same scopes and protocol mappers, so its
 *       tokens carry the web client's audiences) with direct access grants, so a test can sign in without a browser.
 *   <li>{@value #OTHER_AUDIENCE}: a confidential client whose service account has the realm role {@code service} but
 *       whose tokens are minted for the audience {@value #FOREIGN_AUDIENCE} only. A service that rejects it with 401
 *       rejects it for the audience alone (its role would pass {@code /internal}).
 * </ul>
 * One user without memberships is added: {@value #USER} with password {@link #USER_PASSWORD}.
 */
public final class TestRealm {

    public static final String REALM = "academy";
    /** Keycloak image of {@code infra/compose}. */
    public static final String KEYCLOAK_IMAGE = "quay.io/keycloak/keycloak:26.8.1";
    /** Client secret of every confidential client of the test realm. */
    public static final String SECRET = "kc-it-secret";
    public static final String WEB_DIRECT_GRANT = "kc-it-web";
    public static final String OTHER_AUDIENCE = "kc-it-other-audience";
    public static final String FOREIGN_AUDIENCE = "another-service";
    public static final String USER = "token-it@example.com";
    /** Random per test JVM: nothing secret-looking in git, and the realm is imported fresh by each container. */
    public static final String USER_PASSWORD = "Pw-" + UUID.randomUUID();
    /** The realm's login theme (ADR-0022), copied into the container so the login pages are the real ones. */
    public static final String THEME = "infra/keycloak/themes/hoops";
    /** The directory of the realm's password blocklist (ADR-0038), Keycloak's {@code data/password-blacklists}. */
    public static final String PASSWORD_BLOCKLIST = "infra/keycloak/password-blocklist";
    /** Keycloak's option for the blocklist's Bloom filter, set as in compose and the chart. */
    public static final String BLOCKLIST_FALSE_POSITIVE_ENV =
            "KC_SPI_PASSWORD_POLICY__PASSWORD_BLACKLIST__FALSE_POSITIVE_PROBABILITY";
    public static final String BLOCKLIST_FALSE_POSITIVE_RATE = "1e-12";

    private static final ObjectMapper JSON = new ObjectMapper();

    private TestRealm() {
    }

    /** The realm file with known secrets and the test clients, as a JSON tree a caller may patch further. */
    public static ObjectNode patched() {
        try {
            String raw = Files.readString(locate("infra/keycloak/realm-academy.json"))
                    .replaceAll("\\$\\{[A-Z_]+_CLIENT_SECRET}", SECRET);
            ObjectNode realm = (ObjectNode) JSON.readTree(raw);
            realm.withArray("clients").add(webDirectGrant(realm));
            realm.withArray("clients").add(JSON.valueToTree(Map.of("clientId", OTHER_AUDIENCE, "enabled", true,
                    "publicClient", false, "secret", SECRET, "serviceAccountsEnabled", true,
                    "standardFlowEnabled", false, "directAccessGrantsEnabled", false,
                    "defaultClientScopes", List.of("basic", "roles"),
                    "protocolMappers", List.of(Map.of("name", "audience " + FOREIGN_AUDIENCE,
                            "protocol", "openid-connect", "protocolMapper", "oidc-audience-mapper",
                            "config", Map.of("included.custom.audience", FOREIGN_AUDIENCE,
                                    "access.token.claim", "true", "id.token.claim", "false"))))));
            realm.withArray("users").add(JSON.valueToTree(Map.of("username", "service-account-" + OTHER_AUDIENCE,
                    "enabled", true, "serviceAccountClientId", OTHER_AUDIENCE, "realmRoles", List.of("service"))));
            realm.withArray("users").add(JSON.valueToTree(Map.of("username", USER, "email", USER,
                    "emailVerified", true, "enabled", true, "firstName", "Token", "lastName", "Tester",
                    "credentials", List.of(Map.of("type", "password", "value", USER_PASSWORD, "temporary", false)))));
            return realm;
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    /** Writes {@code realm} to {@code target} (directories created). */
    public static void write(ObjectNode realm, Path target) {
        try {
            Files.createDirectories(target.getParent());
            JSON.writeValue(target.toFile(), realm);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    /** A path relative to the repository root, found from the module directory the tests run in. */
    public static Path locate(String relative) {
        for (Path dir = Path.of("").toAbsolutePath(); dir != null; dir = dir.getParent()) {
            if (Files.exists(dir.resolve(relative))) {
                return dir.resolve(relative);
            }
        }
        throw new IllegalStateException(relative + " not found");
    }

    private static ObjectNode webDirectGrant(ObjectNode realm) {
        for (var client : realm.withArray("clients")) {
            if ("web".equals(client.path("clientId").asText())) {
                ObjectNode copy = client.deepCopy();
                copy.put("clientId", WEB_DIRECT_GRANT).put("name", WEB_DIRECT_GRANT)
                        .put("standardFlowEnabled", false).put("directAccessGrantsEnabled", true);
                copy.putArray("redirectUris");
                copy.putArray("webOrigins");
                copy.remove("attributes");
                return copy;
            }
        }
        throw new IllegalStateException("realm has no client 'web'");
    }
}
