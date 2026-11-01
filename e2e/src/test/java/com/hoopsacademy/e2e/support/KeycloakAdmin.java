package com.hoopsacademy.e2e.support;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.nio.charset.StandardCharsets;
import java.util.Map;

/**
 * Test-only shortcut around the "set your password" e-mail link (a browser interaction): sets a permanent password for
 * a user of realm {@code academy} through the Keycloak Admin API, authenticated as the master-realm admin
 * ({@code KEYCLOAK_ADMIN} / {@code KEYCLOAK_ADMIN_PASSWORD}, admin-cli). It also clears required actions so the
 * scripted PKCE login of {@link KeycloakUserTokens} reaches the code redirect.
 */
public final class KeycloakAdmin {
    private static final String REALM = "academy";
    /** Admin API base. On kind the ingress only exposes realm `academy`: port-forward Keycloak and set E2E_KEYCLOAK_ADMIN_URL. */
    private final String kc = System.getenv("E2E_KEYCLOAK_ADMIN_URL") != null && !System.getenv("E2E_KEYCLOAK_ADMIN_URL").isBlank()
            ? System.getenv("E2E_KEYCLOAK_ADMIN_URL").replaceAll("/+$", "")
            : E2eEnv.baseUrl() + "/auth";
    private final HttpClient http = Http.client(null);

    private String adminToken() {
        var r = Http.postForm(http, kc + "/realms/master/protocol/openid-connect/token", Map.of(
                "grant_type", "password", "client_id", "admin-cli",
                "username", E2eEnv.required("KEYCLOAK_ADMIN"), "password", E2eEnv.required("KEYCLOAK_ADMIN_PASSWORD")));
        return Http.json(r, 200).get("access_token").asText();
    }

    /** Waits (the user is created synchronously by the API call, so normally no wait) and returns the user id. */
    public String userIdByEmail(String token, String email) {
        var r = Http.send(http, HttpRequest.newBuilder(URI.create(kc + "/admin/realms/" + REALM + "/users?exact=true&email="
                + URLEncoder.encode(email, StandardCharsets.UTF_8))).header("Authorization", "Bearer " + token).GET().build());
        JsonNode users = Http.json(r, 200);
        if (users.size() != 1) {
            throw new IllegalStateException("expected exactly one Keycloak user for the invited e-mail, found " + users.size());
        }
        return users.get(0).get("id").asText();
    }

    public void setPassword(String email, String password) {
        String token = adminToken();
        String id = userIdByEmail(token, email);
        String base = kc + "/admin/realms/" + REALM + "/users/" + id;
        var cred = Http.send(http, HttpRequest.newBuilder(URI.create(base + "/reset-password"))
                .header("Authorization", "Bearer " + token).header("Content-Type", "application/json")
                .PUT(HttpRequest.BodyPublishers.ofString(
                        "{\"type\":\"password\",\"temporary\":false,\"value\":" + Http.JSON.valueToTree(password) + "}")).build());
        if (cred.statusCode() != 204) {
            throw new IllegalStateException("reset-password -> " + cred.statusCode());
        }
        var get = Http.send(http, HttpRequest.newBuilder(URI.create(base)).header("Authorization", "Bearer " + token).GET().build());
        ObjectNode user = (ObjectNode) Http.json(get, 200);
        user.put("emailVerified", true).put("enabled", true).putArray("requiredActions");
        var put = Http.send(http, HttpRequest.newBuilder(URI.create(base))
                .header("Authorization", "Bearer " + token).header("Content-Type", "application/json")
                .PUT(HttpRequest.BodyPublishers.ofString(user.toString())).build());
        if (put.statusCode() != 204) {
            throw new IllegalStateException("update user -> " + put.statusCode());
        }
    }

    /**
     * OPT-IN environment fix-up (only with {@code E2E_FIX_REALM=1}) for a realm defect found by this suite
     * (docs/wp/WP18-e2e.md, bug 1): client {@code web} lacks the built-in {@code basic} client scope, so its access
     * tokens carry no {@code sub} claim; the services then fall back to {@code preferred_username}, which never matches
     * the Keycloak user id stored in the membership index, and every real user gets 404 "User is not provisioned".
     * This adds the scope as a default scope of {@code web} in the RUNNING realm (the proper fix is in
     * {@code infra/keycloak/realm-academy.json}). Returns true when it changed something.
     */
    public boolean ensureWebClientHasBasicScope() {
        String token = adminToken();
        String auth = "Bearer " + token;
        JsonNode clients = Http.json(Http.send(http, HttpRequest.newBuilder(URI.create(
                kc + "/admin/realms/" + REALM + "/clients?clientId=web")).header("Authorization", auth).GET().build()), 200);
        String clientId = clients.get(0).get("id").asText();
        JsonNode scopes = Http.json(Http.send(http, HttpRequest.newBuilder(URI.create(
                kc + "/admin/realms/" + REALM + "/client-scopes")).header("Authorization", auth).GET().build()), 200);
        String basicId = null;
        for (JsonNode s : scopes) {
            if ("basic".equals(s.get("name").asText())) {
                basicId = s.get("id").asText();
            }
        }
        if (basicId == null) {
            return false;
        }
        JsonNode current = Http.json(Http.send(http, HttpRequest.newBuilder(URI.create(
                kc + "/admin/realms/" + REALM + "/clients/" + clientId + "/default-client-scopes")).header("Authorization", auth).GET().build()), 200);
        for (JsonNode s : current) {
            if ("basic".equals(s.get("name").asText())) {
                return false;
            }
        }
        var put = Http.send(http, HttpRequest.newBuilder(URI.create(
                kc + "/admin/realms/" + REALM + "/clients/" + clientId + "/default-client-scopes/" + basicId))
                .header("Authorization", auth).PUT(HttpRequest.BodyPublishers.noBody()).build());
        if (put.statusCode() != 204) {
            throw new IllegalStateException("adding scope basic to client web -> " + put.statusCode());
        }
        return true;
    }
}
