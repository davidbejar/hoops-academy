package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.common.tenancy.TenantRole;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.response.ValidatableResponse;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Decision 54 (athlete 2.3.0): `q` also finds plans by an item title, in the negotiated language, with the matches. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class PlanItemSearchApiTest {

    static final String TENANT = "78000000-0000-4000-8000-000000000011";
    static final String PLANS = "/api/athlete/training-plans";

    static ValidatableResponse templates(String language, String q) {
        return api(TENANT).header("Accept-Language", language).queryParam("template", true).queryParam("q", q)
                .get(PLANS).then().statusCode(200);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void anItemTitleFindsItsTemplateInTheCallersLanguage() {
        String finishing = templates("en", "Finishing").extract().path("items[0].id");

        templates("es", "EUROPEO").body("items.nameKey", contains("finishing-at-the-rim"))
                .body("items[0].name", equalTo("Finalización junto al aro"))
                .body("items[0].matchedItems.title", contains("Paso europeo"))
                .body("items[0].matchedItems[0].planId", equalTo(finishing))
                .body("page.totalElements", equalTo(1));
        templates("en", "europeo").body("items", hasSize(0)).body("page.totalElements", equalTo(0));
        templates("id", "suicide run").body("items.name", contains("Kondisi fisik (interval)"))
                .body("items[0].matchedItems.title", contains("Suicide run"));
        templates("en", "suicid").body("items[0].matchedItems.title", contains("Suicides"));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PLAYER, ownPlayer = "78000000-0000-4000-8000-0000000000b1")
    void aNameMatchListsNoItemsAndBothKindsOfMatchCombine() {
        templates("en", "free-throw").body("items.name", containsInAnyOrder("Form shooting", "Free-throw routine"))
                .body("items.find { it.name == 'Free-throw routine' }.matchedItems", nullValue())
                .body("items.find { it.name == 'Form shooting' }.matchedItems.title", contains("Free-throw line shots"));
        templates("en", "shot").body("items.find { it.nameKey == 'form-shooting' }.matchedItems.title",
                contains("One-hand form shots", "Both hands form shots", "Free-throw line shots"));
        api(TENANT).queryParam("template", true).get(PLANS).then().body("items[0].matchedItems", nullValue());
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void tenantPlansAreFoundByTheirStoredItemTitles() {
        String plan = api(TENANT).body(Map.of("name", "Tuesday", "items", List.of(Map.of("title", "Warm-up"),
                Map.of("title", "Zigzag sprint"), Map.of("title", "zigzag slides")))).post(PLANS).then().statusCode(201)
                .extract().path("id");

        api(TENANT).header("Accept-Language", "es").queryParam("q", "ZIGZAG").get(PLANS).then().statusCode(200)
                .body("items.id", contains(plan)).body("items[0].matchedItems.title", contains("Zigzag sprint", "zigzag slides"))
                .body("items[0].matchedItems.planId", contains(plan, plan));
        api(TENANT).queryParam("q", "zig_zag").get(PLANS).then().body("items", hasSize(0));
        api(TENANT).queryParam("q", "%").get(PLANS).then().body("items", hasSize(0));
    }
}
