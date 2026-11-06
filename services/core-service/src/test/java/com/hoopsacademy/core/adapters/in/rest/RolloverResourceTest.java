package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.hasSize;

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
import io.restassured.response.ExtractableResponse;
import io.restassured.response.Response;
import io.restassured.response.ValidatableResponse;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * Last season (already over, reference year Y−1) → the current season (reference year Y), BIRTH_YEAR rule: every
 * player is one year older, so U12 players born in Y−12 become too old while those born in Y−11 stay eligible.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class RolloverResourceTest {

    private static final int Y = RosterDb.YEAR;

    private String tenant;
    private UUID last;
    private UUID current;
    private UUID lions;
    private UUID girls;
    private UUID coach;
    private UUID ann;
    private UUID bea;
    private UUID cat;
    private UUID dan;

    @BeforeEach
    void lastSeasonWithTwoTeams() {
        tenant = Members.newTenant();
        Map<String, UUID> categories = RosterDb.defaultCategories(tenant);
        last = RosterDb.season(tenant, "Last", RosterDb.TODAY.minusDays(400), RosterDb.TODAY.minusDays(100), Y - 1);
        current = RosterDb.currentSeason(tenant);
        lions = RosterDb.team(tenant, last, "Lions", categories.get("U12"), "MIXED");
        girls = RosterDb.team(tenant, last, "Girls", categories.get("U10"), "FEMALE");
        coach = CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH);
        RosterDb.staff(tenant, lions, coach, "COACH");
        ann = RosterDb.player(tenant, "Ann", "Old", LocalDate.of(Y - 12, 3, 1), "FEMALE");
        bea = RosterDb.player(tenant, "Bea", "Young", LocalDate.of(Y - 11, 3, 1), "FEMALE");
        cat = RosterDb.player(tenant, "Cat", "Girl", LocalDate.of(Y - 10, 3, 1), "FEMALE");
        dan = RosterDb.player(tenant, "Dan", "Gone", LocalDate.of(Y - 11, 3, 1), "MALE");
        RosterDb.assignment(tenant, lions, ann, "4");
        RosterDb.assignment(tenant, lions, bea, "5");
        RosterDb.assignment(tenant, girls, cat, null);
        RosterDb.assignment(tenant, lions, dan, null);
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.player set status = 'WITHDRAWN' where id = ?", dan));
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void rolloverClonesTeamsStaffAndPlayersAndReturnsTheOrphans() {
        ExtractableResponse<Response> result = rollover(current, "{\"fromSeasonId\":\"" + last + "\"}").statusCode(200)
                .body("fromSeasonId", equalTo(last.toString()))
                .body("toSeasonId", equalTo(current.toString()))
                .body("clonedTeams.name", containsInAnyOrder("Lions", "Girls"))
                .body("orphans.player.id", containsInAnyOrder(ann.toString(), cat.toString()))
                .body("orphans.player.displayName", containsInAnyOrder("Ann Old", "Cat Girl"))
                .body("orphans.previousTeam.name", containsInAnyOrder("Lions", "Girls"))
                .body("orphans.reasons", everyItem(equalTo(List.of("CATEGORY_TOO_LOW"))))
                .body("openedCaseIds", hasSize(2))
                .extract();

        UUID newLions = UUID.fromString(result.path("clonedTeams.find { it.name == 'Lions' }.id"));
        assertThat(CoreDb.count(tenant, "select count(*) from core.team where season_id = ?", current)).isEqualTo(2);
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_staff where team_id = ? and person_id = ? "
                + "and role = 'COACH'", newLions, coach)).isEqualTo(1);
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where team_id = ? and player_id = ? "
                + "and invalidated_at is null and left_on is null and jersey_number = '5'", newLions, bea)).isEqualTo(1);
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where team_id = ? and player_id = ? "
                + "and invalid_reason = 'CATEGORY_TOO_LOW'", newLions, ann)).isEqualTo(1);
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where player_id = ? and team_id = ?", dan,
                newLions)).isZero();
        assertThat(CoreDb.count(tenant, "select count(*) from core.eligibility_case where status = 'OPEN'")).isEqualTo(2);
        assertThat(RosterDb.playerStatus(tenant, ann)).isEqualTo("ORPHAN");
        assertThat(RosterDb.playerStatus(tenant, cat)).isEqualTo("ORPHAN");
        assertThat(RosterDb.playerStatus(tenant, bea)).isEqualTo("ACTIVE");
        assertThat(RosterDb.playerStatus(tenant, dan)).isEqualTo("WITHDRAWN");
        assertThat(RosterEvents.state(tenant, "core.team", newLions).get("seasonId").asText()).isEqualTo(current.toString());
        assertThat(RosterEvents.state(tenant, "core.team-staff", RosterEvents.teamStaffId(newLions, coach)).get("role")
                .asText()).isEqualTo("COACH");
        UUID annCopy = UUID.fromString(RosterDb.text(tenant,
                "select id::text from core.team_player where team_id = ? and player_id = ?", newLions, ann));
        assertThat(RosterEvents.state(tenant, "core.team-player", annCopy).get("invalidReason").asText())
                .as("the eligibility engine's invalidation").isEqualTo("CATEGORY_TOO_LOW");
        assertThat(RosterEvents.state(tenant, "core.player", ann).get("status").asText())
                .as("the status sync's ORPHAN").isEqualTo("ORPHAN");
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where team_id = ? and left_on is null", lions))
                .as("last season's history is kept").isEqualTo(3);

        rollover(current, "{\"fromSeasonId\":\"" + last + "\"}").statusCode(409).body("code", equalTo("ROLLOVER_TARGET_NOT_EMPTY"));
    }

    @Test
    void withoutPlayersEveryFormerPlayerIsAnOrphanAndNoCaseIsOpened() {
        rollover(current, "{\"fromSeasonId\":\"" + last + "\",\"clonePlayers\":false,\"cloneStaff\":false}").statusCode(200)
                .body("clonedTeams", hasSize(2))
                .body("orphans.player.id", containsInAnyOrder(ann.toString(), bea.toString(), cat.toString()))
                .body("orphans.reasons", everyItem(empty()))
                .body("openedCaseIds", empty());
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_staff s join core.team t on t.id = s.team_id "
                + "where t.season_id = ?", current)).isZero();
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player p join core.team t on t.id = p.team_id "
                + "where t.season_id = ?", current)).isZero();
        assertThat(RosterDb.playerStatus(tenant, bea)).isEqualTo("ORPHAN");
    }

    @Test
    void invalidRollovers() {
        rollover(current, "{\"fromSeasonId\":\"" + current + "\"}").statusCode(422).body("code", equalTo("ROLLOVER_SAME_SEASON"));
        rollover(last, "{\"fromSeasonId\":\"" + current + "\"}").statusCode(422).body("code", equalTo("ROLLOVER_BACKWARDS"));
        rollover(current, "{\"fromSeasonId\":\"" + UUID.randomUUID() + "\"}").statusCode(404);
        rollover(UUID.randomUUID(), "{\"fromSeasonId\":\"" + last + "\"}").statusCode(404);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON).body("{}")
                .post("/api/core/seasons/" + current + "/rollover").then().statusCode(400);
    }

    @ParameterizedTest
    @MethodSource("com.hoopsacademy.core.testsupport.Members#roleSetsWithAdminFlag")
    void onlyAdminsRollOver(Set<TenantRole> roles, boolean admin) {
        Members.signIn(tenant, roles);
        rollover(current, "{\"fromSeasonId\":\"" + last + "\"}").statusCode(admin ? 200 : 403);
    }

    @Test
    void anotherTenantsSeasonsCannotBeRolledOver() {
        String other = Members.newTenant();
        UUID otherSeason = RosterDb.currentSeason(other);
        Members.signIn(other, TenantRole.ADMIN);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).contentType(ContentType.JSON)
                .body("{\"fromSeasonId\":\"" + last + "\"}").post("/api/core/seasons/" + otherSeason + "/rollover")
                .then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).contentType(ContentType.JSON)
                .body("{\"fromSeasonId\":\"" + last + "\"}").post("/api/core/seasons/" + current + "/rollover")
                .then().statusCode(404);
        assertThat(CoreDb.count(tenant, "select count(*) from core.team where season_id = ?", current)).isZero();
    }

    private ValidatableResponse rollover(UUID target, String json) {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON).body(json)
                .post("/api/core/seasons/" + target + "/rollover").then();
    }
}
