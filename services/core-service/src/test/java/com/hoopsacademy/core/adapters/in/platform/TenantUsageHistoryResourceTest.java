package com.hoopsacademy.core.adapters.in.platform;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.TestDatabases;
import com.hoopsacademy.core.testsupport.UsageStubs;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** {@code GET /platform/tenants/{id}/usage/history}: the daily snapshots of one tenant, ascending, in a date range. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = "platform-admin", roles = "super_admin")
class TenantUsageHistoryResourceTest {

    private static final LocalDate TODAY = LocalDate.now(ZoneOffset.UTC);

    @InjectWireMock
    WireMockServer peers;

    private String tenant;

    @BeforeEach
    void aTenantWithThreeDailySnapshots() {
        KeycloakStubs.installDefaults(peers);
        UsageStubs.bothAnswer(peers);
        tenant = Members.newTenant();
        snapshot(tenant, TODAY.minusDays(40), "[]");
        snapshot(tenant, TODAY.minusDays(2), "[\"game\"]");
        snapshot(tenant, TODAY.minusDays(1), "[]");
        snapshot(Members.newTenant(), TODAY.minusDays(1), "[]");
    }

    private io.restassured.response.ValidatableResponse history(String query) {
        return given().filter(Contract.CORE).get("/platform/tenants/" + tenant + "/usage/history" + query).then();
    }

    @Test
    void listsTheTenantsSnapshotsOfTheLast90DaysAscending() {
        history("").statusCode(200)
                .body("tenantId", equalTo(tenant))
                .body("from", equalTo(TODAY.minusDays(89).toString()))
                .body("to", equalTo(TODAY.toString()))
                .body("snapshots.date", contains(TODAY.minusDays(40).toString(), TODAY.minusDays(2).toString(),
                        TODAY.minusDays(1).toString()))
                .body("snapshots[1].unavailableServices", contains("game"))
                .body("snapshots[0].services[0].service", equalTo("core"))
                .body("snapshots[0].services[0].counters.members", equalTo(3));
    }

    @Test
    void theRangeIsInclusiveAndIncludesTheSnapshotWrittenByTheLiveUsageCall() {
        given().filter(Contract.CORE).get("/platform/tenants/" + tenant + "/usage").then().statusCode(200);

        history("?from=" + TODAY.minusDays(1) + "&to=" + TODAY).statusCode(200)
                .body("snapshots.date", contains(TODAY.minusDays(1).toString(), TODAY.toString()));
        history("?from=" + TODAY.minusDays(30) + "&to=" + TODAY.minusDays(3)).statusCode(200)
                .body("snapshots", empty());
        history("?to=" + TODAY.minusDays(2)).statusCode(200)
                .body("from", equalTo(TODAY.minusDays(91).toString()))
                .body("snapshots", hasSize(2));
    }

    @Test
    void invalidRangesAreBadRequests() {
        history("?from=" + TODAY + "&to=" + TODAY.minusDays(1)).statusCode(400);
        history("?from=" + TODAY.minusDays(400) + "&to=" + TODAY).statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).get("/platform/tenants/" + tenant + "/usage/history?from=yesterday")
                .then().statusCode(400);
    }

    @Test
    void unknownTenantsAreNotFound() {
        given().filter(Contract.CORE).get("/platform/tenants/" + UUID.randomUUID() + "/usage/history").then().statusCode(404);
    }

    @Test
    @TestSecurity(user = "academy-admin", roles = "user")
    void tenantUsersAreForbidden() {
        history("").statusCode(403);
    }

    @Test
    @TestSecurity
    void anonymousCallersAreUnauthorized() {
        history("").statusCode(401);
    }

    /** A stored report as the snapshot job writes it (TenantUsageDto JSON), collected at noon UTC of {@code day}. */
    private static void snapshot(String tenant, LocalDate day, String unavailable) {
        String report = """
                {"tenantId":"%s","collectedAt":"%sT12:00:00Z","services":[{"tenantId":"%s","service":"core",\
                "collectedAt":"%sT12:00:00Z","counters":{"members":3}}],"unavailableServices":%s}"""
                .formatted(tenant, day, tenant, day, unavailable);
        try (Connection c = TestDatabases.openAsPlatform()) {
            CoreDb.update(c, "insert into core.usage_snapshot (id, tenant_id, collected_at, report) "
                    + "values (?, ?::uuid, ?::timestamptz, ?::jsonb)", UUID.randomUUID(), tenant, day + "T12:00:00Z", report);
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }
}
