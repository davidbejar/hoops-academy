package com.hoopsacademy.athlete.adapters.in.internal;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RealBearerTokensProfile;
import com.hoopsacademy.common.testing.RealmKeycloakResource;
import com.hoopsacademy.common.testing.RealmTokens;
import com.hoopsacademy.common.testing.TestRealm;
import com.hoopsacademy.athlete.support.CoreMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import java.util.UUID;
import org.eclipse.microprofile.config.ConfigProvider;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * F-14 / ADR-0034: athlete-service accepts only access tokens minted for the audience {@code athlete-service}. Real tokens
 * of the test realm (the real realm file plus test clients): one minted for another audience is a 401 even with the
 * realm role {@code service}, and so is athlete's own service token (it is for core); core's service token and the web
 * client's token are accepted (the web user lacks the role {@code service}, hence 403 on {@code /internal}).
 */
@Tag("keycloak")
@QuarkusTest
@TestProfile(RealBearerTokensProfile.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
@WithTestResource(RealmKeycloakResource.class)
class TokenAudienceKeycloakTest {

    private static final String SELF = "athlete-service";

    private final RealmTokens tokens = new RealmTokens(
            ConfigProvider.getConfig().getValue(RealmKeycloakResource.TOKEN_URL, String.class));
    private final String usage = "/internal/usage/" + UUID.randomUUID();

    @Test
    void aTokenMintedForAnotherAudienceIsUnauthorizedEvenWithTheServiceRole() {
        String token = tokens.clientCredentials(TestRealm.OTHER_AUDIENCE);
        assertThat(RealmTokens.audiences(token)).doesNotContain(SELF).contains(TestRealm.FOREIGN_AUDIENCE);
        assertThat(RealmTokens.realmRoles(token)).contains("service");

        given().auth().oauth2(token).get(usage).then().statusCode(401);
    }

    @Test
    void athletesOwnServiceTokenIsForCoreNotForAthlete() {
        String token = tokens.clientCredentials(SELF);
        assertThat(RealmTokens.audiences(token)).contains("core-service").doesNotContain(SELF);

        given().auth().oauth2(token).get(usage).then().statusCode(401);
    }

    @Test
    void coreReachesTheAthleteInternalApiWithItsServiceToken() {
        String token = tokens.clientCredentials("core-service");
        assertThat(RealmTokens.audiences(token)).contains(SELF);

        given().auth().oauth2(token).get(usage).then().statusCode(200);
    }

    @Test
    void theWebClientsTokenIsAcceptedAndItsMissingServiceRoleDecides() {
        String token = tokens.password(TestRealm.WEB_DIRECT_GRANT, TestRealm.USER, TestRealm.USER_PASSWORD)
                .path("access_token").asText();
        assertThat(RealmTokens.audiences(token)).contains(SELF);

        given().auth().oauth2(token).get(usage).then().statusCode(403);
    }
}
