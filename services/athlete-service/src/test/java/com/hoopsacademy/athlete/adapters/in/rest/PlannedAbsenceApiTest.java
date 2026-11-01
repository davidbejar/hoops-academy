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
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.common.tenancy.TenantRole;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class PlannedAbsenceApiTest {

    static final String TENANT = "54000000-0000-4000-8000-000000000001";
    static final String TEAM = "54000000-0000-4000-8000-0000000000a1";
    static final String CHILD = "54000000-0000-4000-8000-0000000000b1";
    static final String OTHER_CHILD = "54000000-0000-4000-8000-0000000000b2";
    static final String ABSENCES = "/api/athlete/planned-absences";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, CHILD, OTHER_CHILD).knownPlayers(TENANT, CHILD, OTHER_CHILD);
    }

    static Map<String, Object> absence(String player, String from, String to) {
        return Map.of("playerId", player, "fromDate", from, "toDate", to, "reason", "family trip");
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT, linkedPlayers = CHILD)
    void parentManagesAbsencesOfTheirLinkedChild() {
        String id = api(TENANT).body(absence(CHILD, "2027-05-01", "2027-05-03")).post(ABSENCES)
                .then().statusCode(201)
                .body("playerId", equalTo(CHILD)).body("reason", equalTo("family trip"))
                .body("recordedBy.personId", notNullValue()).body("recordedBy.displayName", notNullValue())
                .body("recordedAt", notNullValue())
                .extract().path("id");

        api(TENANT).get(ABSENCES + "/" + id).then().statusCode(200).body("toDate", equalTo("2027-05-03"));
        api(TENANT).body(Map.of("toDate", "2027-05-05")).patch(ABSENCES + "/" + id).then().statusCode(200)
                .body("toDate", equalTo("2027-05-05")).body("fromDate", equalTo("2027-05-01"));
        var clearReason = new java.util.HashMap<String, Object>();
        clearReason.put("reason", null);
        api(TENANT).body(clearReason).patch(ABSENCES + "/" + id).then().statusCode(200).body("reason", nullValue());
        api(TENANT).get(ABSENCES).then().statusCode(200).body("items", hasSize(org.hamcrest.Matchers.greaterThanOrEqualTo(1)));
        api(TENANT).delete(ABSENCES + "/" + id).then().statusCode(204);
        api(TENANT).get(ABSENCES + "/" + id).then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT, linkedPlayers = CHILD)
    void parentCannotTouchAnotherFamilysPlayer() {
        api(TENANT).body(absence(OTHER_CHILD, "2027-05-10", "2027-05-12")).post(ABSENCES).then().statusCode(403);
        api(TENANT).queryParam("playerId", OTHER_CHILD).get(ABSENCES).then().statusCode(403);

        // an absence created by staff for another player is invisible to this parent (404, not 403)
        member(TENANT, TenantRole.ADMIN);
        String foreign = api(TENANT).body(absence(OTHER_CHILD, "2027-05-10", "2027-05-12")).post(ABSENCES)
                .then().statusCode(201).extract().path("id");
        member(TENANT, Set.of(TenantRole.PARENT), Set.of(), Set.of(CHILD), null);
        api(TENANT).get(ABSENCES + "/" + foreign).then().statusCode(404);
        api(TENANT).body(Map.of("toDate", "2027-05-20")).patch(ABSENCES + "/" + foreign).then().statusCode(404);
        api(TENANT).delete(ABSENCES + "/" + foreign).then().statusCode(404);
        api(TENANT).get(ABSENCES).then().statusCode(200).body("items.playerId", org.hamcrest.Matchers.everyItem(equalTo(CHILD)));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PLAYER, ownPlayer = CHILD)
    void playerManagesOnlyTheirOwnAbsences() {
        api(TENANT).body(absence(CHILD, "2027-06-01", "2027-06-02")).post(ABSENCES).then().statusCode(201);
        api(TENANT).body(absence(OTHER_CHILD, "2027-06-01", "2027-06-02")).post(ABSENCES).then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffHandleAbsencesOfAnyPlayerAndFilterByTeamPlayerAndDates() {
        String a = api(TENANT).body(absence(CHILD, "2027-07-01", "2027-07-05")).post(ABSENCES).then().statusCode(201).extract().path("id");
        api(TENANT).body(absence(OTHER_CHILD, "2027-07-20", "2027-07-25")).post(ABSENCES).then().statusCode(201);

        api(TENANT).queryParam("teamId", TEAM).queryParam("from", "2027-07-01").queryParam("to", "2027-07-31")
                .get(ABSENCES).then().statusCode(200).body("items", hasSize(2)).body("page.totalElements", equalTo(2));
        api(TENANT).queryParam("playerId", CHILD).queryParam("from", "2027-07-01").queryParam("to", "2027-07-31")
                .get(ABSENCES).then().body("items", hasSize(1)).body("items[0].id", equalTo(a));
        // overlap semantics: a range ending on the absence's first day still matches, one ending before does not
        api(TENANT).queryParam("playerId", CHILD).queryParam("from", "2027-06-25").queryParam("to", "2027-07-01")
                .get(ABSENCES).then().body("items", hasSize(1));
        api(TENANT).queryParam("playerId", CHILD).queryParam("from", "2027-06-25").queryParam("to", "2027-06-30")
                .get(ABSENCES).then().body("items", hasSize(0));
        api(TENANT).queryParam("playerId", CHILD).queryParam("size", 1).queryParam("page", 0).queryParam("from", "2027-07-01")
                .queryParam("to", "2027-07-31").get(ABSENCES).then().body("page.size", equalTo(1));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void validationErrors() {
        lenient(TENANT).body(absence(CHILD, "2027-08-05", "2027-08-01")).post(ABSENCES).then().statusCode(422)
                .body("code", equalTo("INVALID_DATE_RANGE"));
        lenient(TENANT).body(Map.of("playerId", CHILD)).post(ABSENCES).then().statusCode(400);
        lenient(TENANT).body(Map.of()).patch(ABSENCES + "/" + UUID.randomUUID()).then().statusCode(400);
        // a player core does not know
        String ghost = "54000000-0000-4000-8000-0000000000ff";
        core.knownPlayers(TENANT, CHILD);
        api(TENANT).body(absence(ghost, "2027-08-01", "2027-08-02")).post(ABSENCES).then().statusCode(404);

        String id = api(TENANT).body(absence(CHILD, "2027-08-01", "2027-08-10")).post(ABSENCES).then().statusCode(201).extract().path("id");
        lenient(TENANT).body(Map.of("toDate", "2027-07-01")).patch(ABSENCES + "/" + id).then().statusCode(422);
        lenient(TENANT).body(Map.of("fromDate", "soon")).patch(ABSENCES + "/" + id).then().statusCode(400);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void unknownIdsAre404() {
        api(TENANT).get(ABSENCES + "/" + UUID.randomUUID()).then().statusCode(404);
        api(TENANT).delete(ABSENCES + "/" + UUID.randomUUID()).then().statusCode(404);
    }
}
