package com.hoopsacademy.core.adapters.in.platform;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;

import com.fasterxml.jackson.databind.JsonNode;
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
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * WP81 (decision 59): the roster data written before the outbox publisher (WP67) has no event, so a replica built from
 * the topics would miss it. The super admin's backfill appends one {@code .changed} per live aggregate without an event
 * (every aggregate with {@code force}) through the outbox, idempotently, with an audit row per academy. The rows below
 * are written with plain SQL, as before WP67: no event.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = "platform-admin", roles = "super_admin")
class PlatformEventBackfillTest {

    private static final String BACKFILL = "/platform/events/backfill";

    private String tenant;
    private Map<String, List<String>> aggregates;

    @BeforeEach
    void anAcademyFromBeforeThePublisher() {
        tenant = Members.newTenant();
        UUID season = RosterDb.currentSeason(tenant);
        UUID team = RosterDb.team(tenant, season, "Lions", RosterDb.defaultCategories(tenant).get("U12"), "MIXED");
        UUID coach = CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH);
        RosterDb.staff(tenant, team, coach, "COACH");
        UUID kidPerson = CoreDb.person(tenant, null, "Leo", "Kid", null, LocalDate.of(2015, 3, 1), "MALE",
                TenantRole.PLAYER);
        UUID player = CoreDb.player(tenant, kidPerson);
        UUID assignment = RosterDb.assignment(tenant, team, player, "7");
        UUID parent = CoreDb.person(tenant, "Pam", "Parent", null, TenantRole.PARENT);
        UUID link = CoreDb.guardianLink(tenant, parent, player);
        aggregates = Map.of(
                "core.tenant", List.of(tenant),
                "core.person", List.of(coach.toString(), kidPerson.toString(), parent.toString()),
                "core.player", List.of(player.toString()),
                "core.team", List.of(team.toString()),
                "core.team-player", List.of(assignment.toString()),
                "core.team-staff", List.of(RosterEvents.teamStaffId(team, coach).toString()),
                "core.guardian-link", List.of(link.toString()));
        assertThat(RosterEvents.count(tenant)).as("written before the publisher: no event").isZero();
    }

    @Test
    void appendsOneChangedEventPerAggregateWithoutAnEventAndNothingTheSecondTime() {
        backfill("{\"tenantId\":\"" + tenant + "\"}").body("tenants", equalTo(1)).body("failed", equalTo(0))
                .body("force", equalTo(false)).body("appended", equalTo(9))
                .body("appendedByTopic.'core.person'", equalTo(3)).body("appendedByTopic.'core.player'", equalTo(1))
                .body("appendedByTopic.'core.tenant'", equalTo(1));

        aggregates.forEach((topic, ids) -> {
            List<JsonNode> events = RosterEvents.of(tenant, topic);
            assertThat(events).as(topic).extracting(event -> event.get("aggregateId").asText())
                    .containsExactlyInAnyOrderElementsOf(ids);
            assertThat(events).as(topic).allSatisfy(event -> {
                assertThat(event.get("type").asText()).endsWith(".changed");
                RosterEvents.assertValid(topic, event);
            });
        });
        assertThat(CoreDb.auditActions(tenant)).containsExactly("tenant.events_backfilled");
        Map<String, String> audit = CoreDb.auditRow(tenant, "tenant.events_backfilled");
        assertThat(audit).containsEntry("targetType", "tenant").containsEntry("targetId", tenant);
        assertThat(audit.get("metadata")).contains("\"force\": false", "\"events\": 9", "core.guardian-link");

        backfill("{\"tenantId\":\"" + tenant + "\"}").body("appended", equalTo(0));

        assertThat(RosterEvents.count(tenant)).as("idempotent: nothing new").isEqualTo(9);
        assertThat(CoreDb.auditActions(tenant)).as("no audit row for a run that appended nothing").hasSize(1);
    }

    @Test
    void anAggregateThatHasAnEventAlreadyIsLeftAloneUnlessForced() {
        backfill("{\"tenantId\":\"" + tenant + "\"}");
        UUID latecomer = CoreDb.person(tenant, "Lou", "Late", null, TenantRole.COACH);

        backfill("{\"tenantId\":\"" + tenant + "\"}").body("appended", equalTo(1))
                .body("appendedByTopic.'core.person'", equalTo(1));
        assertThat(RosterEvents.of(tenant, "core.person", latecomer)).hasSize(1);

        backfill("{\"tenantId\":\"" + tenant + "\",\"force\":true}").body("force", equalTo(true))
                .body("appended", equalTo(10));

        aggregates.forEach((topic, ids) -> ids.forEach(id -> assertThat(
                RosterEvents.of(tenant, topic).stream().filter(event -> event.get("aggregateId").asText().equals(id)))
                .as("%s %s: once by the first run, once forced (the player once, not again with its person)", topic, id)
                .hasSize(2)));
    }

    @Test
    void withoutATenantEveryAcademyIsBackfilled() {
        String other = Members.newTenant();
        UUID otherTeam = RosterDb.team(other, RosterDb.currentSeason(other), "Cubs",
                RosterDb.defaultCategories(other).get("U12"), "MIXED");

        backfill("{}").body("tenants", greaterThanOrEqualTo(2)).body("appended", greaterThanOrEqualTo(12));

        assertThat(RosterEvents.of(tenant, "core.team")).hasSize(1);
        assertThat(RosterEvents.of(other, "core.team", otherTeam)).hasSize(1);
        assertThat(RosterEvents.of(other, "core.tenant")).hasSize(1);
    }

    @Test
    void anUnknownAcademyIsNotFound() {
        given().filter(Contract.CORE).contentType(ContentType.JSON)
                .body("{\"tenantId\":\"" + UUID.randomUUID() + "\"}").post(BACKFILL).then().statusCode(404)
                .contentType("application/problem+json");
    }

    @Test
    @TestSecurity(user = TenantUser.SUBJECT)
    void onlyTheSuperAdminMayBackfill() {
        given().filter(Contract.CORE).contentType(ContentType.JSON).body("{}").post(BACKFILL).then().statusCode(403);
        assertThat(RosterEvents.count(tenant)).isZero();
    }

    private ValidatableResponse backfill(String body) {
        return given().filter(Contract.CORE).contentType(ContentType.JSON).body(body).post(BACKFILL).then()
                .statusCode(200);
    }
}
