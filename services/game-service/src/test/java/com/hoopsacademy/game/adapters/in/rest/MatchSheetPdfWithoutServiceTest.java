package com.hoopsacademy.game.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.support.Contract;
import com.hoopsacademy.game.support.MatchSeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.QuarkusTestProfile;
import io.quarkus.test.junit.TestProfile;
import jakarta.inject.Inject;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Without {@code PDF_SERVICE_URL} game still starts; only the match sheet answers 503 (WP117). */
@QuarkusTest
@TestProfile(MatchSheetPdfWithoutServiceTest.NoPdfService.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
class MatchSheetPdfWithoutServiceTest {

    static final String A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
    static final String TEAM = "11111111-0000-4000-8000-0000000000e3";

    public static class NoPdfService implements QuarkusTestProfile {
        @Override
        public Map<String, String> getConfigOverrides() {
            return Map.of("hoops.pdf.url", "");
        }
    }

    @Inject
    MatchSeed seed;

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void theSheetIs503AndTheBoxScoreStillWorks() {
        UUID match = seed.match(A, TEAM, MatchStatus.FINISHED);

        given().filter(Contract.FILTER).urlEncodingEnabled(false).header("X-Tenant-Id", A)
                .get("/api/game/matches/" + match + "/box-score:pdf")
                .then().statusCode(503).body("code", equalTo("UPSTREAM_UNAVAILABLE"));
        given().filter(Contract.FILTER).header("X-Tenant-Id", A).get("/api/game/matches/" + match + "/box-score")
                .then().statusCode(200);
    }
}
