package com.hoopsacademy.core.adapters.in.platform;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
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
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * WP96 (decisions 67 and 68, ADR-0048): the super admin exports the audit trail of one or every academy as CSV, with
 * the names of the JSON list (academies and their active administrators), recorded in each exported academy's trail.
 * Rows of other tests share the database, so each test works in its own time window.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = "platform-admin", roles = "super_admin")
class PlatformAuditEventExportTest {

    private static final String EXPORT = "/platform/audit-events:export";
    private static final ObjectMapper JSON = new ObjectMapper();

    private Instant t0;
    private String academyA;
    private String academyB;

    @BeforeEach
    void twoAcademies() {
        t0 = Instant.parse("2001-01-01T00:00:00Z").plus(ThreadLocalRandom.current().nextLong(1, 3_000_000),
                ChronoUnit.MINUTES);
        academyA = Members.newTenant();
        academyB = Members.newTenant();
        RosterDb.timezone(academyB, "Asia/Jakarta");
    }

    @Test
    void oneAcademysFileNamesItsAdministratorsAndShowsTheLogins() throws Exception {
        UUID admin = CoreDb.person(academyA, "Ada", "Admin", "ada@example.com", TenantRole.ADMIN);
        UUID coach = CoreDb.person(academyA, "Cora", "Coach", "cora@example.com", TenantRole.COACH);
        CoreDb.auditEvent(academyA, t0, "ada", admin, "member.invited", "person", coach, "{}");
        CoreDb.auditEvent(academyB, t0, "x", null, "tenant.created", "tenant", academyB, "{}");

        Response response = window("tenantId", academyA);

        response.then().statusCode(200).header("Cache-Control", "no-store").header("Content-Disposition",
                "attachment; filename=\"hoops-" + slug(academyA) + "-audit-" + RosterDb.TODAY
                        .format(DateTimeFormatter.BASIC_ISO_DATE) + ".csv\"");
        List<String> lines = lines(response);
        assertThat(lines.get(0)).isEqualTo("Academy,Academy id,Date,Time,Time zone,Action,Action code,Actor,"
                + "Actor name,Actor person id,Actor login,Target,Target id,Target name,Details");
        assertThat(lines).hasSize(2);
        String local = t0.atZone(java.time.ZoneId.of("Europe/Madrid")).format(DateTimeFormatter.ofPattern(
                "yyyy-MM-dd,HH:mm"));
        assertThat(lines.get(1)).isEqualTo(name(academyA) + "," + academyA + "," + local + ",Europe/Madrid,"
                + "Member invited,member.invited,Academy member,Ada Admin," + admin + ",ada,Person," + coach + ",,");

        Map<String, String> audit = CoreDb.auditRow(academyA, "audit.exported");
        assertThat(audit.get("actorSub")).isEqualTo("platform-admin");
        assertThat(audit.get("actorPersonId")).isNull();
        assertThat(audit.get("targetId")).isEqualTo(academyA);
        assertThat(JSON.readTree(audit.get("metadata")).get("rows").asInt()).isEqualTo(1);
        assertThat(CoreDb.auditActions(academyB)).doesNotContain("audit.exported");
    }

    @Test
    void everyAcademysFileUsesEachRowsZoneAndIsRecordedInEachAcademy() throws Exception {
        CoreDb.auditEvent(academyA, t0, "x", null, "tenant.created", "tenant", academyA, "{}");
        CoreDb.auditEvent(academyB, t0.plusSeconds(1), "x", null, "tenant.created", "tenant", academyB, "{}");
        CoreDb.auditEvent(academyB, t0.plusSeconds(2), "x", null, "tenant.logo_removed", "tenant", academyB, "{}");

        Response response = window();
        response.then().header("Content-Disposition", "attachment; filename=\"hoops-platform-audit-"
                + LocalDate.now(ZoneOffset.UTC).format(DateTimeFormatter.BASIC_ISO_DATE) + ".csv\"");
        List<String> lines = lines(response);

        assertThat(lines).hasSize(4);
        assertThat(lines.get(1)).startsWith(name(academyB) + "," + academyB + ",").contains(",Asia/Jakarta,");
        assertThat(lines.get(3)).startsWith(name(academyA) + "," + academyA + ",").contains(",Europe/Madrid,");
        assertThat(JSON.readTree(CoreDb.auditRow(academyA, "audit.exported").get("metadata")).get("rows").asInt())
                .isEqualTo(1);
        assertThat(JSON.readTree(CoreDb.auditRow(academyB, "audit.exported").get("metadata")).get("rows").asInt())
                .isEqualTo(2);
    }

    @Test
    void theHeaderFollowsTheLanguageAndAnUnknownAcademyIsNotFound() {
        Response spanish = request().header("Accept-Language", "es").queryParam("tenantId", academyA)
                .queryParam("from", t0.toString()).get(EXPORT);

        assertThat(lines(spanish).get(0)).startsWith("Academia,Id de la academia,Fecha,Hora,Zona horaria,");
        request().queryParam("tenantId", UUID.randomUUID().toString()).get(EXPORT).then().statusCode(404);
    }

    @Test
    @TestSecurity(user = "academy-admin", roles = "user")
    void academyUsersAreForbidden() {
        request().get(EXPORT).then().statusCode(403);
    }

    @Test
    @TestSecurity
    void anonymousCallersAreUnauthorized() {
        request().get(EXPORT).then().statusCode(401);
    }

    private Response window(String... query) {
        RequestSpecification spec = request().queryParam("from", t0.toString())
                .queryParam("to", t0.plus(1, ChronoUnit.MINUTES).toString());
        for (int i = 0; i < query.length; i += 2) {
            spec = spec.queryParam(query[i], query[i + 1]);
        }
        return spec.get(EXPORT);
    }

    private static RequestSpecification request() {
        return given().filter(Contract.CORE).urlEncodingEnabled(false);
    }

    private static List<String> lines(Response response) {
        String csv = new String(response.then().statusCode(200).extract().asByteArray(), StandardCharsets.UTF_8);
        assertThat(csv).startsWith("﻿");
        return List.of(csv.substring(1).split("\r\n"));
    }

    private static String name(String tenant) {
        return RosterDb.text(tenant, "select name from core.tenant where id = ?::uuid", tenant);
    }

    private static String slug(String tenant) {
        return RosterDb.text(tenant, "select slug from core.tenant where id = ?::uuid", tenant);
    }
}
