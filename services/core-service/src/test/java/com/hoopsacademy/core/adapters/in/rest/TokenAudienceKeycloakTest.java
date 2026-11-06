package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RealmTokens;
import com.hoopsacademy.common.testing.TestRealm;
import com.hoopsacademy.core.testsupport.KeycloakContainerResource;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RealLoginProfile;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import java.util.List;
import org.eclipse.microprofile.config.ConfigProvider;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * F-14 / ADR-0034: core accepts only access tokens minted for the audience {@code core-service}. Real tokens of the
 * test realm (the real realm file plus test clients): one minted for another audience is a 401 even with the realm role
 * {@code service}; core's own service token (for game and athlete) is a 401 at core; the callers of core's
 * {@code /internal} (game, athlete) and the web client get through (the web user lacks the role {@code service},
 * hence 403 on {@code /internal}).
 */
@Tag("keycloak")
@QuarkusTest
@TestProfile(RealLoginProfile.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(KeycloakContainerResource.class)
class TokenAudienceKeycloakTest {

    private final RealmTokens tokens = new RealmTokens(
            ConfigProvider.getConfig().getValue(KeycloakContainerResource.TOKEN_URL, String.class));

    @Test
    void aTokenMintedForAnotherAudienceIsUnauthorizedEvenWithTheServiceRole() {
        String token = tokens.clientCredentials(TestRealm.OTHER_AUDIENCE);
        assertThat(RealmTokens.audiences(token)).doesNotContain("core-service").contains(TestRealm.FOREIGN_AUDIENCE);
        assertThat(RealmTokens.realmRoles(token)).contains("service");

        given().auth().oauth2(token).get("/internal/usage/" + Members.newTenant()).then().statusCode(401);
        given().auth().oauth2(token).get("/api/core/me").then().statusCode(401);
    }

    @Test
    void coresOwnServiceTokenIsForGameAndAthleteNotForCore() {
        String token = tokens.clientCredentials("core-service");
        assertThat(RealmTokens.audiences(token)).contains("game-service", "athlete-service")
                .doesNotContain("core-service");

        given().auth().oauth2(token).get("/internal/usage/" + Members.newTenant()).then().statusCode(401);
    }

    @Test
    void gameAndAthleteReachCoresInternalApiWithTheirServiceTokens() {
        for (String caller : List.of("game-service", "athlete-service")) {
            String token = tokens.clientCredentials(caller);
            assertThat(RealmTokens.audiences(token)).as(caller).contains("core-service")
                    .doesNotContain("game-service", "athlete-service");

            given().auth().oauth2(token).get("/internal/usage/" + Members.newTenant()).then().statusCode(200);
        }
    }

    @Test
    void theWebClientsTokenCarriesEveryServiceAudienceAndIsAccepted() {
        String token = tokens.password(TestRealm.WEB_DIRECT_GRANT, TestRealm.USER, TestRealm.USER_PASSWORD)
                .path("access_token").asText();
        assertThat(RealmTokens.audiences(token)).contains("core-service", "game-service", "athlete-service");

        // authenticated, so the missing role `service` decides (an unknown audience would be a 401 first)
        given().auth().oauth2(token).get("/internal/usage/" + Members.newTenant()).then().statusCode(403);
    }
}
