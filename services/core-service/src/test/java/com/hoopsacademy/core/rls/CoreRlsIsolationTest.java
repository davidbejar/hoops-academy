package com.hoopsacademy.core.rls;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.testing.ColumnFixture;
import com.hoopsacademy.common.testing.GenericRlsIsolationTest;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class CoreRlsIsolationTest extends GenericRlsIsolationTest {

    @Override
    protected List<String> schemas() {
        return List.of("core", "billing");
    }

    @Override
    protected Map<String, Map<String, ColumnFixture>> fixtureOverrides() {
        return Map.of(
                "core.tenant_settings", Map.of("age_rule", CoreRlsIsolationTest::tenantRowThenAgeRule),
                "core.tenant_logo", Map.of("content_type", (c, t) -> "image/png"),
                "core.membership_role", Map.of("person_id", CoreRlsIsolationTest::person, "role", (c, t) -> "COACH"),
                "core.player", Map.of("person_id", CoreRlsIsolationTest::person),
                "core.guardian_link", Map.of(
                        "guardian_person_id", CoreRlsIsolationTest::person,
                        "player_id", CoreRlsIsolationTest::player),
                "core.user_membership_index", Map.of("person_id", CoreRlsIsolationTest::person),
                "billing.tenant_subscription", Map.of("plan_code", (c, t) -> "FREE"));
    }

    /** tenant_settings.tenant_id references the registry: create the tenant row first. */
    private static Object tenantRowThenAgeRule(Connection migrator, TenantId tenant) throws SQLException {
        CoreDb.insertTenantRow(migrator, tenant.value(), "ACTIVE");
        return "BIRTH_YEAR";
    }

    private static Object person(Connection migrator, TenantId tenant) throws SQLException {
        return insertReturningId(migrator,
                "insert into core.person (id, tenant_id, given_name, family_name) values (?, ?, 'Fix', 'Ture')",
                tenant);
    }

    private static Object player(Connection migrator, TenantId tenant) throws SQLException {
        Object personId = person(migrator, tenant);
        UUID id = UUID.randomUUID();
        CoreDb.update(migrator, "insert into core.player (id, tenant_id, person_id) values (?, ?, ?)",
                id, tenant.value(), personId);
        return id;
    }

    private static Object insertReturningId(Connection migrator, String sql, TenantId tenant) throws SQLException {
        UUID id = UUID.randomUUID();
        try (PreparedStatement statement = migrator.prepareStatement(sql + " returning id")) {
            statement.setObject(1, id);
            statement.setObject(2, tenant.value());
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getObject(1);
            }
        }
    }
}
