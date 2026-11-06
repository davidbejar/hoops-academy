package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.RosterEvents;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import io.restassured.specification.RequestSpecification;
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class EligibilityCaseResourceTest {

    private static final String CASES = "/api/core/eligibility-cases";

    private String tenant;
    private UUID season;
    private Map<String, UUID> categories;
    private UUID lions;
    private UUID tom;
    private UUID assignment;
    private UUID caseId;

    /** Tom (13) sits invalidly on the U12 team "Lions" with an OPEN case. */
    @BeforeEach
    void anOpenCase() {
        tenant = Members.newTenant();
        season = RosterDb.currentSeason(tenant);
        categories = RosterDb.defaultCategories(tenant);
        lions = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        tom = RosterDb.playerAged(tenant, "Tom", 13, "MALE");
        assignment = RosterDb.assignment(tenant, lions, tom, "5");
        caseId = RosterDb.openCase(tenant, assignment, "CATEGORY_TOO_LOW");
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.player set status = 'ORPHAN' where id = ?", tom));
        RosterDb.callerPerson(tenant);
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void adminListsFiltersAndGetsCases() {
        request().get(CASES).then().statusCode(200).body("items.id", contains(caseId.toString()))
                .body("page.totalElements", equalTo(1));
        request().queryParam("status", "OPEN").queryParam("teamId", lions.toString()).queryParam("playerId", tom.toString())
                .get(CASES).then().body("items", hasSize(1));
        request().queryParam("status", "RESOLVED").get(CASES).then().body("items", hasSize(0));
        request().queryParam("teamId", UUID.randomUUID().toString()).get(CASES).then().body("items", hasSize(0));
        request().get(CASES + "/" + caseId).then().statusCode(200)
                .body("player.id", equalTo(tom.toString())).body("player.displayName", equalTo("Tom Test"))
                .body("team.id", equalTo(lions.toString())).body("team.name", equalTo("Lions"))
                .body("reason", equalTo("CATEGORY_TOO_LOW")).body("status", equalTo("OPEN"))
                .body("openedAt", notNullValue()).body("resolution", nullValue());
        request().get(CASES + "/" + UUID.randomUUID()).then().statusCode(404);
    }

    @Test
    void dismissingRecordsTheDecisionOnlyAndOnlyOnce() {
        resolve("{\"resolution\":\"DISMISSED\",\"note\":\"Federation waiver\"}").statusCode(200)
                .body("status", equalTo("RESOLVED")).body("resolution", equalTo("DISMISSED"))
                .body("resolutionNote", equalTo("Federation waiver"))
                .body("resolvedBy.personId", equalTo(Members.callerPersonId(tenant).toString()))
                .body("resolvedBy.displayName", equalTo("Cal Ler"))
                .body("resolvedAt", notNullValue());
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where id = ? and left_on is null "
                + "and invalidated_at is not null", assignment)).isEqualTo(1);
        resolve("{\"resolution\":\"DISMISSED\"}").statusCode(409).body("code", equalTo("ELIGIBILITY_CASE_NOT_OPEN"));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"resolution\":\"DISMISSED\"}").post(CASES + "/" + UUID.randomUUID() + "/resolve")
                .then().statusCode(404);
    }

    @Test
    void removingFromTheTeamClosesTheInvalidAssignment() {
        resolve("{\"resolution\":\"REMOVED_FROM_TEAM\"}").statusCode(200).body("resolution", equalTo("REMOVED_FROM_TEAM"));
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where id = ? and left_on is not null",
                assignment)).isEqualTo(1);
        assertThat(RosterDb.playerStatus(tenant, tom)).isEqualTo("ORPHAN");
        assertThat(RosterEvents.state(tenant, "core.team-player", assignment).get("leftOn").isNull()).isFalse();
    }

    @Test
    void reassigningRunsTheEligibilityCheckedAssignment() {
        UUID u12b = RosterDb.team(tenant, season, "Other U12", categories.get("U12"), "MIXED");
        UUID u14 = RosterDb.team(tenant, season, "U14", categories.get("U14"), "MIXED");
        resolve("{\"resolution\":\"REASSIGNED\"}").statusCode(422).body("code", equalTo("TARGET_TEAM_REQUIRED"));
        resolve("{\"resolution\":\"REASSIGNED\",\"targetTeamId\":\"" + u12b + "\"}").statusCode(422)
                .body("code", equalTo("PLAYER_INELIGIBLE")).body("violations.code", contains("CATEGORY_TOO_LOW"));
        resolve("{\"resolution\":\"REASSIGNED\",\"targetTeamId\":\"" + UUID.randomUUID() + "\"}").statusCode(404);
        request().get(CASES + "/" + caseId).then().body("status", equalTo("OPEN"));

        resolve("{\"resolution\":\"REASSIGNED\",\"targetTeamId\":\"" + u14 + "\"}").statusCode(200)
                .body("resolution", equalTo("REASSIGNED"));
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where team_id = ? and player_id = ? "
                + "and left_on is null and invalidated_at is null", u14, tom)).isEqualTo(1);
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where id = ? and left_on is not null",
                assignment)).isEqualTo(1);
        assertThat(RosterDb.playerStatus(tenant, tom)).isEqualTo("ACTIVE");
    }

    /** roles, staff of the case's team?, sees the case in the list, may get it, may resolve it. */
    static Stream<Arguments> callers() {
        return Stream.of(
                Arguments.of(EnumSet.of(TenantRole.ADMIN), false, 200, true, 200, 200),
                Arguments.of(EnumSet.of(TenantRole.COACH), true, 200, true, 200, 200),
                Arguments.of(EnumSet.of(TenantRole.COACH), false, 200, false, 403, 403),
                Arguments.of(EnumSet.of(TenantRole.ASSISTANT_COACH), true, 200, true, 200, 403),
                Arguments.of(EnumSet.of(TenantRole.ASSISTANT_COACH), false, 200, false, 403, 403),
                Arguments.of(EnumSet.of(TenantRole.PARENT), false, 403, false, 403, 403),
                Arguments.of(EnumSet.of(TenantRole.PLAYER), false, 403, false, 403, 403),
                Arguments.of(EnumSet.of(TenantRole.ADMIN, TenantRole.COACH), false, 200, true, 200, 200),
                Arguments.of(EnumSet.of(TenantRole.COACH, TenantRole.PARENT), true, 200, true, 200, 200));
    }

    @ParameterizedTest
    @MethodSource("callers")
    void roleMatrix(Set<TenantRole> roles, boolean staff, int listStatus, boolean seesCase, int getStatus, int resolveStatus) {
        Members.signInAs(tenant, Members.callerPersonId(tenant), roles, staff ? Set.of(lions) : Set.of());
        ValidatableResponse list = request().get(CASES).then().statusCode(listStatus);
        if (listStatus == 200) {
            list.body("items", hasSize(seesCase ? 1 : 0));
        }
        request().get(CASES + "/" + caseId).then().statusCode(getStatus);
        resolve("{\"resolution\":\"DISMISSED\"}").statusCode(resolveStatus);
    }

    @Test
    void anotherTenantsCasesAreNotFound() {
        String other = Members.newTenant();
        Members.signIn(other, TenantRole.ADMIN);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(CASES + "/" + caseId).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).contentType(ContentType.JSON)
                .body("{\"resolution\":\"DISMISSED\"}").post(CASES + "/" + caseId + "/resolve").then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(CASES).then().statusCode(200).body("items", hasSize(0));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(CASES).then().statusCode(404);
        assertThat(CoreDb.count(tenant, "select count(*) from core.eligibility_case where status = 'OPEN'")).isEqualTo(1);
    }

    private RequestSpecification request() {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant);
    }

    private ValidatableResponse resolve(String json) {
        return request().contentType(ContentType.JSON).body(json).post(CASES + "/" + caseId + "/resolve").then();
    }
}
