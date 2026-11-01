package com.hoopsacademy.athlete.application;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.adapters.out.client.CoreRosterAdapter;
import com.hoopsacademy.athlete.domain.TrainingSession;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** The nightly job iterates the tenant registry and fills each tenant's horizon in that tenant's time zone. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class NightlyMaterialisationTest {

    static final String JAKARTA_TENANT = "56000000-0000-4000-8000-000000000001";
    static final String MADRID_TENANT = "56000000-0000-4000-8000-000000000002";
    static final String TEAM_J = "56000000-0000-4000-8000-0000000000a1";
    static final String TEAM_M = "56000000-0000-4000-8000-0000000000a2";

    @Inject NightlyMaterialisation nightly;
    @Inject TenantRegistry registry;
    @Inject TenantScope tenantScope;
    @Inject SessionRepository sessions;
    @Inject CoreRosterAdapter rosterAdapter;
    @Inject com.hoopsacademy.athlete.adapters.in.job.NightlyMaterialisationJob nightlyJob;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
    }

    private List<TrainingSession> sessionsOf(String tenant, String team) {
        return tenantScope.runAs(TenantId.parse(tenant), () -> sessions.list(new SessionQuery(
                java.util.Set.of(new com.hoopsacademy.athlete.domain.TeamId(java.util.UUID.fromString(team))),
                Instant.parse("2000-01-01T00:00:00Z"), Instant.parse("2100-01-01T00:00:00Z"), java.util.Optional.empty(), 0, 200)).items());
    }

    private void wipeSessions(String tenant, String team) {
        tenantScope.runAs(TenantId.parse(tenant), () -> sessions.delete(sessionsOf(tenant, team).stream().map(TrainingSession::id).toList()));
    }

    @Test
    @TenantUser(tenant = JAKARTA_TENANT, roles = TenantRole.ADMIN, timezone = "Asia/Jakarta")
    void scheduleCreationRegistersTheTenantWithTheZoneOfTheCallersAuthzContext() {
        core.roster(JAKARTA_TENANT, TEAM_J);

        api(JAKARTA_TENANT).body(Map.of("teamId", TEAM_J, "dayOfWeek", "MONDAY", "startTime", "18:00", "durationMinutes", 60,
                "validFrom", LocalDate.now(ZoneId.of("Asia/Jakarta")).toString())).post("/api/athlete/training-schedules")
                .then().statusCode(201);

        assertThat(registry.zoneOf(TenantId.parse(JAKARTA_TENANT))).contains(ZoneId.of("Asia/Jakarta"));
        assertThat(registry.tenants()).contains(TenantId.parse(JAKARTA_TENANT));
        assertThat(sessionsOf(JAKARTA_TENANT, TEAM_J)).hasSize(8)
                .allSatisfy(s -> assertThat(s.startsAt().toString()).endsWith("T11:00:00Z")); // 18:00 +07:00
    }

    @Test
    @TenantUser(tenant = MADRID_TENANT, roles = TenantRole.ADMIN)
    void nightlyRunRefillsTheHorizonOfEveryTenantAndIsIdempotent() {
        core.roster(MADRID_TENANT, TEAM_M);
        api(MADRID_TENANT).body(Map.of("teamId", TEAM_M, "dayOfWeek", "TUESDAY", "startTime", "18:00", "durationMinutes", 60,
                "validFrom", LocalDate.now(ZoneId.of("Europe/Madrid")).toString())).post("/api/athlete/training-schedules")
                .then().statusCode(201);
        assertThat(sessionsOf(MADRID_TENANT, TEAM_M)).hasSize(8);
        assertThat(registry.zoneOf(TenantId.parse(MADRID_TENANT))).contains(ZoneId.of("Europe/Madrid"));

        wipeSessions(MADRID_TENANT, TEAM_M);
        assertThat(sessionsOf(MADRID_TENANT, TEAM_M)).isEmpty();

        nightly.run();
        List<TrainingSession> refilled = sessionsOf(MADRID_TENANT, TEAM_M);
        assertThat(refilled).hasSize(8);
        int createdOnSecondRun = nightly.run();

        assertThat(sessionsOf(MADRID_TENANT, TEAM_M)).hasSize(8);
        assertThat(createdOnSecondRun).isZero();
        assertThat(nightlyJob.run()).as("job wrapper ran under the cluster lock").isTrue();
        assertThat(refilled).allSatisfy(s -> assertThat(s.startsAt().atZone(ZoneId.of("Europe/Madrid")).toLocalTime().toString()).isEqualTo("18:00"));
    }

    @Test
    void whileAnotherReplicaHoldsTheMaterialisationLockTheJobSkips() throws Exception {
        try (java.sql.Connection otherReplica = com.hoopsacademy.common.testing.RlsTestDatabase.fromConfig().openAsApp();
                java.sql.PreparedStatement lock = otherReplica.prepareStatement("select pg_advisory_lock(?)")) {
            lock.setLong(1, TenantScope.advisoryKey(com.hoopsacademy.athlete.adapters.in.job.NightlyMaterialisationJob.LOCK));
            lock.execute();

            assertThat(nightlyJob.run()).isFalse();

            // release explicitly: close() frees a session lock only once the backend has exited (can lag)
            try (java.sql.PreparedStatement unlock = otherReplica.prepareStatement("select pg_advisory_unlock(?)")) {
                unlock.setLong(1, TenantScope.advisoryKey(com.hoopsacademy.athlete.adapters.in.job.NightlyMaterialisationJob.LOCK));
                unlock.execute();
            }
        }
        assertThat(nightlyJob.run()).isTrue();
    }
}
