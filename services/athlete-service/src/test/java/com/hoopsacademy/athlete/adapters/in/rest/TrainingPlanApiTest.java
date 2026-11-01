package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class TrainingPlanApiTest {

    static final String TENANT = "60000000-0000-4000-8000-000000000001";
    static final String OTHER_TENANT = "60000000-0000-4000-8000-000000000002";
    static final String TEAM = "60000000-0000-4000-8000-0000000000a1";
    static final String PLANS = "/api/athlete/training-plans";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, "60000000-0000-4000-8000-0000000000b1");
    }

    static Map<String, Object> item(String title, Integer minutes) {
        Map<String, Object> item = new HashMap<>();
        item.put("title", title);
        if (minutes != null) {
            item.put("durationMinutes", minutes);
        }
        return item;
    }

    String createPlan(String name, Map<String, Object> firstItem) {
        return api(TENANT).body(Map.of("name", name, "description", "d", "items", List.of(firstItem))).post(PLANS)
                .then().statusCode(201).extract().path("id");
    }

    /** The ":copy" custom method: the validator only matches the path when the colon is not percent-encoded. */
    static io.restassured.response.Response copy(io.restassured.specification.RequestSpecification spec, String plan,
            Object body) {
        var request = spec.urlEncodingEnabled(false);
        return (body == null ? request : request.body(body)).post(PLANS + "/" + plan + ":copy");
    }

    // ------------------------------------------------------------------ archive / unarchive
    static io.restassured.response.Response lifecycle(io.restassured.specification.RequestSpecification spec, String plan,
            String verb) {
        return spec.urlEncodingEnabled(false).post(PLANS + "/" + plan + ":" + verb);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void anArchivedPlanLeavesTheListAndComesBackWhenUnarchived() {
        String plan = createPlan("Archive me " + UUID.randomUUID(), item("Warm up", 10));

        lifecycle(api(TENANT), plan, "archive").then().statusCode(200).body("id", equalTo(plan)).body("archived", equalTo(true));
        lifecycle(api(TENANT), plan, "archive").then().statusCode(200).body("archived", equalTo(true));
        api(TENANT).queryParam("size", 200).get(PLANS).then().statusCode(200)
                .body("items.id", org.hamcrest.Matchers.not(org.hamcrest.Matchers.hasItem(plan)));
        api(TENANT).get(PLANS + "/" + plan).then().statusCode(200).body("archived", equalTo(true));

        lifecycle(api(TENANT), plan, "unarchive").then().statusCode(200).body("archived", equalTo(false));
        api(TENANT).queryParam("size", 200).get(PLANS).then().body("items.id", org.hamcrest.Matchers.hasItem(plan))
                .body("items.find { it.id == '" + plan + "' }.archived", equalTo(false));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void templatesCannotBeArchivedAndOnlyStaffArchives() {
        String template = api(TENANT).queryParam("template", true).get(PLANS).then().extract().path("items[0].id");
        lifecycle(api(TENANT), template, "archive").then().statusCode(403).body("code", equalTo("PLAN_IS_TEMPLATE"));
        String plan = createPlan("Staff only " + UUID.randomUUID(), item("Warm up", 10));
        lifecycle(api(TENANT), UUID.randomUUID().toString(), "unarchive").then().statusCode(404);

        member(TENANT, java.util.Set.of(TenantRole.PARENT), java.util.Set.of(), java.util.Set.of(), null);
        lifecycle(api(TENANT), plan, "archive").then().statusCode(403);
    }

    // ------------------------------------------------------------------ templates
    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PLAYER, ownPlayer = "60000000-0000-4000-8000-0000000000b1")
    void everyMemberSeesTheSeededTemplatesWithTheirItems() {
        var templates = api(TENANT).queryParam("template", true).queryParam("size", 50).get(PLANS)
                .then().statusCode(200).body("items", hasSize(greaterThanOrEqualTo(10)))
                .body("items.template", org.hamcrest.Matchers.everyItem(equalTo(true)))
                .body("items.itemCount", org.hamcrest.Matchers.everyItem(org.hamcrest.Matchers.allOf(
                        greaterThanOrEqualTo(4), org.hamcrest.Matchers.lessThanOrEqualTo(8))))
                .body("items.totalDurationMinutes", org.hamcrest.Matchers.everyItem(greaterThanOrEqualTo(15)))
                .extract().jsonPath();
        List<String> names = templates.getList("items.name");
        assertThat(names).contains("Warm-up & mobility", "Ball handling basics", "Form shooting", "Free-throw routine",
                "Finishing at the rim", "Defensive footwork", "Conditioning (intervals)", "Passing & decision making",
                "Rebounding & box-out", "Cool-down & stretching");

        String id = templates.getString("items.find { it.name == 'Form shooting' }.id");
        api(TENANT).get(PLANS + "/" + id).then().statusCode(200)
                .body("template", equalTo(true)).body("items", hasSize(greaterThanOrEqualTo(4)))
                .body("items[0].position", equalTo(0)).body("items[0].title", notNullValue())
                .body("items[1].position", equalTo(1));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void templateSearchMatchesNamesCaseInsensitively() {
        api(TENANT).queryParam("template", true).queryParam("q", "SHOOT").get(PLANS).then().statusCode(200)
                .body("items.name", org.hamcrest.Matchers.hasItem("Form shooting"));
        api(TENANT).queryParam("template", true).queryParam("q", "no such plan xyz").get(PLANS).then()
                .body("items", hasSize(0)).body("page.totalElements", equalTo(0));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void templatesAreReadOnly() {
        String template = api(TENANT).queryParam("template", true).queryParam("q", "Cool-down").get(PLANS)
                .then().statusCode(200).extract().path("items[0].id");
        String firstItem = api(TENANT).get(PLANS + "/" + template).then().extract().path("items[0].id");
        List<String> itemIds = api(TENANT).get(PLANS + "/" + template).then().extract().path("items.id");

        lenient(TENANT).body(Map.of("name", "mine")).patch(PLANS + "/" + template).then().statusCode(403)
                .body("code", equalTo("PLAN_IS_TEMPLATE"));
        lenient(TENANT).delete(PLANS + "/" + template).then().statusCode(403).body("code", equalTo("PLAN_IS_TEMPLATE"));
        lenient(TENANT).body(item("x", 5)).post(PLANS + "/" + template + "/items").then().statusCode(403)
                .body("code", equalTo("PLAN_IS_TEMPLATE"));
        lenient(TENANT).body(Map.of("title", "x")).patch(PLANS + "/" + template + "/items/" + firstItem).then().statusCode(403);
        lenient(TENANT).delete(PLANS + "/" + template + "/items/" + firstItem).then().statusCode(403);
        lenient(TENANT).body(Map.of("itemIds", itemIds)).put(PLANS + "/" + template + "/items").then().statusCode(403);

        api(TENANT).get(PLANS + "/" + template).then().body("name", equalTo("Cool-down & stretching"))
                .body("items", hasSize(itemIds.size()));
    }

    // ------------------------------------------------------------------ copy on use
    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void copyingATemplateCreatesAnIndependentTenantPlan() {
        String template = api(TENANT).queryParam("template", true).queryParam("q", "Warm-up").get(PLANS)
                .then().extract().path("items[0].id");
        int templateItems = api(TENANT).get(PLANS + "/" + template).then().extract().path("items.size()");

        String copy = copy(api(TENANT), template, Map.of("name", "U12 warm-up"))
                .then().statusCode(201)
                .body("name", equalTo("U12 warm-up")).body("template", equalTo(false))
                .body("sourceTemplateId", equalTo(template)).body("items", hasSize(templateItems))
                .extract().path("id");

        api(TENANT).body(Map.of("title", "Extra", "durationMinutes", 5)).post(PLANS + "/" + copy + "/items").then().statusCode(201);
        api(TENANT).body(Map.of("name", "Renamed")).patch(PLANS + "/" + copy).then().statusCode(200);

        api(TENANT).get(PLANS + "/" + template).then().body("name", equalTo("Warm-up & mobility"))
                .body("items", hasSize(templateItems));
        api(TENANT).get(PLANS + "/" + copy).then().body("name", equalTo("Renamed")).body("items", hasSize(templateItems + 1));
        api(TENANT).get(PLANS).then().body("items.id", org.hamcrest.Matchers.hasItem(copy))
                .body("items.template", org.hamcrest.Matchers.everyItem(equalTo(false)));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void copyWithoutBodyKeepsTheNameAndCopiesOfOwnPlansWork() {
        String plan = createPlan("Layups", item("Right hand", 10));

        copy(api(TENANT), plan, null).then().statusCode(201)
                .body("name", equalTo("Layups")).body("sourceTemplateId", equalTo(plan));
        copy(api(TENANT), UUID.randomUUID().toString(), null).then().statusCode(404);
    }

    // ------------------------------------------------------------------ tenant plans
    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ASSISTANT_COACH, staffTeams = TEAM)
    void staffCreatesReadsPatchesAndDeletesAPlan() {
        String id = api(TENANT).body(Map.of("name", "Passing", "description", "chest passes",
                        "items", List.of(item("Chest pass", 10), item("Bounce pass", 5))))
                .post(PLANS).then().statusCode(201)
                .body("name", equalTo("Passing")).body("template", equalTo(false)).body("itemCount", equalTo(2))
                .body("totalDurationMinutes", equalTo(15)).body("items[1].position", equalTo(1))
                .body("sourceTemplateId", nullValue()).extract().path("id");

        api(TENANT).get(PLANS + "/" + id).then().statusCode(200).body("items[0].title", equalTo("Chest pass"));
        api(TENANT).body(Map.of("name", "Passing 2")).patch(PLANS + "/" + id).then().statusCode(200)
                .body("name", equalTo("Passing 2")).body("description", equalTo("chest passes"));
        Map<String, Object> clear = new HashMap<>();
        clear.put("description", null);
        api(TENANT).body(clear).patch(PLANS + "/" + id).then().statusCode(200).body("description", nullValue());
        api(TENANT).queryParam("q", "passing 2").get(PLANS).then().body("items", hasSize(1));
        api(TENANT).delete(PLANS + "/" + id).then().statusCode(204);
        api(TENANT).get(PLANS + "/" + id).then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void planValidation() {
        lenient(TENANT).body(Map.of("description", "no name")).post(PLANS).then().statusCode(400);
        lenient(TENANT).body(Map.of("name", "x", "items", List.of(Map.of("title", "t", "durationMinutes", 0)))).post(PLANS)
                .then().statusCode(400);
        lenient(TENANT).body(Map.of()).patch(PLANS + "/" + UUID.randomUUID()).then().statusCode(400);
        lenient(TENANT).queryParam("template", "maybe").get(PLANS).then().statusCode(400);
        lenient(TENANT).get(PLANS + "/" + UUID.randomUUID()).then().statusCode(404);
    }

    // ------------------------------------------------------------------ items
    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void itemsAreAddedPatchedRemovedAndReordered() {
        String plan = createPlan("Drills", item("A", 5));
        String b = api(TENANT).body(Map.of("title", "B", "description", "bb", "durationMinutes", 7, "sets", 3,
                "repetitions", 10, "videoUrl", "https://example.com/v")).post(PLANS + "/" + plan + "/items")
                .then().statusCode(201).body("position", equalTo(1)).body("sets", equalTo(3)).extract().path("id");
        String c = api(TENANT).body(Map.of("title", "C")).post(PLANS + "/" + plan + "/items").then().statusCode(201)
                .body("position", equalTo(2)).extract().path("id");

        api(TENANT).body(Map.of("title", "B2", "durationMinutes", 9)).patch(PLANS + "/" + plan + "/items/" + b)
                .then().statusCode(200).body("title", equalTo("B2")).body("durationMinutes", equalTo(9))
                .body("sets", equalTo(3));
        Map<String, Object> clear = new HashMap<>();
        clear.put("sets", null);
        clear.put("videoUrl", null);
        api(TENANT).body(clear).patch(PLANS + "/" + plan + "/items/" + b).then().statusCode(200)
                .body("sets", nullValue()).body("videoUrl", nullValue()).body("title", equalTo("B2"));

        String a = api(TENANT).get(PLANS + "/" + plan).then().extract().path("items[0].id");
        api(TENANT).body(Map.of("itemIds", List.of(c, a, b))).put(PLANS + "/" + plan + "/items").then().statusCode(200)
                .body("title", org.hamcrest.Matchers.contains("C", "A", "B2")).body("position", org.hamcrest.Matchers.contains(0, 1, 2));
        lenient(TENANT).body(Map.of("itemIds", List.of(c, a))).put(PLANS + "/" + plan + "/items").then().statusCode(422)
                .body("code", equalTo("ITEM_ORDER_MISMATCH"));

        api(TENANT).delete(PLANS + "/" + plan + "/items/" + a).then().statusCode(204);
        api(TENANT).get(PLANS + "/" + plan).then().body("items.title", org.hamcrest.Matchers.contains("C", "B2"))
                .body("items.position", org.hamcrest.Matchers.contains(0, 1));
        api(TENANT).delete(PLANS + "/" + plan + "/items/" + a).then().statusCode(404);
        api(TENANT).body(Map.of("title", "x")).patch(PLANS + "/" + plan + "/items/" + UUID.randomUUID()).then().statusCode(404);
        lenient(TENANT).body(Map.of("title", " ")).patch(PLANS + "/" + plan + "/items/" + b).then().statusCode(400);
    }

    // ------------------------------------------------------------------ isolation
    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void aTenantNeverSeesAnotherTenantsPlans() {
        String mine = createPlan("Private plan", item("x", 5));
        member(OTHER_TENANT, TenantRole.ADMIN);

        lenient(OTHER_TENANT).get(PLANS + "/" + mine).then().statusCode(404);
        lenient(OTHER_TENANT).body(Map.of("name", "stolen")).patch(PLANS + "/" + mine).then().statusCode(404);
        lenient(OTHER_TENANT).delete(PLANS + "/" + mine).then().statusCode(404);
        copy(lenient(OTHER_TENANT), mine, null).then().statusCode(404);
        lenient(OTHER_TENANT).body(item("y", 5)).post(PLANS + "/" + mine + "/items").then().statusCode(404);
        api(OTHER_TENANT).get(PLANS).then().body("items.name", org.hamcrest.Matchers.not(org.hamcrest.Matchers.hasItem("Private plan")));
        api(OTHER_TENANT).queryParam("template", true).queryParam("size", 50).get(PLANS).then()
                .body("items", hasSize(greaterThanOrEqualTo(10)));
    }
}
