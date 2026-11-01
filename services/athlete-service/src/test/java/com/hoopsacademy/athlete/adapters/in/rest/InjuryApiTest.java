package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static com.hoopsacademy.athlete.support.ApiSupport.unvalidated;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.hasItem;
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
import java.time.LocalDate;
import java.util.HashMap;
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
class InjuryApiTest {

    static final String TENANT = "66000000-0000-4000-8000-000000000001";
    static final String OTHER_TENANT = "66000000-0000-4000-8000-000000000002";
    static final String TEAM = "66000000-0000-4000-8000-0000000000a1";
    static final String OTHER_TEAM = "66000000-0000-4000-8000-0000000000a2";
    static final String CHILD = "66000000-0000-4000-8000-0000000000b1";
    static final String SIBLING = "66000000-0000-4000-8000-0000000000b2";
    static final String STRANGER = "66000000-0000-4000-8000-0000000000b3";
    /** Only the availability tests use this player, so open injuries of other tests do not count. */
    static final String AVAILABLE = "66000000-0000-4000-8000-0000000000b4";
    static final String INJURIES = "/api/athlete/injuries";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, CHILD, SIBLING, AVAILABLE).roster(TENANT, OTHER_TEAM, STRANGER)
                .knownPlayers(TENANT, CHILD, SIBLING, STRANGER, AVAILABLE);
        member(TENANT, TenantRole.ADMIN);
    }

    static Map<String, Object> injury(String player, LocalDate occurred, LocalDate expected) {
        Map<String, Object> body = new HashMap<>();
        body.put("playerId", player);
        body.put("occurredOn", occurred.toString());
        body.put("bodyPart", "left ankle");
        body.put("severity", "MODERATE");
        body.put("description", "twisted in practice");
        if (expected != null) {
            body.put("expectedReturnOn", expected.toString());
        }
        return body;
    }

    private void asCoachOfTeam() {
        member(TENANT, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);
    }

    private void asParentOfChild() {
        member(TENANT, Set.of(TenantRole.PARENT), Set.of(), Set.of(CHILD), null);
    }

    @Test
    void teamStaffReportsReadsUpdatesAndDeletesAnInjury() {
        asCoachOfTeam();
        LocalDate today = LocalDate.now();

        String id = api(TENANT).body(injury(CHILD, today, today.plusDays(14))).post(INJURIES)
                .then().statusCode(201)
                .body("playerId", equalTo(CHILD)).body("status", equalTo("OPEN")).body("bodyPart", equalTo("left ankle"))
                .body("severity", equalTo("MODERATE")).body("actualReturnOn", nullValue())
                .body("recordedBy.personId", notNullValue()).body("recordedAt", notNullValue())
                .extract().path("id");

        api(TENANT).get(INJURIES + "/" + id).then().statusCode(200).body("expectedReturnOn", equalTo(today.plusDays(14).toString()));
        api(TENANT).body(Map.of("severity", "SEVERE", "expectedReturnOn", today.plusDays(30).toString()))
                .patch(INJURIES + "/" + id).then().statusCode(200).body("severity", equalTo("SEVERE"))
                .body("expectedReturnOn", equalTo(today.plusDays(30).toString())).body("bodyPart", equalTo("left ankle"));
        Map<String, Object> recover = new HashMap<>();
        recover.put("status", "RECOVERED");
        recover.put("actualReturnOn", today.plusDays(9).toString());
        api(TENANT).body(recover).patch(INJURIES + "/" + id).then().statusCode(200)
                .body("status", equalTo("RECOVERED")).body("actualReturnOn", equalTo(today.plusDays(9).toString()));
        Map<String, Object> clear = new HashMap<>();
        clear.put("description", null);
        api(TENANT).body(clear).patch(INJURIES + "/" + id).then().statusCode(200).body("description", nullValue());
        api(TENANT).delete(INJURIES + "/" + id).then().statusCode(204);
        api(TENANT).get(INJURIES + "/" + id).then().statusCode(404);
    }

    @Test
    void listFiltersByPlayerTeamAndStatusAndIsScopedToWhatTheCallerMaySee() {
        LocalDate today = LocalDate.now();
        String open = api(TENANT).body(injury(CHILD, today, null)).post(INJURIES).then().statusCode(201).extract().path("id");
        String recovered = api(TENANT).body(injury(SIBLING, today.minusDays(20), null)).post(INJURIES).then().statusCode(201).extract().path("id");
        Map<String, Object> done = new HashMap<>();
        done.put("status", "RECOVERED");
        done.put("actualReturnOn", today.minusDays(5).toString());
        api(TENANT).body(done).patch(INJURIES + "/" + recovered).then().statusCode(200);
        String foreignTeam = api(TENANT).body(injury(STRANGER, today, null)).post(INJURIES).then().statusCode(201).extract().path("id");

        api(TENANT).queryParam("playerId", CHILD).get(INJURIES).then().statusCode(200)
                .body("items.id", hasItem(open)).body("items.playerId", everyItem(equalTo(CHILD)));
        api(TENANT).queryParam("teamId", TEAM).queryParam("status", "RECOVERED").get(INJURIES).then().statusCode(200)
                .body("items.id", hasItem(recovered)).body("items.status", everyItem(equalTo("RECOVERED")));
        api(TENANT).queryParam("teamId", TEAM).get(INJURIES).then().body("items.id", org.hamcrest.Matchers.not(hasItem(foreignTeam)));
        api(TENANT).queryParam("size", 1).get(INJURIES).then().statusCode(200).body("items", hasSize(1)).body("page.size", equalTo(1));

        // team staff only see the players of their teams
        asCoachOfTeam();
        api(TENANT).get(INJURIES).then().statusCode(200).body("items.id", hasItem(open))
                .body("items.id", org.hamcrest.Matchers.not(hasItem(foreignTeam)));
        api(TENANT).get(INJURIES + "/" + foreignTeam).then().statusCode(404);
        api(TENANT).queryParam("playerId", STRANGER).get(INJURIES).then().statusCode(403);
    }

    @Test
    void parentReportsAndUpdatesForALinkedChildButCannotDeleteOrTouchOthers() {
        asParentOfChild();
        LocalDate today = LocalDate.now();

        String id = api(TENANT).body(injury(CHILD, today, today.plusDays(7))).post(INJURIES).then().statusCode(201).extract().path("id");
        api(TENANT).body(Map.of("bodyPart", "right wrist")).patch(INJURIES + "/" + id).then().statusCode(200)
                .body("bodyPart", equalTo("right wrist"));
        api(TENANT).get(INJURIES).then().statusCode(200).body("items.playerId", everyItem(equalTo(CHILD)));
        api(TENANT).delete(INJURIES + "/" + id).then().statusCode(403);
        api(TENANT).body(injury(SIBLING, today, null)).post(INJURIES).then().statusCode(403);

        member(TENANT, TenantRole.ADMIN);
        String foreign = api(TENANT).body(injury(SIBLING, today, null)).post(INJURIES).then().statusCode(201).extract().path("id");
        asParentOfChild();
        api(TENANT).get(INJURIES + "/" + foreign).then().statusCode(404);
        api(TENANT).body(Map.of("bodyPart", "x")).patch(INJURIES + "/" + foreign).then().statusCode(404);
    }

    @Test
    void aPlayerReadsTheirOwnInjuriesOnly() {
        LocalDate today = LocalDate.now();
        String own = api(TENANT).body(injury(CHILD, today, null)).post(INJURIES).then().statusCode(201).extract().path("id");
        String other = api(TENANT).body(injury(SIBLING, today, null)).post(INJURIES).then().statusCode(201).extract().path("id");
        member(TENANT, Set.of(TenantRole.PLAYER), Set.of(), Set.of(), CHILD);

        api(TENANT).get(INJURIES + "/" + own).then().statusCode(200);
        api(TENANT).get(INJURIES + "/" + other).then().statusCode(404);
        api(TENANT).get(INJURIES).then().statusCode(200).body("items.playerId", everyItem(equalTo(CHILD)));
        api(TENANT).body(injury(CHILD, today, null)).post(INJURIES).then().statusCode(403);
        api(TENANT).body(Map.of("bodyPart", "x")).patch(INJURIES + "/" + own).then().statusCode(403);
        api(TENANT).delete(INJURIES + "/" + own).then().statusCode(403);
    }

    @Test
    void invariantsAreReportedAs422WithTheirProblemCode() {
        LocalDate today = LocalDate.now();
        lenient(TENANT).body(injury(CHILD, today, today.minusDays(1))).post(INJURIES).then().statusCode(422)
                .body("code", equalTo("INJURY_RETURN_BEFORE_OCCURRENCE"));
        String id = api(TENANT).body(injury(CHILD, today, null)).post(INJURIES).then().statusCode(201).extract().path("id");
        lenient(TENANT).body(Map.of("status", "RECOVERED")).patch(INJURIES + "/" + id).then().statusCode(422)
                .body("code", equalTo("RECOVERY_DATE_REQUIRED"));
        lenient(TENANT).body(Map.of("expectedReturnOn", today.minusDays(3).toString())).patch(INJURIES + "/" + id)
                .then().statusCode(422).body("code", equalTo("INJURY_RETURN_BEFORE_OCCURRENCE"));
    }

    @Test
    void malformedRequestsAre400AndUnknownThingsAre404() {
        LocalDate today = LocalDate.now();
        Map<String, Object> badSeverity = injury(CHILD, today, null);
        badSeverity.put("severity", "CATASTROPHIC");
        lenient(TENANT).body(badSeverity).post(INJURIES).then().statusCode(400);
        lenient(TENANT).body(Map.of("playerId", CHILD)).post(INJURIES).then().statusCode(400);
        lenient(TENANT).body(Map.of()).patch(INJURIES + "/" + UUID.randomUUID()).then().statusCode(400);
        lenient(TENANT).queryParam("playerId", "nope").get(INJURIES).then().statusCode(400);
        api(TENANT).body(injury(UUID.randomUUID().toString(), today, null)).post(INJURIES).then().statusCode(404);
        api(TENANT).get(INJURIES + "/" + UUID.randomUUID()).then().statusCode(404);
        api(TENANT).delete(INJURIES + "/" + UUID.randomUUID()).then().statusCode(404);
    }

    @Test
    void anotherTenantNeverSeesOrTouchesTheInjury() {
        String id = api(TENANT).body(injury(CHILD, LocalDate.now(), null)).post(INJURIES).then().statusCode(201).extract().path("id");
        core.roster(OTHER_TENANT, TEAM, CHILD).knownPlayers(OTHER_TENANT, CHILD);
        member(OTHER_TENANT, TenantRole.ADMIN);

        api(OTHER_TENANT).get(INJURIES + "/" + id).then().statusCode(404);
        api(OTHER_TENANT).body(Map.of("bodyPart", "x")).patch(INJURIES + "/" + id).then().statusCode(404);
        api(OTHER_TENANT).delete(INJURIES + "/" + id).then().statusCode(404);
        api(OTHER_TENANT).get(INJURIES).then().statusCode(200).body("items.id", org.hamcrest.Matchers.not(hasItem(id)));
    }

    // ------------------------------------------------------------------ availability
    @Test
    void availabilityFollowsOpenInjuriesAndShowsTheExpectedReturn() {
        LocalDate today = LocalDate.now();
        String path = "/api/athlete/players/" + AVAILABLE + "/availability";
        unvalidated(TENANT).get(path).then().statusCode(200).body("available", equalTo(true))
                .body("playerId", equalTo(AVAILABLE)).body("expectedReturnOn", nullValue());

        String id = api(TENANT).body(injury(AVAILABLE, today.minusDays(2), today.plusDays(10))).post(INJURIES)
                .then().statusCode(201).extract().path("id");
        unvalidated(TENANT).get(path).then().statusCode(200).body("available", equalTo(false))
                .body("expectedReturnOn", equalTo(today.plusDays(10).toString()))
                .body("injuries", hasSize(1));

        Map<String, Object> recover = new HashMap<>();
        recover.put("status", "RECOVERED");
        recover.put("actualReturnOn", today.toString());
        api(TENANT).body(recover).patch(INJURIES + "/" + id).then().statusCode(200);
        unvalidated(TENANT).get(path).then().statusCode(200).body("available", equalTo(true));
    }

    @Test
    void availabilityIsVisibleToStaffParentAndPlayerOfThatPlayerOnly() {
        String path = "/api/athlete/players/" + CHILD + "/availability";
        asCoachOfTeam();
        unvalidated(TENANT).get(path).then().statusCode(200);
        unvalidated(TENANT).get("/api/athlete/players/" + STRANGER + "/availability").then().statusCode(404);
        asParentOfChild();
        unvalidated(TENANT).get(path).then().statusCode(200);
        unvalidated(TENANT).get("/api/athlete/players/" + SIBLING + "/availability").then().statusCode(404);
        member(TENANT, Set.of(TenantRole.PLAYER), Set.of(), Set.of(), CHILD);
        unvalidated(TENANT).get(path).then().statusCode(200);
        member(TENANT, TenantRole.ADMIN);
        unvalidated(TENANT).get("/api/athlete/players/" + UUID.randomUUID() + "/availability").then().statusCode(404);
    }
}
