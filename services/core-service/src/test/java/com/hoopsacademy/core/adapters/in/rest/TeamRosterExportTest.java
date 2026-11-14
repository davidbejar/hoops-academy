package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.SecurityEventCapture;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.LogCapture;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * WP96 (decisions 67 and 68, ADR-0048): the team roster with guardians and staff as a CSV file, for ADMIN and the
 * team's COACH only, audited without personal data, never cached and never logged. WP106 (decision 83): the team's
 * CURRENT coach only; a former coach of an ended season keeps its screens (ADR-0042) but not the export.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class TeamRosterExportTest {

    private static final String BOM = "﻿";

    private String tenant;
    private UUID season;
    private Map<String, UUID> categories;
    private UUID lions;
    private UUID coach;
    private UUID assistant;
    private UUID uma;

    @BeforeEach
    void aTeamWithPlayersGuardiansAndStaff() {
        tenant = Members.newTenant();
        season = RosterDb.currentSeason(tenant);
        categories = RosterDb.defaultCategories(tenant);
        lions = RosterDb.team(tenant, season, "U12 Lions", categories.get("U12"), "MIXED");
        coach = CoreDb.person(tenant, "Cora", "Coach", "cora@example.com", TenantRole.COACH);
        assistant = CoreDb.person(tenant, "Ana", "Assist", null, TenantRole.ASSISTANT_COACH);
        RosterDb.staff(tenant, lions, coach, "COACH");
        RosterDb.staff(tenant, lions, assistant, "ASSISTANT_COACH");
        uma = RosterDb.player(tenant, "Uma", "Ant", LocalDate.of(RosterDb.YEAR - 11, 6, 15), "FEMALE");
        UUID ben = RosterDb.player(tenant, "Ben", "Bee", LocalDate.of(RosterDb.YEAR - 11, 1, 2), "MALE");
        UUID gina = CoreDb.person(tenant, "Gina", "Ant", "gina@example.com", TenantRole.PARENT);
        UUID gus = CoreDb.person(tenant, "Gus", "Ant", null, TenantRole.PARENT);
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.person set phone = '=1+2' where id = ?", gina));
        CoreDb.guardianLink(tenant, gina, uma);
        CoreDb.guardianLink(tenant, gus, uma);
        RosterDb.assignment(tenant, lions, uma, "7");
        UUID invalid = RosterDb.assignment(tenant, lions, ben, null);
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.team_player set invalidated_at = now(), "
                + "invalid_reason = 'CATEGORY_TOO_LOW' where id = ?", invalid));
        UUID gone = RosterDb.player(tenant, "Gil", "Gone", LocalDate.of(RosterDb.YEAR - 11, 1, 2), "MALE");
        UUID closed = RosterDb.assignment(tenant, lions, gone, "9");
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.team_player set left_on = joined_on where id = ?",
                closed));
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void anAdminDownloadsTheRosterWithGuardiansAndStaff() {
        Response response = export(lions, null);

        response.then().statusCode(200).header("Cache-Control", "no-store")
                .header("Content-Disposition", "attachment; filename=\"hoops-" + slug() + "-roster-u12-lions-"
                        + today() + ".csv\"");
        assertThat(response.contentType().toLowerCase(java.util.Locale.ROOT).replace(" ", ""))
                .isEqualTo("text/csv;charset=utf-8");
        String csv = new String(response.asByteArray(), StandardCharsets.UTF_8);
        assertThat(csv).startsWith(BOM).endsWith("\r\n");
        List<String> lines = List.of(csv.substring(1).split("\r\n"));
        assertThat(lines.get(0)).isEqualTo("Role,Given name,Family name,Birth date,Gender,Age category,Eligibility,"
                + "Play-up levels,Jersey number,Joined on,E-mail,Phone,Guardian 1 given name,Guardian 1 family name,"
                + "Guardian 1 e-mail,Guardian 1 phone,Guardian 2 given name,Guardian 2 family name,Guardian 2 e-mail,"
                + "Guardian 2 phone");
        String joined = RosterDb.TODAY.minusDays(30).toString();
        assertThat(lines.subList(1, lines.size())).containsExactly(
                "Player,Uma,Ant," + (RosterDb.YEAR - 11) + "-06-15,Female,U12,Eligible,0,7," + joined
                        + ",,,Gina,Ant,gina@example.com,'=1+2,Gus,Ant,,",
                "Player,Ben,Bee," + (RosterDb.YEAR - 11) + "-01-02,Male,U12,Not eligible,0,," + joined + ",,,,,,,,,,",
                "Coach,Cora,Coach,,,,,,," + RosterDb.TODAY + ",cora@example.com,,,,,,,,,",
                "Assistant coach,Ana,Assist,,,,,,," + RosterDb.TODAY + ",,,,,,,,,,");
    }

    @Test
    void theHeaderFollowsTheCallersLanguage() {
        String csv = new String(export(lions, "es-ES, en;q=0.5").then().statusCode(200).extract().asByteArray(),
                StandardCharsets.UTF_8);

        assertThat(csv).startsWith(BOM + "Rol,Nombre,Apellidos,").contains("\r\nJugador,Uma,Ant,")
                .contains(",Femenino,").contains("\r\nEntrenador,Cora,");
    }

    @Test
    void everyExportIsAuditedWithTheRowCountOnly() {
        export(lions, null).then().statusCode(200);

        Map<String, String> row = CoreDb.auditRow(tenant, "team.roster_exported");
        assertThat(row.get("targetType")).isEqualTo("team");
        assertThat(row.get("targetId")).isEqualTo(lions.toString());
        assertThat(row.get("actorSub")).isEqualTo(TenantUser.SUBJECT);
        assertThat(row.get("metadata")).isEqualTo("{\"rows\": 4}");
    }

    @Test
    void theContentIsNeverLogged() {
        try (LogCapture logs = LogCapture.start()) {
            export(lions, null).then().statusCode(200);

            assertThat(logs.containing("gina@example.com")).isEmpty();
            assertThat(logs.containing("Gina")).isEmpty();
        }
    }

    /**
     * roles, relation to the team (current staff, former staff of an ended season, none), expected status (authz
     * matrix row "Export the team roster").
     */
    static Stream<Arguments> callers() {
        return Stream.of(
                Arguments.of(EnumSet.of(TenantRole.ADMIN), Relation.NONE, 200),
                Arguments.of(EnumSet.of(TenantRole.COACH), Relation.STAFF, 200),
                Arguments.of(EnumSet.of(TenantRole.COACH), Relation.NONE, 403),
                Arguments.of(EnumSet.of(TenantRole.COACH), Relation.FORMER, 403),
                Arguments.of(EnumSet.of(TenantRole.ASSISTANT_COACH), Relation.STAFF, 403),
                Arguments.of(EnumSet.of(TenantRole.ASSISTANT_COACH), Relation.FORMER, 403),
                Arguments.of(EnumSet.of(TenantRole.PARENT), Relation.NONE, 403),
                Arguments.of(EnumSet.of(TenantRole.PLAYER), Relation.NONE, 403),
                Arguments.of(EnumSet.of(TenantRole.ADMIN, TenantRole.COACH), Relation.NONE, 200),
                Arguments.of(EnumSet.of(TenantRole.ADMIN, TenantRole.COACH), Relation.FORMER, 200),
                Arguments.of(EnumSet.of(TenantRole.COACH, TenantRole.PARENT), Relation.STAFF, 200),
                Arguments.of(EnumSet.of(TenantRole.COACH, TenantRole.PARENT), Relation.FORMER, 403),
                Arguments.of(EnumSet.of(TenantRole.ASSISTANT_COACH, TenantRole.PARENT), Relation.STAFF, 403));
    }

    enum Relation { NONE, STAFF, FORMER }

    @ParameterizedTest
    @MethodSource("callers")
    void roleMatrix(Set<TenantRole> roles, Relation relation, int expected) {
        Members.signInAs(tenant, coach, roles, relation == Relation.STAFF ? Set.of(lions) : Set.of(),
                relation == Relation.FORMER ? Set.of(lions) : Set.of());

        export(lions, null).then().statusCode(expected);

        long audited = CoreDb.auditActions(tenant).stream().filter("team.roster_exported"::equals).count();
        assertThat(audited).isEqualTo(expected == 200 ? 1 : 0);
    }

    @Test
    void theFormerCoachOfAnEndedSeasonNoLongerExportsItsRosterButTheAdminDoes() {
        UUID last = RosterDb.season(tenant, "Last", RosterDb.TODAY.minusDays(400), RosterDb.TODAY.minusDays(100),
                RosterDb.YEAR - 1);
        UUID oldLions = RosterDb.team(tenant, last, "Old Lions", categories.get("U12"), "MIXED");
        RosterDb.staff(tenant, oldLions, coach, "COACH");
        Members.signInAs(tenant, coach, EnumSet.of(TenantRole.COACH), Set.of(), Set.of(oldLions));

        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            export(oldLions, null).then().statusCode(403);

            assertThat(events.single())
                    .containsEntry("security.kind", "fine_grained")
                    .containsEntry("security.outcome", "403")
                    .containsEntry("tenantId", tenant)
                    .containsEntry("security.resource", "GET /api/core/teams/{teamId}/roster:export");
        }
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("team.roster_exported");

        Members.signIn(tenant, TenantRole.ADMIN);
        export(oldLions, null).then().statusCode(200);
    }

    @Test
    void aNonMemberGetsNotFoundNeverForbidden() {
        Members.signIn(Members.newTenant(), TenantRole.ADMIN, TenantRole.COACH);

        export(lions, null).then().statusCode(404);
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("team.roster_exported");
    }

    @Test
    void unknownAndOtherAcademiesTeamsAreNotFound() {
        export(UUID.randomUUID(), null).then().statusCode(404);
        String other = Members.newTenant();
        Members.signIn(other, TenantRole.ADMIN);

        given().filter(Contract.CORE).urlEncodingEnabled(false).header("X-Tenant-Id", other)
                .get("/api/core/teams/" + lions + "/roster:export").then().statusCode(404);
        assertThat(CoreDb.auditActions(other)).doesNotContain("team.roster_exported");
    }

    private Response export(UUID team, String language) {
        RequestSpecification request = given().filter(Contract.CORE).urlEncodingEnabled(false)
                .header("X-Tenant-Id", tenant);
        if (language != null) {
            request = request.header("Accept-Language", language);
        }
        return request.get("/api/core/teams/" + team + "/roster:export");
    }

    private String slug() {
        return RosterDb.text(tenant, "select slug from core.tenant where id = ?::uuid", tenant);
    }

    private static String today() {
        return RosterDb.TODAY.format(DateTimeFormatter.BASIC_ISO_DATE);
    }
}
