package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasSize;
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
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Decision 43 (athlete 2.2.0): template texts follow Accept-Language (fallback en); tenant plans are returned as stored. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class TemplateLanguageApiTest {

    static final String TENANT = "61000000-0000-4000-8000-000000000001";
    static final String PLANS = "/api/athlete/training-plans";

    static RequestSpecification in(String acceptLanguage) {
        return api(TENANT).header("Accept-Language", acceptLanguage);
    }

    static List<String> templateNames(RequestSpecification spec) {
        return spec.queryParam("template", true).queryParam("size", 50).get(PLANS).then().statusCode(200)
                .body("items.nameKey", everyItem(notNullValue())).extract().path("items.name");
    }

    static String formShooting() {
        return api(TENANT).queryParam("template", true).queryParam("size", 50).get(PLANS).then().statusCode(200)
                .extract().path("items.find { it.nameKey == 'form-shooting' }.id");
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PLAYER, ownPlayer = "61000000-0000-4000-8000-0000000000b1")
    void templatesAreListedInTheCallersLanguage() {
        assertThat(templateNames(in("es"))).hasSize(10).contains("Calentamiento y movilidad", "Técnica de tiro",
                "Vuelta a la calma y estiramientos");
        assertThat(templateNames(in("id"))).hasSize(10).contains("Pemanasan & mobilitas", "Teknik menembak",
                "Pendinginan & peregangan");
        assertThat(templateNames(in("en"))).hasSize(10).contains("Warm-up & mobility", "Form shooting",
                "Cool-down & stretching");
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT)
    void theFirstSupportedLanguageWinsAndEnglishIsTheFallback() {
        assertThat(templateNames(in("fr-FR, id;q=0.8, es;q=0.5"))).contains("Teknik menembak");
        assertThat(templateNames(in("es-AR,es;q=0.9"))).contains("Técnica de tiro");
        assertThat(templateNames(in("fr"))).contains("Form shooting");
        assertThat(templateNames(in("*"))).contains("Form shooting");
        assertThat(templateNames(api(TENANT))).as("no header").contains("Form shooting");
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void aTemplateDetailTranslatesItsItems() {
        String id = formShooting();

        in("es").get(PLANS + "/" + id).then().statusCode(200).body("nameKey", equalTo("form-shooting"))
                .body("name", equalTo("Técnica de tiro")).body("description", notNullValue())
                .body("items[0].title", equalTo("Tiros a una mano")).body("items[0].position", equalTo(0));
        in("id").get(PLANS + "/" + id).then().statusCode(200).body("name", equalTo("Teknik menembak"))
                .body("items[0].title", equalTo("Tembakan satu tangan"));
        in("en").get(PLANS + "/" + id).then().statusCode(200).body("name", equalTo("Form shooting"))
                .body("items[0].title", equalTo("One-hand form shots"));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void searchMatchesTheTemplateNameInTheCallersLanguage() {
        in("es").queryParam("template", true).queryParam("q", "TIRO").get(PLANS).then().statusCode(200)
                .body("items.name", hasItem("Técnica de tiro")).body("items.name", hasItem("Rutina de tiros libres"));
        in("id").queryParam("template", true).queryParam("q", "menembak").get(PLANS).then().statusCode(200)
                .body("items.name", equalTo(List.of("Teknik menembak")));
        in("en").queryParam("template", true).queryParam("q", "tiro").get(PLANS).then().statusCode(200)
                .body("items", hasSize(0)).body("page.totalElements", equalTo(0));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void aCopyKeepsTheNameItWasCopiedWithInTheCopiersLanguage() {
        String template = formShooting();

        String copy = in("es").urlEncodingEnabled(false).post(PLANS + "/" + template + ":copy").then().statusCode(201)
                .body("name", equalTo("Técnica de tiro")).body("template", equalTo(false))
                .body("nameKey", nullValue()).body("sourceTemplateId", equalTo(template))
                .body("items[0].title", equalTo("Tiros a una mano")).extract().path("id");

        in("id").get(PLANS + "/" + copy).then().statusCode(200).body("name", equalTo("Técnica de tiro"))
                .body("items[0].title", equalTo("Tiros a una mano"));
        in("en").get(PLANS).then().statusCode(200).body("items.find { it.id == '" + copy + "' }.name",
                equalTo("Técnica de tiro"));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void aTenantPlanIsReturnedAsStoredWhateverTheLanguage() {
        String plan = api(TENANT).body(Map.of("name", "Mi plan del martes", "items", List.of(Map.of("title", "Bote"))))
                .post(PLANS).then().statusCode(201).body("nameKey", nullValue()).extract().path("id");

        for (String language : List.of("es", "en", "id")) {
            in(language).get(PLANS + "/" + plan).then().statusCode(200).body("name", equalTo("Mi plan del martes"))
                    .body("items[0].title", equalTo("Bote"));
        }
        in("id").queryParam("q", "martes").get(PLANS).then().body("items.name", hasItem("Mi plan del martes"))
                .body("items.nameKey", everyItem(nullValue())).body("items.template", not(hasItem(true)));
    }
}
