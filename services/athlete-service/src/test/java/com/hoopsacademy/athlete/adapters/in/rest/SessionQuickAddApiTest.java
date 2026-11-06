package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.not;
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
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import jakarta.inject.Inject;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Decision 54 (ADR-0041): items of any readable plan or template are quick-added (copied) to a session or a tenant
 * plan. A session without a plan of its own gets an ad-hoc plan; templates and shared plans are never changed.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class SessionQuickAddApiTest {

    static final String TENANT = "78000000-0000-4000-8000-000000000001";
    static final String OTHER_TENANT = "78000000-0000-4000-8000-000000000002";
    static final String TEAM = "78000000-0000-4000-8000-0000000000a1";
    static final String OTHER_TEAM = "78000000-0000-4000-8000-0000000000a2";
    static final String SESSIONS = "/api/athlete/training-sessions";
    static final String PLANS = "/api/athlete/training-plans";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, "78000000-0000-4000-8000-0000000000b1").roster(TENANT, OTHER_TEAM);
    }

    // ------------------------------------------------------------------ helpers
    static String session(String tenant, String team, Object planId) {
        Map<String, Object> body = new HashMap<>(Map.of("teamId", team, "startsAt", "2027-09-07T15:00:00Z",
                "durationMinutes", 90));
        if (planId != null) {
            body.put("planId", planId);
        }
        return api(tenant).body(body).post(SESSIONS).then().statusCode(201).extract().path("id");
    }

    static String finishingTemplate(String tenant) {
        return api(tenant).queryParam("template", true).queryParam("size", 50).get(PLANS).then().statusCode(200)
                .extract().path("items.find { it.nameKey == 'finishing-at-the-rim' }.id");
    }

    static String itemId(String tenant, String plan, String englishTitle) {
        return api(tenant).header("Accept-Language", "en").get(PLANS + "/" + plan).then().statusCode(200)
                .extract().path("items.find { it.title == '" + englishTitle + "' }.id");
    }

    static Map<String, Object> ref(String plan, String item) {
        return Map.of("planId", plan, "itemId", item);
    }

    static Response toSession(RequestSpecification spec, String session, List<Map<String, Object>> refs) {
        return spec.body(Map.of("items", refs)).post(SESSIONS + "/" + session + "/items");
    }

    static Response toPlan(RequestSpecification spec, String plan, List<Map<String, Object>> refs) {
        return spec.urlEncodingEnabled(false).body(Map.of("items", refs)).post(PLANS + "/" + plan + "/items:copy");
    }

    String tenantPlan(String name, String... titles) {
        List<Map<String, Object>> items = java.util.Arrays.stream(titles).map(t -> Map.<String, Object>of("title", t)).toList();
        return api(TENANT).body(Map.of("name", name, "items", items)).post(PLANS).then().statusCode(201).extract().path("id");
    }

    // ------------------------------------------------------------------ to a session
    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void theFirstQuickAddGivesASessionWithoutPlanItsOwnPlanInTheCallersLanguage() {
        String session = session(TENANT, TEAM, null);
        String template = finishingTemplate(TENANT);
        String euro = itemId(TENANT, template, "Euro step");

        String own = toSession(api(TENANT).header("Accept-Language", "es"), session, List.of(ref(template, euro)))
                .then().statusCode(200).body("sessionId", equalTo(session)).body("template", equalTo(false))
                .body("name", equalTo("Sesión 2027-09-07")).body("items.title", contains("Paso europeo"))
                .body("items[0].id", not(equalTo(euro))).extract().path("id");

        api(TENANT).get(SESSIONS + "/" + session).then().body("planId", equalTo(own));
        api(TENANT).header("Accept-Language", "en").get(PLANS + "/" + own).then().statusCode(200)
                .body("items.title", contains("Paso europeo")).body("sessionId", equalTo(session));
        api(TENANT).queryParam("size", 200).get(PLANS).then().body("items.id", not(hasItem(own)));
        api(TENANT).queryParam("q", "Sesión").get(PLANS).then().body("items.id", not(hasItem(own)));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void laterQuickAddsAppendToTheSamePlanAndAnItemMayComeTwice() {
        String session = session(TENANT, TEAM, null);
        String template = finishingTemplate(TENANT);
        String euro = itemId(TENANT, template, "Euro step");
        String floater = itemId(TENANT, template, "Floater");
        String own = toSession(api(TENANT), session, List.of(ref(template, euro))).then().statusCode(200)
                .extract().path("id");

        toSession(api(TENANT), session, List.of(ref(template, floater), ref(template, euro))).then().statusCode(200)
                .body("id", equalTo(own)).body("items.title", contains("Euro step", "Floater", "Euro step"))
                .body("items.position", contains(0, 1, 2)).body("itemCount", equalTo(3));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void aSessionOnATemplateGetsAnOwnCopyAndTheTemplateStaysAsItWas() {
        String template = finishingTemplate(TENANT);
        String session = session(TENANT, TEAM, template);
        int before = api(TENANT).get(PLANS + "/" + template).then().extract().path("itemCount");
        String extra = tenantPlan("Extras " + UUID.randomUUID(), "Zigzag sprint");
        String zigzag = itemId(TENANT, extra, "Zigzag sprint");

        String own = toSession(api(TENANT).header("Accept-Language", "es"), session, List.of(ref(extra, zigzag)))
                .then().statusCode(200).body("sessionId", equalTo(session)).body("sourceTemplateId", equalTo(template))
                .body("name", equalTo("Finalización junto al aro")).body("itemCount", equalTo(before + 1))
                .body("items[2].title", equalTo("Paso europeo")).body("items[" + before + "].title", equalTo("Zigzag sprint"))
                .extract().path("id");

        api(TENANT).get(SESSIONS + "/" + session).then().body("planId", equalTo(own));
        api(TENANT).get(PLANS + "/" + template).then().body("itemCount", equalTo(before));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void aSessionOnASharedPlanGetsAnOwnCopyAndTheSharedPlanStaysAsItWas() {
        String shared = tenantPlan("Shared " + UUID.randomUUID(), "Jog", "Shots");
        String session = session(TENANT, TEAM, shared);
        String other = session(TENANT, TEAM, shared);
        String shots = itemId(TENANT, shared, "Shots");

        String own = toSession(api(TENANT), session, List.of(ref(shared, shots))).then().statusCode(200)
                .body("items.title", contains("Jog", "Shots", "Shots")).body("sourceTemplateId", equalTo(shared))
                .extract().path("id");

        api(TENANT).get(PLANS + "/" + shared).then().body("items.title", contains("Jog", "Shots"));
        api(TENANT).get(SESSIONS + "/" + other).then().body("planId", equalTo(shared));
        api(TENANT).get(SESSIONS + "/" + session).then().body("planId", equalTo(own));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void movingASessionOffItsOwnPlanDeletesThatPlan() {
        String template = finishingTemplate(TENANT);
        String euro = itemId(TENANT, template, "Euro step");
        String first = session(TENANT, TEAM, null);
        String firstOwn = toSession(api(TENANT), first, List.of(ref(template, euro))).then().extract().path("id");
        String second = session(TENANT, TEAM, null);
        String secondOwn = toSession(api(TENANT), second, List.of(ref(template, euro))).then().extract().path("id");

        api(TENANT).body(Map.of("planId", template)).patch(SESSIONS + "/" + first).then().statusCode(200)
                .body("planId", equalTo(template));
        api(TENANT).body(Map.of("clear", List.of("planId"))).patch(SESSIONS + "/" + second).then().statusCode(200)
                .body("planId", nullValue());

        lenient(TENANT).get(PLANS + "/" + firstOwn).then().statusCode(404);
        lenient(TENANT).get(PLANS + "/" + secondOwn).then().statusCode(404);
        api(TENANT).body(Map.of("notes", "kept")).patch(SESSIONS + "/" + first).then().statusCode(200)
                .body("planId", equalTo(template));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void aSessionPlanStaysWithItsSession() {
        String template = finishingTemplate(TENANT);
        String euro = itemId(TENANT, template, "Euro step");
        String session = session(TENANT, TEAM, null);
        String own = toSession(api(TENANT), session, List.of(ref(template, euro))).then().extract().path("id");
        String other = session(TENANT, TEAM, null);

        lenient(TENANT).body(Map.of("planId", own)).patch(SESSIONS + "/" + other).then().statusCode(422)
                .body("code", equalTo("PLAN_OF_ANOTHER_SESSION"));
        lenient(TENANT).body(Map.of("teamId", TEAM, "startsAt", "2027-09-08T15:00:00Z", "durationMinutes", 60, "planId", own))
                .post(SESSIONS).then().statusCode(422).body("code", equalTo("PLAN_OF_ANOTHER_SESSION"));
        lenient(TENANT).body(Map.of("planId", own, "teamId", TEAM, "dueOn", "2028-01-10"))
                .post("/api/athlete/plan-assignments").then().statusCode(422).body("code", equalTo("PLAN_OF_A_SESSION"));
        api(TENANT).body(Map.of("planId", own)).patch(SESSIONS + "/" + session).then().statusCode(200);
        api(TENANT).get(PLANS + "/" + own).then().statusCode(200);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void unknownSessionsPlansAndItemsAreNotFoundAndNothingIsCreated() {
        String template = finishingTemplate(TENANT);
        String euro = itemId(TENANT, template, "Euro step");
        String session = session(TENANT, TEAM, null);
        String ghost = UUID.randomUUID().toString();

        toSession(lenient(TENANT), ghost, List.of(ref(template, euro))).then().statusCode(404);
        toSession(lenient(TENANT), session, List.of(ref(template, euro), ref(ghost, euro))).then().statusCode(404);
        toSession(lenient(TENANT), session, List.of(ref(template, ghost))).then().statusCode(404);
        String other = tenantPlan("Other " + UUID.randomUUID(), "x");
        toSession(lenient(TENANT), session, List.of(ref(other, euro))).then().statusCode(404); // an item of another plan

        api(TENANT).get(SESSIONS + "/" + session).then().body("planId", nullValue());
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void anotherTenantsPlanOrSessionIsNotFound() {
        String session = session(TENANT, TEAM, null);
        String mine = tenantPlan("Mine " + UUID.randomUUID(), "Secret drill");
        String secret = itemId(TENANT, mine, "Secret drill");
        member(OTHER_TENANT, java.util.Set.of(TenantRole.COACH), java.util.Set.of(TEAM), java.util.Set.of(), null);
        core.roster(OTHER_TENANT, TEAM);
        String theirs = session(OTHER_TENANT, TEAM, null);

        toSession(lenient(OTHER_TENANT), theirs, List.of(ref(mine, secret))).then().statusCode(404);
        toSession(lenient(OTHER_TENANT), session, List.of(ref(finishingTemplate(OTHER_TENANT),
                itemId(OTHER_TENANT, finishingTemplate(OTHER_TENANT), "Floater")))).then().statusCode(404);
        toPlan(lenient(OTHER_TENANT), mine, List.of(ref(mine, secret))).then().statusCode(404);
        lenient(OTHER_TENANT).body(Map.of("planId", mine)).patch(SESSIONS + "/" + theirs).then().statusCode(404);
        lenient(OTHER_TENANT).body(Map.of("teamId", TEAM, "startsAt", "2027-09-08T15:00:00Z", "durationMinutes", 60,
                "planId", mine)).post(SESSIONS).then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void aCancelledSessionTakesNoItemsAndTheRequestIsValidated() {
        String template = finishingTemplate(TENANT);
        String euro = itemId(TENANT, template, "Euro step");
        String session = session(TENANT, TEAM, null);
        api(TENANT).body(Map.of("reason", "rain")).post(SESSIONS + "/" + session + "/cancel").then().statusCode(200);

        toSession(lenient(TENANT), session, List.of(ref(template, euro))).then().statusCode(409)
                .body("code", equalTo("SESSION_CANCELLED"));
        api(TENANT).get(SESSIONS + "/" + session).then().body("planId", nullValue());
        String open = session(TENANT, TEAM, null);
        toSession(lenient(TENANT), open, List.of()).then().statusCode(400);
        lenient(TENANT).body(Map.of()).post(SESSIONS + "/" + open + "/items").then().statusCode(400);
        toSession(lenient(TENANT), open, java.util.Collections.nCopies(51, ref(template, euro))).then().statusCode(400);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffOfAnotherTeamMayNotQuickAdd() {
        String template = finishingTemplate(TENANT);
        String euro = itemId(TENANT, template, "Euro step");
        member(TENANT, java.util.Set.of(TenantRole.ADMIN), java.util.Set.of(), java.util.Set.of(), null);
        String otherTeams = session(TENANT, OTHER_TEAM, null);
        member(TENANT, java.util.Set.of(TenantRole.COACH), java.util.Set.of(TEAM), java.util.Set.of(), null);

        toSession(lenient(TENANT), otherTeams, List.of(ref(template, euro))).then().statusCode(403);
    }

    // ------------------------------------------------------------------ to a plan
    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ASSISTANT_COACH)
    void itemsAreCopiedToATenantPlanButNeverToATemplate() {
        String template = finishingTemplate(TENANT);
        String euro = itemId(TENANT, template, "Euro step");
        String target = tenantPlan("Target " + UUID.randomUUID(), "Jog");

        toPlan(api(TENANT).header("Accept-Language", "id"), target, List.of(ref(template, euro), ref(target,
                itemId(TENANT, target, "Jog")))).then().statusCode(200).body("id", equalTo(target))
                .body("items.title", contains("Jog", "Euro step", "Jog")).body("sessionId", nullValue());

        toPlan(lenient(TENANT), template, List.of(ref(template, euro))).then().statusCode(403)
                .body("code", equalTo("PLAN_IS_TEMPLATE"));
        toPlan(lenient(TENANT), UUID.randomUUID().toString(), List.of(ref(template, euro))).then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT, linkedPlayers = "78000000-0000-4000-8000-0000000000b1")
    void aParentMayNotQuickAdd() {
        String template = finishingTemplate(TENANT);
        String euro = itemId(TENANT, template, "Euro step");

        toPlan(lenient(TENANT), template, List.of(ref(template, euro))).then().statusCode(403);
    }
}
