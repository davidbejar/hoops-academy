package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * WP96 (decisions 67 and 68, ADR-0048): the academy's audit trail as a CSV file with the filters and the masking of
 * the JSON list, recorded as {@code audit.exported}, refused above 10,000 rows.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class AuditEventExportTest {

    private static final String EXPORT = "/api/core/audit-events:export";
    private static final Instant T0 = Instant.parse("2026-03-01T10:00:00Z");
    private static final ObjectMapper JSON = new ObjectMapper();

    private String tenant;
    private UUID admin;
    private UUID coach;

    @BeforeEach
    void academyWithAnAdminAndACoach() {
        tenant = Members.newTenant();
        admin = CoreDb.person(tenant, "Ada", "Admin", "ada@example.com", TenantRole.ADMIN);
        coach = CoreDb.person(tenant, "Cora", "Coach", "cora@example.com", TenantRole.COACH);
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void theFileHoldsTheFilteredRowsInTheAcademysTimeWithThePlatformMasked() {
        UUID invited = event(T0, "admin-sub", admin, "member.invited", "person", coach, "{\"roles\":[\"COACH\"]}");
        event(T0.plusSeconds(60), "platform-admin", null, "tenant.suspended", "tenant", tenant,
                "{\"status\":\"SUSPENDED\",\"reason\":\"=unpaid\"}");
        event(T0.minusSeconds(1), "admin-sub", admin, "member.updated", "person", coach, "{}");

        Response response = export("from", T0.toString(), "to", T0.plusSeconds(120).toString());

        response.then().statusCode(200).header("Cache-Control", "no-store")
                .header("Content-Disposition", "attachment; filename=\"hoops-" + slug() + "-audit-" + today()
                        + ".csv\"");
        List<String> lines = lines(response);
        assertThat(lines).containsExactly(
                "Date,Time,Time zone,Action,Action code,Actor,Actor name,Actor person id,Actor login,Target,"
                        + "Target id,Target name,Details",
                "2026-03-01,11:01,Europe/Madrid,Academy suspended,tenant.suspended,Platform administrator,,,,Academy,"
                        + tenant + "," + academyName() + ",reason==unpaid; status=SUSPENDED",
                "2026-03-01,11:00,Europe/Madrid,Member invited,member.invited,Academy member,Ada Admin," + admin
                        + ",admin-sub,Person," + coach + ",Cora Coach,roles=[COACH]");
        assertThat(String.join("\n", lines)).doesNotContain("platform-admin").doesNotContain(invited.toString());
    }

    @Test
    void theActionFilterAndTheLanguageApply() {
        event(T0, "admin-sub", admin, "member.invited", "person", coach, "{}");
        event(T0.plusSeconds(1), "admin-sub", admin, "member.updated", "person", coach, "{\"fields\":[\"phone\"]}");

        List<String> lines = lines(exportIn("id", "action", "member.updated", "from", T0.toString()));

        assertThat(lines).hasSize(2);
        assertThat(lines.get(0)).startsWith("Tanggal,");
        assertThat(lines.get(1)).contains(",member.updated,").endsWith(",fields=[phone]");
    }

    @Test
    void everyExportIsAuditedWithItsRowCountAndFilterButNotInItsOwnFile() throws Exception {
        event(T0, "admin-sub", admin, "member.invited", "person", coach, "{}");

        List<String> first = lines(export("action", "member.invited", "action", "audit.exported",
                "from", T0.toString()));
        List<String> second = lines(export("action", "member.invited", "action", "audit.exported",
                "from", T0.toString()));

        assertThat(first).hasSize(2);
        assertThat(second).hasSize(3).anySatisfy(line -> assertThat(line).contains(",audit.exported,"));
        JsonNode metadata = JSON.readTree(CoreDb.auditRow(tenant, "audit.exported").get("metadata"));
        assertThat(metadata.get("rows").asInt()).isEqualTo(2);
        assertThat(metadata.get("from").asText()).isEqualTo(T0.toString());
        assertThat(metadata.has("to")).isFalse();
        assertThat(metadata.get("actions")).hasSize(2);
        assertThat(CoreDb.auditRow(tenant, "audit.exported").get("targetId")).isEqualTo(tenant);
        assertThat(CoreDb.auditRow(tenant, "audit.exported").get("targetType")).isEqualTo("tenant");
    }

    @Test
    void moreThanTenThousandRowsAreRefusedWithAHint() {
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, """
                insert into core.audit_event (id, tenant_id, actor_sub, action, target_type, target_id, metadata, at)
                select gen_random_uuid(), ?, 'bulk', 'member.updated', 'person', ?, '{}'::jsonb,
                       cast(? as timestamptz) + make_interval(secs => n)
                  from generate_series(1, 10001) n""", UUID.fromString(tenant), coach.toString(),
                java.sql.Timestamp.from(T0)));

        export("from", T0.toString()).then().statusCode(422).body("code", equalTo("EXPORT_TOO_LARGE"))
                .body("detail", containsString("10000"));
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("audit.exported");
        export("from", T0.plusSeconds(2).toString()).then().statusCode(200);
    }

    @ParameterizedTest
    @MethodSource("com.hoopsacademy.core.testsupport.Members#roleSetsWithAdminFlag")
    void onlyAdminsExport(Set<TenantRole> roles, boolean admin) {
        Members.signIn(tenant, roles);

        export().then().statusCode(admin ? 200 : 403);
    }

    @Test
    void anotherAcademysRowsNeverAppear() {
        event(T0, "admin-sub", admin, "member.invited", "person", coach, "{}");
        String other = Members.newTenant();
        Members.signIn(other, TenantRole.ADMIN);

        Response response = given().filter(Contract.CORE).urlEncodingEnabled(false).header("X-Tenant-Id", other)
                .get(EXPORT);

        assertThat(lines(response)).hasSize(1);
        given().filter(Contract.CORE).urlEncodingEnabled(false).header("X-Tenant-Id", tenant).get(EXPORT).then()
                .statusCode(404);
    }

    @Test
    @TestSecurity(user = "platform-admin", roles = "super_admin")
    void theSuperAdminWithoutMembershipIsNotFound() {
        export().then().statusCode(404);
    }

    @Test
    void invalidFiltersAreBadRequests() {
        export("from", T0.toString(), "to", T0.toString()).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).urlEncodingEnabled(false).header("X-Tenant-Id", tenant)
                .queryParam("action", "member.hacked").get(EXPORT).then().statusCode(400);
    }

    private Response export(String... query) {
        return exportIn(null, query);
    }

    private Response exportIn(String language, String... query) {
        RequestSpecification request = given().filter(Contract.CORE).urlEncodingEnabled(false)
                .header("X-Tenant-Id", tenant);
        if (language != null) {
            request = request.header("Accept-Language", language);
        }
        for (int i = 0; i < query.length; i += 2) {
            request = request.queryParam(query[i], query[i + 1]);
        }
        return request.get(EXPORT);
    }

    private static List<String> lines(Response response) {
        String csv = new String(response.then().statusCode(200).extract().asByteArray(), StandardCharsets.UTF_8);
        assertThat(csv).startsWith("﻿");
        return List.of(csv.substring(1).split("\r\n"));
    }

    private UUID event(Instant at, String actorSub, UUID actorPerson, String action, String targetType, Object target,
            String metadata) {
        return CoreDb.auditEvent(tenant, at, actorSub, actorPerson, action, targetType, target, metadata);
    }

    private String slug() {
        return RosterDb.text(tenant, "select slug from core.tenant where id = ?::uuid", tenant);
    }

    private String academyName() {
        return RosterDb.text(tenant, "select name from core.tenant where id = ?::uuid", tenant);
    }

    private static String today() {
        return RosterDb.TODAY.format(DateTimeFormatter.BASIC_ISO_DATE);
    }
}
