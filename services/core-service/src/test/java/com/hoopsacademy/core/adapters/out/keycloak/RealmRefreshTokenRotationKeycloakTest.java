package com.hoopsacademy.core.adapters.out.keycloak;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.common.testing.RealmKeycloakResource;
import com.hoopsacademy.common.testing.RealmTokens;
import com.hoopsacademy.common.testing.TestRealm;
import dasniko.testcontainers.keycloak.KeycloakContainer;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * F-08 / ADR-0034: the realm rotates refresh tokens with reuse detection. Every refresh answers a new refresh token,
 * a refresh token that was already used once is rejected ({@code invalid_grant}), and that reuse ends the client's
 * session, so the newest token dies with it. Real Keycloak with the real realm file (test clients added).
 */
@Tag("keycloak")
class RealmRefreshTokenRotationKeycloakTest {

    private static KeycloakContainer keycloak;
    private static RealmTokens tokens;

    @BeforeAll
    static void realm() {
        keycloak = RealmKeycloakResource.start(TestRealm.patched(), "realm-rotation/realm-academy.json");
        tokens = new RealmTokens(keycloak.getAuthServerUrl() + "/realms/" + TestRealm.REALM
                + "/protocol/openid-connect/token");
    }

    @AfterAll
    static void stop() {
        keycloak.stop();
    }

    @Test
    void everyRefreshAnswersANewRefreshToken() {
        String first = signIn();

        JsonNode refreshed = RealmTokens.json(tokens.refresh(TestRealm.WEB_DIRECT_GRANT, first));
        String second = refreshed.path("refresh_token").asText();

        assertThat(second).isNotBlank().isNotEqualTo(first);
        assertThat(refreshed.path("access_token").asText()).isNotBlank();
    }

    @Test
    void aRefreshTokenThatWasAlreadyUsedIsRejected() {
        String first = signIn();
        assertThat(tokens.refresh(TestRealm.WEB_DIRECT_GRANT, first).statusCode()).isEqualTo(200);

        HttpResponse<String> reused = tokens.refresh(TestRealm.WEB_DIRECT_GRANT, first);

        assertThat(reused.statusCode()).as(reused.body()).isEqualTo(400);
        assertThat(RealmTokens.json(reused).path("error").asText()).isEqualTo("invalid_grant");
    }

    @Test
    void aReuseEndsTheSessionSoTheLatestRefreshTokenStopsWorkingToo() {
        // reuse detection: whoever presents a spent token (a thief, or a second browser tab, which is why the web
        // client serialises refreshes across tabs: SerialRefresh) ends the chain for both parties
        String first = signIn();
        String latest = RealmTokens.json(tokens.refresh(TestRealm.WEB_DIRECT_GRANT, first))
                .path("refresh_token").asText();
        assertThat(tokens.refresh(TestRealm.WEB_DIRECT_GRANT, first).statusCode()).isEqualTo(400);

        HttpResponse<String> afterReuse = tokens.refresh(TestRealm.WEB_DIRECT_GRANT, latest);

        assertThat(afterReuse.statusCode()).as(afterReuse.body()).isEqualTo(400);
        assertThat(RealmTokens.json(afterReuse).path("error").asText()).isEqualTo("invalid_grant");
    }

    private static String signIn() {
        String refresh = tokens.password(TestRealm.WEB_DIRECT_GRANT, TestRealm.USER, TestRealm.USER_PASSWORD)
                .path("refresh_token").asText();
        assertThat(refresh).isNotBlank();
        return refresh;
    }
}
