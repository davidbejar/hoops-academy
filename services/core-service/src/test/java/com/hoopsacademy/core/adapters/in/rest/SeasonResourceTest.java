package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import java.time.LocalDate;
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
class SeasonResourceTest {

    private static final String SEASONS = "/api/core/seasons";
    private static final LocalDate TODAY = RosterDb.TODAY;

    private String tenant;

    @BeforeEach
    void adminOfAFreshTenant() {
        tenant = Members.newTenant();
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void adminCreatesListsGetsAndUpdatesSeasons() {
        var created = create("Past", TODAY.minusDays(400), TODAY.minusDays(100), 2020).statusCode(201)
                .body("name", equalTo("Past"))
                .body("startsOn", equalTo(TODAY.minusDays(400).toString()))
                .body("referenceYear", equalTo(2020))
                .body("current", equalTo(false))
                .extract();
        String past = created.path("id");
        assertThat(created.header("Location")).endsWith(SEASONS + "/" + past);
        String current = create("Now", TODAY.minusDays(10), TODAY.plusDays(100), RosterDb.YEAR).statusCode(201)
                .body("current", equalTo(true)).extract().path("id");

        request().get(SEASONS).then().statusCode(200).body("id", contains(current, past));
        request().get(SEASONS + "/" + past).then().statusCode(200).body("name", equalTo("Past"));
        patch(past, "{\"name\":\"Old\",\"referenceYear\":2019}").statusCode(200)
                .body("name", equalTo("Old")).body("referenceYear", equalTo(2019)).body("current", equalTo(false));
        request().get(SEASONS + "/" + UUID.randomUUID()).then().statusCode(404);
        patch(UUID.randomUUID().toString(), "{\"name\":\"x\"}").statusCode(404);
    }

    @Test
    void seasonsOfATenantMustNotOverlap() {
        create("A", LocalDate.of(2030, 9, 1), LocalDate.of(2031, 6, 30), 2030).statusCode(201);
        String b = create("B", LocalDate.of(2031, 9, 1), LocalDate.of(2032, 6, 30), 2031).statusCode(201).extract().path("id");
        create("C", LocalDate.of(2031, 6, 30), LocalDate.of(2031, 8, 1), 2031).statusCode(409)
                .body("code", equalTo("SEASON_OVERLAP"));
        patch(b, "{\"startsOn\":\"2031-06-01\"}").statusCode(409).body("code", equalTo("SEASON_OVERLAP"));
        patch(b, "{\"startsOn\":\"2031-07-01\"}").statusCode(200);
    }

    @Test
    void invalidRequestsAre400AndRuleViolations422() {
        create("X", LocalDate.of(2030, 9, 2), LocalDate.of(2030, 9, 1), 2030).statusCode(422)
                .body("code", equalTo("INVALID_ENDS_ON"));
        create("X", LocalDate.of(2030, 9, 1), LocalDate.of(2031, 9, 1), 1999).statusCode(400);
        requestUnchecked().contentType(ContentType.JSON).body("{\"name\":\"X\"}").post(SEASONS)
                .then().statusCode(400);
        String id = create("Y", LocalDate.of(2030, 9, 1), LocalDate.of(2031, 6, 30), 2030).statusCode(201).extract().path("id");
        patch(id, "{\"endsOn\":\"2030-01-01\"}").statusCode(422);
        requestUnchecked().contentType(ContentType.JSON).body("{}").patch(SEASONS + "/" + id).then().statusCode(400);
        requestUnchecked().contentType(ContentType.JSON).body("{\"referenceYear\":\"x\",\"name\":null}")
                .patch(SEASONS + "/" + id).then().statusCode(400);
    }

    @ParameterizedTest
    @MethodSource("com.hoopsacademy.core.testsupport.Members#roleSetsWithAdminFlag")
    void everyMemberReadsOnlyAdminsWrite(Set<TenantRole> roles, boolean admin) {
        UUID existing = RosterDb.season(tenant, "S", LocalDate.of(2040, 9, 1), LocalDate.of(2041, 6, 30), 2040);
        Members.signIn(tenant, roles);
        request().get(SEASONS).then().statusCode(200);
        request().get(SEASONS + "/" + existing).then().statusCode(200);
        create("New", LocalDate.of(2042, 9, 1), LocalDate.of(2043, 6, 30), 2042).statusCode(admin ? 201 : 403);
        patch(existing.toString(), "{\"name\":\"Renamed\"}").statusCode(admin ? 200 : 403);
    }

    @Test
    void anotherTenantsSeasonsAreNotFound() {
        UUID foreign = RosterDb.season(tenant, "S", LocalDate.of(2040, 9, 1), LocalDate.of(2041, 6, 30), 2040);
        String other = Members.newTenant();
        Members.signIn(other, TenantRole.ADMIN);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(SEASONS + "/" + foreign).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).contentType(ContentType.JSON).body("{\"name\":\"x\"}")
                .patch(SEASONS + "/" + foreign).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(SEASONS).then().statusCode(200)
                .body("size()", equalTo(0));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(SEASONS).then().statusCode(404);
        // the same dates are fine in another tenant
        given().filter(Contract.CORE).header("X-Tenant-Id", other).contentType(ContentType.JSON)
                .body(body("S", LocalDate.of(2040, 9, 1), LocalDate.of(2041, 6, 30), 2040)).post(SEASONS)
                .then().statusCode(201);
    }

    private io.restassured.specification.RequestSpecification request() {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant);
    }

    private io.restassured.specification.RequestSpecification requestUnchecked() {
        return given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant);
    }

    private ValidatableResponse create(String name, LocalDate from, LocalDate to, int referenceYear) {
        var spec = referenceYear < 2000 ? requestUnchecked() : request();
        return spec.contentType(ContentType.JSON).body(body(name, from, to, referenceYear)).post(SEASONS).then();
    }

    private ValidatableResponse patch(String id, String json) {
        return request().contentType(ContentType.JSON).body(json).patch(SEASONS + "/" + id).then();
    }

    private static String body(String name, LocalDate from, LocalDate to, int referenceYear) {
        return "{\"name\":\"" + name + "\",\"startsOn\":\"" + from + "\",\"endsOn\":\"" + to + "\",\"referenceYear\":"
                + referenceYear + "}";
    }
}
