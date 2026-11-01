package com.hoopsacademy.common.problem;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasKey;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.response.ValidatableResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class ProblemExceptionMappersTest {

    private static final String BASE = "/probe/problems/";

    @ParameterizedTest
    @CsvSource({
        "not-found,     404, urn:hoops:problem:not-found,             Not Found,             Widget 42 not found",
        "conflict,      409, urn:hoops:problem:conflict,              Conflict,              Widget was modified concurrently",
        "domain-rule,   422, urn:hoops:problem:domain-rule-violation, Domain Rule Violation, Player is too old for category U12",
        "access-denied, 403, urn:hoops:problem:forbidden,             Forbidden,             Requires one of [ADMIN]"
    })
    void mapsDomainExceptionsToProblemJson(String path, int status, String type, String title, String detail) {
        assertProblem(given().get(BASE + path), status, type)
                .body("title", equalTo(title))
                .body("detail", equalTo(detail))
                .body("instance", equalTo(BASE + path));
    }

    @ParameterizedTest
    @CsvSource({
        "coded-domain-rule, 422, PLAYER_INELIGIBLE",
        "coded-conflict,    409, NOT_PENDING",
        "coded-not-found,   404, TEAM_NOT_FOUND"
    })
    void exposesTheMachineReadableCode(String path, int status, String code) {
        given().get(BASE + path).then().statusCode(status).body("code", equalTo(code));
    }

    @Test
    void domainRuleViolationCarriesItsReasons() {
        given().get(BASE + "coded-domain-rule").then()
                .body("violations[0].field", equalTo("birthDate"))
                .body("violations[0].code", equalTo("MISSING_BIRTH_DATE"))
                .body("violations[0].message", equalTo("Birth date is required"));
    }

    @Test
    void uncodedProblemsOmitTheCode() {
        given().get(BASE + "not-found").then().body("$", not(hasKey("code")));
    }

    @Test
    void invalidParameterIsValidationProblemWithViolations() {
        assertProblem(given().queryParam("size", 0).get(BASE + "validation"), 400, "urn:hoops:problem:validation")
                .body("violations.field", hasItem(containsString("size")))
                .body("violations.message", hasItem(not(nullValue())));
    }

    @Test
    void invalidBodyIsValidationProblem() {
        assertProblem(given().contentType("application/json").body("{\"name\":\" \"}").post(BASE + "validation"),
                        400, "urn:hoops:problem:validation")
                .body("violations.field", hasItem(containsString("name")));
    }

    @Test
    void malformedJsonIsBadRequestProblem() {
        assertProblem(given().contentType("application/json").body("{\"name\":").post(BASE + "validation"),
                400, "about:blank");
    }

    @Test
    void unexpectedExceptionIs500WithoutAnyDetail() {
        assertProblem(given().get(BASE + "unexpected"), 500, "urn:hoops:problem:internal-error")
                .body("detail", nullValue())
                .body(not(containsString("secret-internal-detail")))
                .body(not(containsString("IllegalStateException")))
                .body(not(containsString("at com.")));
    }

    @Test
    void jaxRsHttpErrorsKeepTheirStatus() {
        assertProblem(given().delete(BASE + "conflict"), 405, "about:blank")
                .body("title", equalTo("Method Not Allowed"));
    }

    @Test
    @TestSecurity(user = "someone")
    void securityForbiddenIsProblem() {
        assertProblem(given().get(BASE + "platform-forbidden"), 403, "urn:hoops:problem:forbidden");
    }

    @ParameterizedTest
    @CsvSource({"optimistic-lock", "stale-state", "wrapped-optimistic-lock"})
    void concurrentModificationIsAConflictProblem(String path) {
        assertProblem(given().get(BASE + path), 409, "urn:hoops:problem:conflict")
                .body("code", equalTo("CONCURRENT_MODIFICATION"))
                .body(not(containsString("version")));
    }

    @Test
    void anUnavailableUpstreamIsA503ProblemWithoutInternals() {
        assertProblem(given().get(BASE + "upstream-unavailable"), 503, "urn:hoops:problem:upstream-unavailable")
                .body("code", equalTo("UPSTREAM_UNAVAILABLE"))
                .body(not(containsString("10.0.0.7")));
    }

    @Test
    void anonymousCallOfARoleProtectedResourceIsA401Problem() {
        assertProblem(given().get(BASE + "platform-forbidden"), 401, "urn:hoops:problem:unauthorized")
                .header("WWW-Authenticate", "Bearer");
    }

    private static ValidatableResponse assertProblem(io.restassured.response.Response response, int status, String type) {
        return response.then()
                .statusCode(status)
                .contentType("application/problem+json")
                .body("status", equalTo(status))
                .body("type", equalTo(type));
    }
}
