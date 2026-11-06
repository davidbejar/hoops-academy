package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import io.restassured.specification.RequestSpecification;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class AgeCategoryResourceTest {

    private static final String CATEGORIES = "/api/core/age-categories";

    private String tenant;

    @BeforeEach
    void adminOfAFreshTenant() {
        tenant = Members.newTenant();
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void listsTheLadderInRankOrder() {
        RosterDb.defaultCategories(tenant);
        request().get(CATEGORIES).then().statusCode(200)
                .body("code", contains("U8", "U10", "U12", "U14", "U16", "U18", "SENIOR"))
                .body("rank", contains(0, 1, 2, 3, 4, 5, 6))
                .body("[6].maxAge", nullValue());
    }

    @Test
    void adminCreatesUpdatesAndDeletesCategories() {
        var created = create("{\"code\":\"MINI\",\"name\":\"Mini\",\"maxAge\":6,\"rank\":10}").statusCode(201)
                .body("code", equalTo("MINI")).body("maxAge", equalTo(6)).body("rank", equalTo(10)).extract();
        String mini = created.path("id");
        assertThat(created.header("Location")).endsWith(CATEGORIES + "/" + mini);
        String open = create("{\"code\":\"OPEN\",\"name\":\"Open\",\"rank\":20}").statusCode(201)
                .body("maxAge", nullValue()).extract().path("id");

        patch(mini, "{\"name\":\"Minis\",\"maxAge\":7}").statusCode(200).body("name", equalTo("Minis")).body("maxAge", equalTo(7));
        patch(open, "{\"maxAge\":30}").statusCode(200).body("maxAge", equalTo(30));
        patch(open, "{\"maxAge\":null}").statusCode(200).body("maxAge", equalTo(30));
        patch(open, "{\"clear\":[\"maxAge\"]}").statusCode(200).body("maxAge", nullValue());
        patch(open, "{\"maxAge\":31,\"clear\":[\"maxAge\"]}").statusCode(400)
                .body("violations.code", contains("CLEAR_CONFLICT"));
        patch(open, "{\"clear\":[]}").statusCode(400);
        request().delete(CATEGORIES + "/" + open).then().statusCode(204);
        request().delete(CATEGORIES + "/" + open).then().statusCode(404);
        patch(UUID.randomUUID().toString(), "{\"name\":\"x\"}").statusCode(404);
        request().get(CATEGORIES).then().body("code", contains("MINI"));
    }

    @Test
    void aCategoryPatchThatChangesNothingReturnsTheCategoryAndWritesNoAuditRow() {
        String open = create("{\"code\":\"OPEN\",\"name\":\"Open\",\"rank\":20}").statusCode(201).extract().path("id");
        int before = CoreDb.auditActions(tenant).size();

        patch(open, "{\"code\":\"OPEN\",\"name\":\"Open\",\"rank\":20}").statusCode(200)
                .body("code", equalTo("OPEN")).body("name", equalTo("Open")).body("rank", equalTo(20));
        patch(open, "{\"clear\":[\"maxAge\"]}").statusCode(200).body("maxAge", nullValue());

        assertThat(CoreDb.auditActions(tenant)).hasSize(before);
    }

    @Test
    void codesAndRanksAreUniqueAndMaxAgeMustGrowWithRank() {
        Map<String, UUID> ladder = RosterDb.defaultCategories(tenant);
        create("{\"code\":\"U12\",\"name\":\"Dup\",\"maxAge\":30,\"rank\":40}").statusCode(409)
                .body("code", equalTo("AGE_CATEGORY_CODE_TAKEN"));
        create("{\"code\":\"NEW\",\"name\":\"Dup\",\"maxAge\":30,\"rank\":2}").statusCode(409)
                .body("code", equalTo("AGE_CATEGORY_RANK_TAKEN"));
        create("{\"code\":\"OLD\",\"name\":\"Old\",\"maxAge\":30,\"rank\":40}").statusCode(422)
                .body("code", equalTo("AGE_CATEGORY_ORDER"));
        patch(ladder.get("U12").toString(), "{\"maxAge\":15}").statusCode(422).body("code", equalTo("AGE_CATEGORY_ORDER"));
        patch(ladder.get("U12").toString(), "{\"code\":\"U14\"}").statusCode(409);
        patch(ladder.get("U12").toString(), "{\"code\":\"U12\",\"rank\":2}").statusCode(200);
        requestUnchecked().contentType(ContentType.JSON).body("{\"code\":\"lower\",\"name\":\"x\",\"rank\":1}")
                .post(CATEGORIES).then().statusCode(400);
        requestUnchecked().contentType(ContentType.JSON).body("{\"maxAge\":\"old\"}")
                .patch(CATEGORIES + "/" + ladder.get("U12")).then().statusCode(400);
    }

    @Test
    void aCategoryInUseCannotBeDeleted() {
        Map<String, UUID> ladder = RosterDb.defaultCategories(tenant);
        RosterDb.team(tenant, RosterDb.currentSeason(tenant), "Cubs", ladder.get("U10"), "MIXED");
        request().delete(CATEGORIES + "/" + ladder.get("U10")).then().statusCode(409)
                .body("code", equalTo("AGE_CATEGORY_IN_USE"));
        assertThat(CoreDb.count(tenant, "select count(*) from core.age_category")).isEqualTo(7);
    }

    @ParameterizedTest
    @MethodSource("com.hoopsacademy.core.testsupport.Members#roleSetsWithAdminFlag")
    void everyMemberReadsOnlyAdminsWrite(Set<TenantRole> roles, boolean admin) {
        UUID existing = RosterDb.defaultCategories(tenant).get("SENIOR");
        Members.signIn(tenant, roles);
        request().get(CATEGORIES).then().statusCode(200);
        create("{\"code\":\"X\",\"name\":\"X\",\"rank\":50}").statusCode(admin ? 422 : 403);
        patch(existing.toString(), "{\"name\":\"Seniors\"}").statusCode(admin ? 200 : 403);
        request().delete(CATEGORIES + "/" + existing).then().statusCode(admin ? 204 : 403);
    }

    @Test
    void anotherTenantsCategoriesAreNotFound() {
        UUID foreign = RosterDb.defaultCategories(tenant).get("U8");
        String other = Members.newTenant();
        Members.signIn(other, TenantRole.ADMIN);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).contentType(ContentType.JSON).body("{\"name\":\"x\"}")
                .patch(CATEGORIES + "/" + foreign).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).delete(CATEGORIES + "/" + foreign).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(CATEGORIES).then().statusCode(200)
                .body("size()", equalTo(0));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(CATEGORIES).then().statusCode(404);
    }

    private RequestSpecification request() {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant);
    }

    private RequestSpecification requestUnchecked() {
        return given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant);
    }

    private ValidatableResponse create(String json) {
        return request().contentType(ContentType.JSON).body(json).post(CATEGORIES).then();
    }

    private ValidatableResponse patch(String id, String json) {
        return request().contentType(ContentType.JSON).body(json).patch(CATEGORIES + "/" + id).then();
    }
}
