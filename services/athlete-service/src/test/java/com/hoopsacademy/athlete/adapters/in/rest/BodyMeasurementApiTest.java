package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

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
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
@TestSecurity(user = "tenant-user")
@OidcSecurity(claims = @Claim(key = "sub", value = "tenant-user"))
class BodyMeasurementApiTest {

    static final String TENANT = "67000000-0000-4000-8000-000000000001";
    static final String OTHER_TENANT = "67000000-0000-4000-8000-000000000002";
    static final String TEAM = "67000000-0000-4000-8000-0000000000a1";
    static final String CHILD = "67000000-0000-4000-8000-0000000000b1";
    static final String SIBLING = "67000000-0000-4000-8000-0000000000b2";
    static final String M = "/api/athlete/body-measurements";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, CHILD).knownPlayers(TENANT, CHILD, SIBLING);
        member(TENANT, TenantRole.ADMIN);
    }

    static Map<String, Object> measurement(String player, String on, Double height, Double weight) {
        Map<String, Object> body = new HashMap<>();
        body.put("playerId", player);
        body.put("measuredOn", on);
        if (height != null) {
            body.put("heightCm", height);
        }
        if (weight != null) {
            body.put("weightKg", weight);
        }
        return body;
    }

    @Test
    void recordCorrectAndDeleteAMeasurement() {
        String id = api(TENANT).body(measurement(CHILD, "2027-01-10", 150.5, 41.25)).post(M).then().statusCode(201)
                .body("playerId", equalTo(CHILD)).body("measuredOn", equalTo("2027-01-10"))
                .body("heightCm", equalTo(150.5f)).body("weightKg", equalTo(41.25f))
                .body("recordedBy.displayName", notNullValue()).body("recordedAt", notNullValue()).extract().path("id");

        api(TENANT).body(Map.of("heightCm", 151.0)).patch(M + "/" + id).then().statusCode(200)
                .body("heightCm", equalTo(151.0f)).body("weightKg", equalTo(41.25f));
        Map<String, Object> nullWeight = new HashMap<>();
        nullWeight.put("weightKg", null);
        api(TENANT).body(nullWeight).patch(M + "/" + id).then().statusCode(200).body("weightKg", equalTo(41.25f));
        api(TENANT).body(Map.of("clear", List.of("weightKg"))).patch(M + "/" + id).then().statusCode(200)
                .body("weightKg", nullValue()).body("heightCm", equalTo(151.0f));
        lenient(TENANT).body(Map.of("clear", List.of("heightCm"))).patch(M + "/" + id).then().statusCode(422);
        lenient(TENANT).body(Map.of("heightCm", 152.0, "clear", List.of("heightCm"))).patch(M + "/" + id)
                .then().statusCode(400).body("violations[0].code", equalTo("CLEAR_CONFLICT"));
        api(TENANT).delete(M + "/" + id).then().statusCode(204);
        api(TENANT).delete(M + "/" + id).then().statusCode(404);
    }

    @Test
    void heightOrWeightAloneIsEnoughButNeitherIsNot() {
        api(TENANT).body(measurement(CHILD, "2027-02-01", 140.0, null)).post(M).then().statusCode(201).body("weightKg", nullValue());
        api(TENANT).body(measurement(CHILD, "2027-02-02", null, 40.0)).post(M).then().statusCode(201).body("heightCm", nullValue());
        lenient(TENANT).body(measurement(CHILD, "2027-02-03", null, null)).post(M).then().statusCode(422)
                .body("code", equalTo("MEASUREMENT_EMPTY"));
        lenient(TENANT).body(measurement(CHILD, "2027-02-04", 20.0, null)).post(M).then().statusCode(400);
    }

    @Test
    void onlyOneMeasurementPerPlayerAndDay() {
        String first = api(TENANT).body(measurement(CHILD, "2027-03-01", 150.0, null)).post(M).then().statusCode(201).extract().path("id");
        lenient(TENANT).body(measurement(CHILD, "2027-03-01", 151.0, null)).post(M).then().statusCode(409)
                .body("code", equalTo("MEASUREMENT_EXISTS_FOR_DATE"));
        api(TENANT).body(measurement(SIBLING, "2027-03-01", 151.0, null)).post(M).then().statusCode(201);
        String second = api(TENANT).body(measurement(CHILD, "2027-03-02", 150.5, null)).post(M).then().statusCode(201).extract().path("id");

        lenient(TENANT).body(Map.of("measuredOn", "2027-03-01")).patch(M + "/" + second).then().statusCode(409)
                .body("code", equalTo("MEASUREMENT_EXISTS_FOR_DATE"));
        // moving a measurement onto its own date is not a conflict
        api(TENANT).body(Map.of("measuredOn", "2027-03-01", "heightCm", 150.2)).patch(M + "/" + first).then().statusCode(200);
    }

    @Test
    void historyIsOrderedByDateAndFilteredByRange() {
        for (String day : new String[] {"2027-05-20", "2027-05-01", "2027-05-10"}) {
            api(TENANT).body(measurement(CHILD, day, 150.0, 40.0)).post(M).then().statusCode(201);
        }

        api(TENANT).queryParam("playerId", CHILD).queryParam("from", "2027-05-01").queryParam("to", "2027-05-31")
                .get(M).then().statusCode(200).body("measuredOn", org.hamcrest.Matchers.contains("2027-05-01", "2027-05-10", "2027-05-20"));
        api(TENANT).queryParam("playerId", CHILD).queryParam("from", "2027-05-05").queryParam("to", "2027-05-15")
                .get(M).then().statusCode(200).body("$", hasSize(1));
        lenient(TENANT).get(M).then().statusCode(400);
    }

    @Test
    void parentWritesForALinkedChildAndPlayerReadsSelf() {
        member(TENANT, Set.of(TenantRole.PARENT), Set.of(), Set.of(CHILD), null);

        String id = api(TENANT).body(measurement(CHILD, "2027-06-01", 152.0, 42.0)).post(M).then().statusCode(201).extract().path("id");
        api(TENANT).body(Map.of("weightKg", 42.5)).patch(M + "/" + id).then().statusCode(200);
        api(TENANT).queryParam("playerId", CHILD).queryParam("from", "2027-06-01").queryParam("to", "2027-06-30")
                .get(M).then().statusCode(200).body("$", hasSize(1));
        api(TENANT).body(measurement(SIBLING, "2027-06-01", 152.0, 42.0)).post(M).then().statusCode(403);
        api(TENANT).queryParam("playerId", SIBLING).get(M).then().statusCode(403);
        api(TENANT).delete(M + "/" + id).then().statusCode(204);

        member(TENANT, TenantRole.ADMIN);
        String own = api(TENANT).body(measurement(CHILD, "2027-06-02", 152.0, 42.0)).post(M).then().statusCode(201).extract().path("id");
        String other = api(TENANT).body(measurement(SIBLING, "2027-06-02", 152.0, 42.0)).post(M).then().statusCode(201).extract().path("id");
        member(TENANT, Set.of(TenantRole.PLAYER), Set.of(), Set.of(), CHILD);
        api(TENANT).queryParam("playerId", CHILD).queryParam("from", "2027-06-01").queryParam("to", "2027-06-30")
                .get(M).then().statusCode(200).body("$", hasSize(1));
        api(TENANT).body(measurement(CHILD, "2027-06-03", 152.0, 42.0)).post(M).then().statusCode(403);
        api(TENANT).body(Map.of("weightKg", 50.0)).patch(M + "/" + own).then().statusCode(403);
        api(TENANT).body(Map.of("weightKg", 50.0)).patch(M + "/" + other).then().statusCode(404);
        api(TENANT).delete(M + "/" + own).then().statusCode(403);
    }

    @Test
    void anotherTenantCannotSeeOrChangeAMeasurement() {
        String id = api(TENANT).body(measurement(CHILD, "2027-07-01", 150.0, 40.0)).post(M).then().statusCode(201).extract().path("id");
        core.roster(OTHER_TENANT, TEAM, CHILD).knownPlayers(OTHER_TENANT, CHILD);
        member(OTHER_TENANT, TenantRole.ADMIN);

        api(OTHER_TENANT).body(Map.of("weightKg", 99.0)).patch(M + "/" + id).then().statusCode(404);
        api(OTHER_TENANT).delete(M + "/" + id).then().statusCode(404);
        api(OTHER_TENANT).queryParam("playerId", CHILD).get(M).then().statusCode(200).body("$", hasSize(0));
        // the same player and day in another tenant is a different measurement
        api(OTHER_TENANT).body(measurement(CHILD, "2027-07-01", 150.0, 40.0)).post(M).then().statusCode(201);
    }

    @Test
    void unknownPlayerAndMalformedBodiesAreRejected() {
        api(TENANT).body(measurement(UUID.randomUUID().toString(), "2027-08-01", 150.0, null)).post(M).then().statusCode(404);
        lenient(TENANT).body(Map.of("playerId", CHILD)).post(M).then().statusCode(400);
        lenient(TENANT).body(Map.of()).patch(M + "/" + UUID.randomUUID()).then().statusCode(400);
        lenient(TENANT).body(Map.of("heightCm", "tall")).patch(M + "/" + UUID.randomUUID()).then().statusCode(400);
        api(TENANT).body(Map.of("heightCm", 151.0)).patch(M + "/" + UUID.randomUUID()).then().statusCode(404);
    }
}
