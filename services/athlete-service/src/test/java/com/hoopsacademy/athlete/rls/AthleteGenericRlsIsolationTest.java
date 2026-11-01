package com.hoopsacademy.athlete.rls;

import com.hoopsacademy.common.testing.ColumnFixture;
import com.hoopsacademy.common.testing.GenericRlsIsolationTest;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.TenantId;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;
import java.util.UUID;

/** Tenant A never sees, changes, deletes or inserts into tenant B's rows of any athlete table. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class AthleteGenericRlsIsolationTest extends GenericRlsIsolationTest {

    @Override
    protected Map<String, Map<String, ColumnFixture>> fixtureOverrides() {
        return Map.of(
                "athlete.training_schedule", Map.of(
                        "weekday", (c, t) -> 3,
                        "duration_min", (c, t) -> 60),
                "athlete.training_session", Map.of(
                        "ends_at", (c, t) -> "2026-01-01 13:00:00+00"),
                "athlete.attendance", Map.of(
                        "session_id", AthleteGenericRlsIsolationTest::insertSession,
                        "status", (c, t) -> "PRESENT"),
                "athlete.plan_assignment", Map.of(
                        "plan_id", AthleteGenericRlsIsolationTest::insertPlan,
                        "team_id", (c, t) -> UUID.randomUUID()),
                "athlete.plan_completion", Map.of(
                        "assignment_id", AthleteGenericRlsIsolationTest::insertAssignment,
                        "status", (c, t) -> "DONE"));
    }

    /** A tenant plan of the same tenant, as the composite foreign key of an assignment requires. */
    private static UUID insertPlan(Connection migrator, TenantId tenant) throws SQLException {
        try (PreparedStatement ps = migrator.prepareStatement(
                "insert into athlete.training_plan (id, owner_tenant_id, name) values (gen_random_uuid(), ?, 'Plan') returning id")) {
            ps.setObject(1, tenant.value());
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getObject(1, UUID.class);
            }
        }
    }

    private static UUID insertAssignment(Connection migrator, TenantId tenant) throws SQLException {
        UUID plan = insertPlan(migrator, tenant);
        try (PreparedStatement ps = migrator.prepareStatement(
                "insert into athlete.plan_assignment (id, tenant_id, plan_id, team_id, due_on, assigned_by_person_id, assigned_by_name) "
                        + "values (gen_random_uuid(), ?, ?, gen_random_uuid(), '2026-01-01', gen_random_uuid(), 'x') returning id")) {
            ps.setObject(1, tenant.value());
            ps.setObject(2, plan);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getObject(1, UUID.class);
            }
        }
    }

    /** A parent session in the same tenant, as the composite foreign key requires. */
    private static UUID insertSession(Connection migrator, TenantId tenant) throws SQLException {
        try (PreparedStatement ps = migrator.prepareStatement(
                "insert into athlete.training_session (id, tenant_id, team_id, starts_at, ends_at) "
                        + "values (gen_random_uuid(), ?, gen_random_uuid(), now(), now() + interval '1 hour') returning id")) {
            ps.setObject(1, tenant.value());
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getObject(1, UUID.class);
            }
        }
    }
}
