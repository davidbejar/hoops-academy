package com.hoopsacademy.common.testing;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/** Token-endpoint calls against a test realm ({@link TestRealm}); {@code tokenUrl} is the realm's token endpoint. */
public final class RealmTokens {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final HttpClient HTTP = HttpClient.newHttpClient();

    private final String tokenUrl;

    public RealmTokens(String tokenUrl) {
        this.tokenUrl = tokenUrl;
    }

    /** Access token of a confidential client's service account (secret {@link TestRealm#SECRET}). */
    public String clientCredentials(String clientId) {
        return ok(post(Map.of("grant_type", "client_credentials", "client_id", clientId,
                "client_secret", TestRealm.SECRET))).path("access_token").asText();
    }

    /** Password grant with a public client that allows direct grants; the whole token response. */
    public JsonNode password(String clientId, String username, String password) {
        return ok(post(Map.of("grant_type", "password", "client_id", clientId, "username", username,
                "password", password, "scope", "openid profile email")));
    }

    /** Refresh-token grant of a public client; the raw answer (a rejected refresh is a 400 the caller asserts). */
    public HttpResponse<String> refresh(String clientId, String refreshToken) {
        return post(Map.of("grant_type", "refresh_token", "client_id", clientId, "refresh_token", refreshToken));
    }

    /** The decoded payload of a JWT (no signature check: for asserting claims the realm put in). */
    public static JsonNode claims(String jwt) {
        try {
            return JSON.readTree(Base64.getUrlDecoder().decode(jwt.split("\\.")[1]));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    /** The {@code aud} claim as a list (Keycloak writes a string for one audience, an array for several). */
    public static List<String> audiences(String jwt) {
        return strings(claims(jwt).path("aud"));
    }

    /** The realm roles of a Keycloak access token ({@code realm_access.roles}). */
    public static List<String> realmRoles(String jwt) {
        return strings(claims(jwt).path("realm_access").path("roles"));
    }

    private static List<String> strings(JsonNode node) {
        List<String> out = new ArrayList<>();
        if (node.isArray()) {
            node.forEach(value -> out.add(value.asText()));
        } else if (node.isTextual()) {
            out.add(node.asText());
        }
        return out;
    }

    public static JsonNode json(HttpResponse<String> response) {
        try {
            return JSON.readTree(response.body());
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static JsonNode ok(HttpResponse<String> response) {
        if (response.statusCode() != 200) {
            throw new IllegalStateException("token endpoint -> " + response.statusCode() + ": " + response.body());
        }
        return json(response);
    }

    private HttpResponse<String> post(Map<String, String> form) {
        String body = new LinkedHashMap<>(form).entrySet().stream()
                .map(e -> e.getKey() + "=" + URLEncoder.encode(e.getValue(), StandardCharsets.UTF_8))
                .collect(Collectors.joining("&"));
        try {
            return HTTP.send(HttpRequest.newBuilder(URI.create(tokenUrl))
                    .header("Content-Type", "application/x-www-form-urlencoded")
                    .POST(HttpRequest.BodyPublishers.ofString(body)).build(), HttpResponse.BodyHandlers.ofString());
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
    }
}
