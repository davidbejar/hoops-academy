package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;

import com.hoopsacademy.athlete.adapters.out.client.CoreRosterAdapter;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.TenantRole;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import jakarta.inject.Inject;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * The SAST/DAST findings of the 2026-11 review on athlete's endpoints: SD-01 ({@code page * size} wrapped around
 * int: a negative offset was a 500, a wrapped one another page) and SD-02 (a NUL in text reached PostgreSQL: 500).
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
@TestSecurity(user = "tenant-user")
@OidcSecurity(claims = @Claim(key = "sub", value = "tenant-user"))
class UnsafeInputApiTest {

    static final String TENANT = "84000000-0000-4000-8000-000000000001";
    static final String TEAM = "84000000-0000-4000-8000-0000000000a1";
    static final String CHILD = "84000000-0000-4000-8000-0000000000b1";

    @Inject CoreRosterAdapter rosterAdapter;

    @BeforeEach
    void setUp() {
        new CoreStubs().reset().roster(TENANT, TEAM, CHILD).knownPlayers(TENANT, CHILD);
        rosterAdapter.clearCache();
        member(TENANT, TenantRole.ADMIN);
    }

    /** Every athlete list that pages in SQL. */
    @ParameterizedTest
    @ValueSource(strings = {"/api/athlete/planned-absences?teamId=" + TEAM, "/api/athlete/plan-assignments?teamId=" + TEAM,
        "/api/athlete/training-plans?template=true", "/api/athlete/physical-test-results?teamId=" + TEAM,
        "/api/athlete/plan-completions?playerId=" + CHILD, "/api/athlete/injuries?teamId=" + TEAM,
        "/api/athlete/training-sessions?teamId=" + TEAM})
    void aPageBeyondTheLastRowIsEmptyEvenWhereItsOffsetOverflowsAnInt(String list) {
        api(TENANT).get(list + "&page=" + Integer.MAX_VALUE).then().statusCode(200).body("items", hasSize(0));
        api(TENANT).get(list + "&page=" + (1 << 30) + "&size=4").then().statusCode(200).body("items", hasSize(0));
    }

    @Test
    void aWrappedOffsetNoLongerReturnsTheFirstPage() {
        LocalDate today = LocalDate.now();
        api(TENANT).body(java.util.Map.of("playerId", CHILD, "occurredOn", today.toString(), "bodyPart", "knee",
                "severity", "MINOR")).post("/api/athlete/injuries").then().statusCode(201);

        api(TENANT).get("/api/athlete/injuries?playerId=" + CHILD + "&page=" + (1 << 30) + "&size=4").then()
                .statusCode(200).body("items", hasSize(0));
    }

    @Test
    void aNulCharacterInTheSearchOrABodyIsABadRequestProblem() {
        lenient(TENANT).urlEncodingEnabled(false).get("/api/athlete/training-plans?q=%00").then()
                .statusCode(400).body("code", equalTo("INVALID_CHARACTERS"));
        lenient(TENANT).body("{\"description\":\"knee\\u0000\"}").patch("/api/athlete/injuries/" + UUID.randomUUID())
                .then().statusCode(400).contentType("application/problem+json")
                .body("violations[0].field", equalTo("description"))
                .body("violations[0].code", equalTo("INVALID_CHARACTERS"));
    }
}
