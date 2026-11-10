package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.common.tenancy.TenantRole;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.specification.RequestSpecification;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * The exercise catalogue (decision 72, ADR-0047, athlete 3.0.0): the global exercises (every distinct item of the
 * seeded templates plus the Cooper test) in the caller's language, read-only; the academy's own exercises are created,
 * edited and archived; another academy's exercises do not exist.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class ExerciseApiTest {

    static final String TENANT = "92000000-0000-4000-8000-000000000001";
    static final String OTHER_TENANT = "92000000-0000-4000-8000-000000000002";
    static final String EXERCISES = "/api/athlete/exercises";
    static final String PLANS = "/api/athlete/training-plans";
    /** 59 distinct items of the ten seeded templates plus the Cooper test. */
    static final int GLOBAL_EXERCISES = 60;

    static RequestSpecification in(String language) {
        return api(TENANT).header("Accept-Language", language);
    }

    static String create(String tenant, Map<String, Object> body) {
        return api(tenant).body(body).post(EXERCISES).then().statusCode(201).extract().path("id");
    }

    static String cooper(String tenant) {
        return api(tenant).queryParam("q", "cooper").queryParam("scope", "GLOBAL").get(EXERCISES).then().statusCode(200)
                .extract().path("items[0].id");
    }

    static String unique(String title) {
        return title + " " + UUID.randomUUID().toString().substring(0, 8);
    }

    // ------------------------------------------------------------------ the global catalogue
    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PLAYER, ownPlayer = "92000000-0000-4000-8000-0000000000b1")
    void theGlobalCatalogueHoldsEveryTemplateExerciseAndTheCooperTest() {
        api(TENANT).queryParam("scope", "GLOBAL").queryParam("size", 200).get(EXERCISES).then().statusCode(200)
                .body("page.totalElements", equalTo(GLOBAL_EXERCISES)).body("items.global", everyItem(equalTo(true)))
                .body("items.archived", everyItem(equalTo(false))).body("items.nameKey", everyItem(notNullValue()))
                .body("items.title", hasItem("Euro step")).body("items.title", hasItem("Cooper test (12 min)"));

        in("en").queryParam("q", "cooper").get(EXERCISES).then().statusCode(200)
                .body("items.title", contains("Cooper test (12 min)")).body("items[0].nameKey", equalTo("cooper-test"))
                .body("items[0].durationMinutes", equalTo(12))
                .body("items[0].description", equalTo("Run as far as you can in 12 minutes; record the distance in metres."));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT, linkedPlayers = "92000000-0000-4000-8000-0000000000b1")
    void aGlobalExerciseIsShownInTheCallersLanguageAndSearchedThere() {
        String cooper = cooper(TENANT);

        in("es").get(EXERCISES + "/" + cooper).then().statusCode(200).body("title", equalTo("Test de Cooper (12 min)"))
                .body("description", equalTo("Corre la mayor distancia posible en 12 minutos; anota la distancia en metros."));
        in("id").get(EXERCISES + "/" + cooper).then().statusCode(200).body("title", equalTo("Tes Cooper (12 menit)"));
        in("fr").get(EXERCISES + "/" + cooper).then().statusCode(200).body("title", equalTo("Cooper test (12 min)"));

        in("es").queryParam("q", "PASO EUROPEO").get(EXERCISES).then().body("items.title", contains("Paso europeo"));
        in("en").queryParam("q", "paso europeo").get(EXERCISES).then().body("page.totalElements", equalTo(0));
        in("es").queryParam("q", "100%_").get(EXERCISES).then().statusCode(200).body("page.totalElements", equalTo(0));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void everyTemplateItemReferencesItsCatalogueExerciseWithTheSameText() {
        String template = api(TENANT).queryParam("template", true).queryParam("size", 50).get(PLANS).then()
                .extract().path("items.find { it.nameKey == 'finishing-at-the-rim' }.id");

        List<Map<String, Object>> items = in("es").get(PLANS + "/" + template).then().statusCode(200)
                .body("items.exerciseId", everyItem(notNullValue())).extract().path("items");

        for (Map<String, Object> item : items) {
            in("es").get(EXERCISES + "/" + item.get("exerciseId")).then().statusCode(200)
                    .body("title", equalTo(item.get("title"))).body("description", equalTo(item.get("description")))
                    .body("global", equalTo(true));
        }
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void globalExercisesAreReadOnly() {
        String cooper = cooper(TENANT);

        lenient(TENANT).body(Map.of("title", "Mine now")).patch(EXERCISES + "/" + cooper).then().statusCode(403)
                .body("code", equalTo("EXERCISE_IS_GLOBAL"));
        lenient(TENANT).urlEncodingEnabled(false).post(EXERCISES + "/" + cooper + ":archive").then().statusCode(403)
                .body("code", equalTo("EXERCISE_IS_GLOBAL"));
        lenient(TENANT).urlEncodingEnabled(false).post(EXERCISES + "/" + cooper + ":unarchive").then().statusCode(403)
                .body("code", equalTo("EXERCISE_IS_GLOBAL"));
        in("en").get(EXERCISES + "/" + cooper).then().body("title", equalTo("Cooper test (12 min)"));
    }

    // ------------------------------------------------------------------ the academy's own exercises
    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void anAcademyCreatesReadsAndEditsItsOwnExercise() {
        String title = unique("Zig-zag sprints");
        Map<String, Object> body = new HashMap<>(Map.of("title", title, "description", "Cones every 3 m",
                "durationMinutes", 8, "sets", 4, "repetitions", 6, "videoUrl", "https://example.org/zigzag"));

        String id = api(TENANT).body(body).post(EXERCISES).then().statusCode(201).body("title", equalTo(title))
                .body("global", equalTo(false)).body("archived", equalTo(false)).body("nameKey", nullValue())
                .body("sets", equalTo(4)).body("repetitions", equalTo(6)).extract().path("id");

        in("es").get(EXERCISES + "/" + id).then().statusCode(200).body("title", equalTo(title))
                .body("videoUrl", equalTo("https://example.org/zigzag")).body("durationMinutes", equalTo(8));
        api(TENANT).body(Map.of("title", "Shuttle run", "durationMinutes", 10, "clear", List.of("description", "sets")))
                .patch(EXERCISES + "/" + id).then().statusCode(200).body("title", equalTo("Shuttle run"))
                .body("durationMinutes", equalTo(10)).body("description", nullValue()).body("sets", nullValue())
                .body("repetitions", equalTo(6));
        api(TENANT).get(EXERCISES + "/" + id).then().body("title", equalTo("Shuttle run")).body("sets", nullValue());
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ASSISTANT_COACH)
    void anArchivedExerciseLeavesTheCatalogueButStaysReadable() {
        String title = unique("Old drill");
        String id = create(TENANT, Map.of("title", title));

        api(TENANT).urlEncodingEnabled(false).post(EXERCISES + "/" + id + ":archive").then().statusCode(200)
                .body("archived", equalTo(true));
        api(TENANT).urlEncodingEnabled(false).post(EXERCISES + "/" + id + ":archive").then().statusCode(200)
                .body("archived", equalTo(true));

        api(TENANT).queryParam("q", title).get(EXERCISES).then().body("page.totalElements", equalTo(0));
        api(TENANT).queryParam("q", title).queryParam("includeArchived", true).get(EXERCISES).then()
                .body("items.id", contains(id)).body("items[0].archived", equalTo(true));
        api(TENANT).get(EXERCISES + "/" + id).then().statusCode(200).body("archived", equalTo(true));
        api(TENANT).urlEncodingEnabled(false).post(EXERCISES + "/" + id + ":unarchive").then().statusCode(200)
                .body("archived", equalTo(false));
        api(TENANT).queryParam("q", title).get(EXERCISES).then().body("items.id", contains(id));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void theScopeSeparatesGlobalFromOwnAndBothAreOrderedByTitleAndPaged() {
        String prefix = "Wp92 scope " + UUID.randomUUID().toString().substring(0, 6);
        String b = create(TENANT, Map.of("title", prefix + " b"));
        String a = create(TENANT, Map.of("title", prefix + " a"));
        String c = create(TENANT, Map.of("title", prefix + " c"));

        api(TENANT).queryParam("q", prefix).get(EXERCISES).then().body("items.id", contains(a, b, c));
        api(TENANT).queryParam("q", prefix).queryParam("size", 2).queryParam("page", 1).get(EXERCISES).then()
                .body("items.id", contains(c)).body("page.totalElements", equalTo(3)).body("page.totalPages", equalTo(2));
        api(TENANT).queryParam("scope", "TENANT").queryParam("size", 200).get(EXERCISES).then()
                .body("items.global", everyItem(equalTo(false))).body("items.id", hasItem(a));
        api(TENANT).queryParam("scope", "GLOBAL").queryParam("q", prefix).get(EXERCISES).then()
                .body("page.totalElements", equalTo(0));
        List<Boolean> both = api(TENANT).queryParam("size", 200).get(EXERCISES).then().extract().path("items.global");
        assertThat(both).contains(true, false);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void anotherAcademysExerciseDoesNotExist() {
        String mine = create(TENANT, Map.of("title", unique("Secret drill")));
        member(OTHER_TENANT, Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null);

        lenient(OTHER_TENANT).get(EXERCISES + "/" + mine).then().statusCode(404);
        lenient(OTHER_TENANT).body(Map.of("title", "Stolen")).patch(EXERCISES + "/" + mine).then().statusCode(404);
        lenient(OTHER_TENANT).urlEncodingEnabled(false).post(EXERCISES + "/" + mine + ":archive").then().statusCode(404);
        api(OTHER_TENANT).queryParam("scope", "TENANT").queryParam("size", 200).get(EXERCISES).then()
                .body("items.id", not(hasItem(mine)));
        api(OTHER_TENANT).queryParam("q", "cooper").get(EXERCISES).then().body("page.totalElements", equalTo(1));
        lenient(OTHER_TENANT).get(EXERCISES + "/" + UUID.randomUUID()).then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = OTHER_TENANT, roles = TenantRole.ADMIN)
    void aMemberOfAnotherTenantGetsNotFound() {
        lenient(TENANT).get(EXERCISES).then().statusCode(404);
        lenient(TENANT).body(Map.of("title", "x")).post(EXERCISES).then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void requestsAreValidated() {
        String id = create(TENANT, Map.of("title", unique("Valid")));

        lenient(TENANT).body(Map.of("title", " ")).post(EXERCISES).then().statusCode(400);
        lenient(TENANT).body(Map.of("title", "t".repeat(121))).post(EXERCISES).then().statusCode(400);
        lenient(TENANT).body(Map.of("title", "x", "durationMinutes", 0)).post(EXERCISES).then().statusCode(400);
        lenient(TENANT).body(Map.of("title", "x", "sets", 101)).post(EXERCISES).then().statusCode(400);
        lenient(TENANT).body(Map.of()).post(EXERCISES).then().statusCode(400);
        lenient(TENANT).body(Map.of()).patch(EXERCISES + "/" + id).then().statusCode(400);
        lenient(TENANT).body(Map.of("clear", List.of("title"))).patch(EXERCISES + "/" + id).then().statusCode(400);
        lenient(TENANT).body(Map.of("repetitions", 1001)).patch(EXERCISES + "/" + id).then().statusCode(400);
        lenient(TENANT).queryParam("q", "q".repeat(101)).get(EXERCISES).then().statusCode(400);
        lenient(TENANT).queryParam("scope", "EVERYWHERE").get(EXERCISES).then().statusCode(400);
        lenient(TENANT).queryParam("size", 201).get(EXERCISES).then().statusCode(400);
    }
}
