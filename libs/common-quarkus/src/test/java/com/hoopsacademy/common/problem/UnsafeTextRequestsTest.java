package com.hoopsacademy.common.problem;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.response.ValidatableResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * SD-02 of the 2026-11 review: a NUL byte in request text reached PostgreSQL ({@code invalid byte sequence for
 * encoding "UTF8": 0x00}) and came back as a 500. Control characters in the URI and NUL in JSON text are a 400 Problem
 * before any resource runs; text that still reaches the database unstorable is a 400 too, never a 500.
 */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class UnsafeTextRequestsTest {

    private static final String SEARCH = "/probe/text/search";

    @ParameterizedTest
    @ValueSource(strings = {"?q=%00", "?q=a%00b", "?q=%1f", "?q=%7F", "?q=%0A", "?x=1&q=%09", "/a%00b"})
    void aControlCharacterInTheUriIsA400ProblemBeforeTheResource(String suffix) {
        given().urlEncodingEnabled(false).get(SEARCH + suffix).then()
                .statusCode(400)
                .contentType("application/problem+json")
                .header("X-Content-Type-Options", "nosniff")
                .body("type", equalTo("urn:hoops:problem:bad-request"))
                .body("code", equalTo(UnsafeText.CODE))
                .body("detail", equalTo("The request URI contains a control character"));
    }

    @Test
    void anEncodedPercentSignAndNonAsciiTextStillReachTheResource() {
        given().urlEncodingEnabled(false).get(SEARCH + "?q=%2500").then().statusCode(200).body(equalTo("3"));
        given().urlEncodingEnabled(false).get(SEARCH + "?q=caf%C3%A9").then().statusCode(200).body(equalTo("4"));
        given().urlEncodingEnabled(false).get(SEARCH + "/caf%C3%A9").then().statusCode(200).body(equalTo("4"));
    }

    @Test
    void aNulCharacterInAJsonStringIsA400ProblemNamingTheField() {
        echo("{\"name\":\"a\\u0000b\"}")
                .statusCode(400)
                .contentType("application/problem+json")
                .body("type", equalTo("urn:hoops:problem:validation"))
                .body("violations[0].field", equalTo("name"))
                .body("violations[0].code", equalTo(UnsafeText.CODE));
    }

    @Test
    void aNulCharacterInAListOfStringsNamesTheElement() {
        echo("{\"name\":\"ok\",\"tags\":[\"a\",\"b\\u0000\"]}")
                .statusCode(400)
                .body("violations[0].field", equalTo("tags[1]"))
                .body("violations[0].code", equalTo(UnsafeText.CODE));
    }

    @Test
    void otherControlCharactersInJsonTextAreStorableAndAccepted() {
        echo("{\"name\":\"line\\nbreak\\ttab\\u0001\"}").statusCode(200).body(equalTo("line\nbreak\ttab\u0001"));
    }

    @Test
    void unstorableTextThatReachesTheDatabaseAnotherWayIsA400NotA500() {
        given().contentType("application/json").body("{\"note\":\"\\u0000\"}").post("/probe/text/tree").then()
                .statusCode(400)
                .contentType("application/problem+json")
                .body("type", equalTo("urn:hoops:problem:bad-request"))
                .body("code", equalTo(UnsafeText.CODE));
    }

    private static ValidatableResponse echo(String json) {
        return given().contentType("application/json").body(json).post("/probe/text/echo").then();
    }
}
