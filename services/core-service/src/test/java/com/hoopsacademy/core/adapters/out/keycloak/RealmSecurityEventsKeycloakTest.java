package com.hoopsacademy.core.adapters.out.keycloak;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.testing.RealmKeycloakResource;
import com.hoopsacademy.common.testing.RealmTokens;
import com.hoopsacademy.common.testing.TestRealm;
import dasniko.testcontainers.keycloak.KeycloakContainer;
import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.UUID;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * ASVS 16.3.1 / ADR-0043: the realm logs every login, failed or not, through the {@code jboss-logging} listener (success
 * events at INFO, errors at WARN) and stores the user events of its list with a 30-day retention; admin events are
 * logged and stored without their representation. Real Keycloak with the real realm file (test clients added).
 */
@Tag("keycloak")
class RealmSecurityEventsKeycloakTest {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final HttpClient HTTP = HttpClient.newHttpClient();

    private static final String ACADEMY_CLIENT = "clientId=\"" + TestRealm.WEB_DIRECT_GRANT + "\"";

    private static KeycloakContainer keycloak;
    private static RealmTokens tokens;

    @BeforeAll
    static void realm() {
        keycloak = RealmKeycloakResource.start(TestRealm.patched(), "realm-events/realm-academy.json");
        tokens = new RealmTokens(realmUrl() + "/protocol/openid-connect/token");
    }

    @AfterAll
    static void stop() {
        keycloak.stop();
    }

    @Test
    void aFailedLoginIsLoggedAndStoredWithoutThePassword() throws Exception {
        String wrong = "Wrong-" + UUID.randomUUID();
        HttpResponse<String> refused = tokens.passwordAttempt(TestRealm.WEB_DIRECT_GRANT, TestRealm.USER, wrong);
        assertThat(refused.statusCode()).as(refused.body()).isBetween(400, 401);
        assertThat(RealmTokens.json(refused).path("error").asText()).isEqualTo("invalid_grant");

        String line = awaitLogLine("type=\"LOGIN_ERROR\"", ACADEMY_CLIENT);
        assertThat(line).contains("WARN", "error=\"invalid_user_credentials\"");
        assertThat(keycloak.getLogs()).doesNotContain(wrong);
        assertThat(admin("/events?type=LOGIN_ERROR")).isNotEmpty();
    }

    @Test
    void aSuccessfulLoginIsLoggedAtInfoAndStored() throws Exception {
        tokens.password(TestRealm.WEB_DIRECT_GRANT, TestRealm.USER, TestRealm.USER_PASSWORD);

        String line = awaitLogLine("type=\"LOGIN\"", ACADEMY_CLIENT);
        assertThat(line).contains("INFO");
        assertThat(keycloak.getLogs()).doesNotContain(TestRealm.USER_PASSWORD);
        assertThat(admin("/events?type=LOGIN")).isNotEmpty();
    }

    @Test
    void theEventStoreKeepsThirtyDaysAndAdminEventsWithoutRepresentation() throws Exception {
        JsonNode config = admin("/events/config");

        assertThat(config.path("eventsEnabled").asBoolean()).isTrue();
        assertThat(config.path("eventsExpiration").asLong()).isEqualTo(Duration.ofDays(30).toSeconds());
        assertThat(config.path("eventsListeners")).extracting(JsonNode::asText).containsExactly("jboss-logging");
        assertThat(config.path("enabledEventTypes")).extracting(JsonNode::asText)
                .contains("LOGIN", "LOGIN_ERROR", "LOGOUT", "UPDATE_PASSWORD", "UPDATE_TOTP", "REMOVE_TOTP",
                        "CODE_TO_TOKEN_ERROR", "REFRESH_TOKEN_ERROR");
        assertThat(config.path("adminEventsEnabled").asBoolean()).isTrue();
        assertThat(config.path("adminEventsDetailsEnabled").asBoolean()).isFalse();
        assertThat(admin("").path("attributes").path("adminEventsExpiration").asText())
                .isEqualTo(Long.toString(Duration.ofDays(30).toSeconds()));
    }

    @Test
    void anAdminChangeIsLoggedAndStoredWithoutItsRepresentation() throws Exception {
        String marker = "Marker" + UUID.randomUUID().toString().substring(0, 8);
        String userId = admin("/users?exact=true&username=" + URLEncoder.encode(TestRealm.USER, StandardCharsets.UTF_8))
                .get(0).path("id").asText();
        HttpResponse<String> update = send(HttpRequest.newBuilder(URI.create(adminUrl() + "/users/" + userId))
                .header("Content-Type", "application/json")
                .PUT(HttpRequest.BodyPublishers.ofString("{\"lastName\":\"" + marker + "\"}")));
        assertThat(update.statusCode()).as(update.body()).isEqualTo(204);

        awaitLogLine("operationType=\"UPDATE\"", "resourceType=\"USER\"", userId);
        assertThat(keycloak.getLogs()).doesNotContain(marker);
        JsonNode stored = admin("/admin-events?operationTypes=UPDATE&resourceTypes=USER");
        assertThat(stored).isNotEmpty();
        assertThat(stored.get(0).path("representation").isMissingNode()).isTrue();
    }

    /** The first Keycloak log line that contains every one of {@code parts} (waits for the asynchronous log). */
    private static String awaitLogLine(String... parts) throws InterruptedException {
        Instant deadline = Instant.now().plusSeconds(10);
        while (Instant.now().isBefore(deadline)) {
            for (String line : keycloak.getLogs().split("\n")) {
                if (Arrays.stream(parts).allMatch(line::contains)) {
                    return line;
                }
            }
            Thread.sleep(200);
        }
        throw new AssertionError("no Keycloak log line contains all of " + Arrays.toString(parts));
    }

    private static JsonNode admin(String path) throws IOException, InterruptedException {
        HttpResponse<String> answer = send(HttpRequest.newBuilder(URI.create(adminUrl() + path)).GET());
        assertThat(answer.statusCode()).as(answer.body()).isEqualTo(200);
        return JSON.readTree(answer.body());
    }

    private static HttpResponse<String> send(HttpRequest.Builder request) throws IOException, InterruptedException {
        return HTTP.send(request.header("Authorization", "Bearer " + adminToken()).build(),
                HttpResponse.BodyHandlers.ofString());
    }

    private static String adminToken() throws IOException, InterruptedException {
        String form = "grant_type=password&client_id=admin-cli&username="
                + URLEncoder.encode(keycloak.getAdminUsername(), StandardCharsets.UTF_8)
                + "&password=" + URLEncoder.encode(keycloak.getAdminPassword(), StandardCharsets.UTF_8);
        HttpResponse<String> answer = HTTP.send(HttpRequest.newBuilder(
                        URI.create(keycloak.getAuthServerUrl() + "/realms/master/protocol/openid-connect/token"))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(form)).build(), HttpResponse.BodyHandlers.ofString());
        return JSON.readTree(answer.body()).path("access_token").asText();
    }

    private static String realmUrl() {
        return keycloak.getAuthServerUrl() + "/realms/" + TestRealm.REALM;
    }

    private static String adminUrl() {
        return keycloak.getAuthServerUrl() + "/admin/realms/" + TestRealm.REALM;
    }
}
