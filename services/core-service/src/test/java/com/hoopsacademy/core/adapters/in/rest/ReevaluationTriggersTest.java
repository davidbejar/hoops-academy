package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;

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
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Writes that change eligibility re-evaluate open assignments in the same transaction (invalidate + case). */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class ReevaluationTriggersTest {

    private String tenant;
    private UUID season;
    private Map<String, UUID> categories;
    private UUID team;
    private UUID uma;

    /** Uma (11) plays one level up in U14 with an unlimited play-up setting. */
    @BeforeEach
    void playUpAssignment() {
        tenant = Members.newTenant();
        season = RosterDb.currentSeason(tenant);
        categories = RosterDb.defaultCategories(tenant);
        team = RosterDb.team(tenant, season, "U14", categories.get("U14"), "MIXED");
        uma = RosterDb.playerAged(tenant, "Uma", 11, "FEMALE");
        RosterDb.assignment(tenant, team, uma, null);
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void lowerPlayUpLimitInvalidates() {
        send("/api/core/tenant/settings", "PUT", "{\"ageRule\":\"BIRTH_YEAR\",\"maxPlayUpLevels\":0}").statusCode(200);
        assertInvalidated("PLAY_UP_LIMIT_EXCEEDED");
    }

    @Test
    void anUnchangedRuleDoesNotTouchAssignments() {
        send("/api/core/tenant/settings", "PUT", "{\"ageRule\":\"BIRTH_YEAR\",\"maxPlayUpLevels\":1}").statusCode(200);
        assertThat(cases()).isZero();
    }

    @Test
    void teamCategoryOrGenderPolicyChangesInvalidate() {
        send("/api/core/teams/" + team, "PATCH", "{\"genderPolicy\":\"MALE\"}").statusCode(200).body("playerCount", equalTo(0));
        assertInvalidated("GENDER_POLICY");
    }

    @Test
    void categoryChangesInvalidate() {
        send("/api/core/teams/" + team, "PATCH", "{\"ageCategoryId\":\"" + categories.get("U10") + "\"}").statusCode(200);
        assertInvalidated("CATEGORY_TOO_LOW");
    }

    @Test
    void aLowerMaxAgeInvalidatesPlayersWhoOutgrowTheCategory() {
        UUID tia = RosterDb.playerAged(tenant, "Tia", 13, "FEMALE");
        RosterDb.assignment(tenant, team, tia, null);
        send("/api/core/age-categories/" + categories.get("U14"), "PATCH", "{\"maxAge\":11}").statusCode(422);
        send("/api/core/age-categories/" + categories.get("U14"), "PATCH", "{\"name\":\"Under 14\"}").statusCode(200);
        assertThat(cases()).isZero();
        send("/api/core/age-categories/" + categories.get("U14"), "PATCH", "{\"maxAge\":12}").statusCode(200);
        assertThat(RosterDb.text(tenant, "select invalid_reason from core.team_player where player_id = ?", tia))
                .isEqualTo("CATEGORY_TOO_LOW");
        assertThat(RosterDb.text(tenant, "select invalid_reason from core.team_player where player_id = ?", uma)).isNull();
        assertThat(cases()).isEqualTo(1);
    }

    @Test
    void aLaterReferenceYearMakesPlayersOlder() {
        send("/api/core/seasons/" + season, "PATCH", "{\"referenceYear\":" + (RosterDb.YEAR + 3) + "}").statusCode(200);
        assertInvalidated("CATEGORY_TOO_LOW");
    }

    private void assertInvalidated(String reason) {
        assertThat(RosterDb.text(tenant, "select invalid_reason from core.team_player where player_id = ?", uma))
                .isEqualTo(reason);
        assertThat(cases()).isEqualTo(1);
        assertThat(RosterDb.playerStatus(tenant, uma)).isEqualTo("ORPHAN");
    }

    private long cases() {
        return CoreDb.count(tenant, "select count(*) from core.eligibility_case where status = 'OPEN'");
    }

    private ValidatableResponse send(String path, String method, String json) {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON).body(json)
                .request(method, path).then();
    }
}
