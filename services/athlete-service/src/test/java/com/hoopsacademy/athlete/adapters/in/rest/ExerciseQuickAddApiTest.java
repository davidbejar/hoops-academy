package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.adapters.in.rest.ExerciseApiTest.EXERCISES;
import static com.hoopsacademy.athlete.adapters.in.rest.SessionQuickAddApiTest.PLANS;
import static com.hoopsacademy.athlete.adapters.in.rest.SessionQuickAddApiTest.SESSIONS;
import static com.hoopsacademy.athlete.adapters.in.rest.SessionQuickAddApiTest.finishingTemplate;
import static com.hoopsacademy.athlete.adapters.in.rest.SessionQuickAddApiTest.itemId;
import static com.hoopsacademy.athlete.adapters.in.rest.SessionQuickAddApiTest.ref;
import static com.hoopsacademy.athlete.adapters.in.rest.SessionQuickAddApiTest.session;
import static com.hoopsacademy.athlete.adapters.in.rest.SessionQuickAddApiTest.toPlan;
import static com.hoopsacademy.athlete.adapters.in.rest.SessionQuickAddApiTest.toSession;
import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
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
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Adding catalogue exercises (decision 72, ADR-0047): each quick-added item is copied from an exercise or from an item
 * of a readable plan; it gets its own text and keeps the exercise it came from, so neither side changes the other.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class ExerciseQuickAddApiTest {

    static final String TENANT = "92000000-0000-4000-8000-000000000011";
    static final String OTHER_TENANT = "92000000-0000-4000-8000-000000000012";
    static final String TEAM = "92000000-0000-4000-8000-0000000000a1";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, "92000000-0000-4000-8000-0000000000b1");
    }

    static Map<String, Object> exercise(String id) {
        return Map.of("exerciseId", id);
    }

    static String cooper(String tenant) {
        return ExerciseApiTest.cooper(tenant);
    }

    static String plan(String tenant, String... titles) {
        List<Map<String, Object>> items = java.util.Arrays.stream(titles).map(t -> Map.<String, Object>of("title", t)).toList();
        return api(tenant).body(Map.of("name", "Plan " + UUID.randomUUID(), "items", items)).post(PLANS).then()
                .statusCode(201).extract().path("id");
    }

    static String ownExercise(String tenant, String title) {
        return ExerciseApiTest.create(tenant, Map.of("title", title, "durationMinutes", 7, "sets", 3));
    }

    // ------------------------------------------------------------------ to a plan and a session
    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void anExerciseIsCopiedToAPlanInTheCallersLanguageAndKeepsTheReference() {
        String cooper = cooper(TENANT);
        String target = plan(TENANT, "Jog");

        toPlan(api(TENANT).header("Accept-Language", "es"), target, List.of(exercise(cooper))).then().statusCode(200)
                .body("items.title", contains("Jog", "Test de Cooper (12 min)"))
                .body("items[1].exerciseId", equalTo(cooper)).body("items[1].durationMinutes", equalTo(12))
                .body("items[1].description", equalTo("Corre la mayor distancia posible en 12 minutos; anota la distancia en metros."))
                .body("items[0].exerciseId", nullValue());

        api(TENANT).header("Accept-Language", "en").get(PLANS + "/" + target).then()
                .body("items[1].title", equalTo("Test de Cooper (12 min)")).body("items[1].exerciseId", equalTo(cooper));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void anExerciseIsCopiedToASessionsOwnPlan() {
        String session = session(TENANT, TEAM, null);
        String mine = ownExercise(TENANT, "Wall sits " + UUID.randomUUID());

        toSession(api(TENANT), session, List.of(exercise(mine))).then().statusCode(200)
                .body("sessionId", equalTo(session)).body("items.exerciseId", contains(mine))
                .body("items[0].durationMinutes", equalTo(7)).body("items[0].sets", equalTo(3));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void exercisesAndPlanItemsMixInTheGivenOrderAndEachCopyKeepsItsSourcesReference() {
        String cooper = cooper(TENANT);
        String template = finishingTemplate(TENANT);
        String euro = itemId(TENANT, template, "Euro step");
        String euroExercise = api(TENANT).get(PLANS + "/" + template).then()
                .extract().path("items.find { it.id == '" + euro + "' }.exerciseId");
        String handWritten = plan(TENANT, "Free shooting");
        String free = itemId(TENANT, handWritten, "Free shooting");
        String target = plan(TENANT);

        toPlan(api(TENANT), target, List.of(ref(template, euro), exercise(cooper), ref(handWritten, free),
                exercise(cooper))).then().statusCode(200)
                .body("items.title", contains("Euro step", "Cooper test (12 min)", "Free shooting", "Cooper test (12 min)"))
                .body("items.exerciseId", contains(euroExercise, cooper, null, cooper));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void aCopyOfATemplateKeepsEveryItemsReference() {
        String template = finishingTemplate(TENANT);

        TrainingPlanApiTest.copy(api(TENANT), template, null).then().statusCode(201)
                .body("template", equalTo(false)).body("items.exerciseId", everyItem(notNullValue()));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void editingTheItemKeepsTheReferenceAndEditingTheExerciseLeavesTheItemAsItWas() {
        String mine = ownExercise(TENANT, "Box jumps " + UUID.randomUUID());
        String target = plan(TENANT);
        String item = toPlan(api(TENANT), target, List.of(exercise(mine))).then().statusCode(200)
                .extract().path("items[0].id");

        api(TENANT).body(Map.of("title", "Box jumps, low box", "clear", List.of("sets")))
                .patch(PLANS + "/" + target + "/items/" + item).then().statusCode(200)
                .body("exerciseId", equalTo(mine)).body("title", equalTo("Box jumps, low box"));
        api(TENANT).body(Map.of("title", "Box jumps (renamed)", "durationMinutes", 20)).patch(EXERCISES + "/" + mine)
                .then().statusCode(200);

        api(TENANT).get(PLANS + "/" + target).then().body("items[0].title", equalTo("Box jumps, low box"))
                .body("items[0].durationMinutes", equalTo(7)).body("items[0].exerciseId", equalTo(mine));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void anArchivedExerciseCannotBeAddedAndItemsCopiedEarlierKeepIt() {
        String mine = ownExercise(TENANT, "Retired drill " + UUID.randomUUID());
        String target = plan(TENANT);
        toPlan(api(TENANT), target, List.of(exercise(mine))).then().statusCode(200);
        api(TENANT).urlEncodingEnabled(false).post(EXERCISES + "/" + mine + ":archive").then().statusCode(200);

        toPlan(lenient(TENANT), target, List.of(exercise(mine))).then().statusCode(422)
                .body("code", equalTo("EXERCISE_ARCHIVED"));
        String session = session(TENANT, TEAM, null);
        toSession(lenient(TENANT), session, List.of(exercise(mine))).then().statusCode(422)
                .body("code", equalTo("EXERCISE_ARCHIVED"));

        api(TENANT).get(PLANS + "/" + target).then().body("itemCount", equalTo(1))
                .body("items[0].exerciseId", equalTo(mine));
        api(TENANT).get(SESSIONS + "/" + session).then().body("planId", nullValue());
        api(TENANT).get(EXERCISES + "/" + api(TENANT).get(PLANS + "/" + target).then().extract().path("items[0].exerciseId"))
                .then().statusCode(200).body("archived", equalTo(true));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void anotherAcademysOrAnUnknownExerciseIsNotFoundAndNothingIsAdded() {
        String target = plan(TENANT, "Jog");
        member(OTHER_TENANT, Set.of(TenantRole.COACH), Set.of(), Set.of(), null);
        String theirs = ownExercise(OTHER_TENANT, "Their secret " + UUID.randomUUID());
        member(TENANT, Set.of(TenantRole.COACH), Set.of(), Set.of(), null);

        toPlan(lenient(TENANT), target, List.of(exercise(cooper(TENANT)), exercise(theirs))).then().statusCode(404);
        toPlan(lenient(TENANT), target, List.of(exercise(UUID.randomUUID().toString()))).then().statusCode(404);

        api(TENANT).get(PLANS + "/" + target).then().body("items.title", contains("Jog"));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void eachSourceIsEitherAnExerciseOrAPlanItem() {
        String cooper = cooper(TENANT);
        String template = finishingTemplate(TENANT);
        String euro = itemId(TENANT, template, "Euro step");
        String target = plan(TENANT);
        Map<String, Object> all = new HashMap<>(ref(template, euro));
        all.put("exerciseId", cooper);

        for (Map<String, Object> source : List.<Map<String, Object>>of(Map.of(), all, Map.of("planId", template),
                Map.of("itemId", euro), Map.of("exerciseId", cooper, "planId", template),
                Map.of("exerciseId", cooper, "itemId", euro))) {
            toPlan(lenient(TENANT), target, List.of(source)).then().statusCode(400);
        }
        api(TENANT).get(PLANS + "/" + target).then().body("itemCount", equalTo(0));
    }
}
