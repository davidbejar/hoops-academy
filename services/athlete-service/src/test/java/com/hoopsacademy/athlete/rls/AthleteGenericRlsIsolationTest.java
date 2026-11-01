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
                        "status", (c, t) -> "PRESENT"));
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
