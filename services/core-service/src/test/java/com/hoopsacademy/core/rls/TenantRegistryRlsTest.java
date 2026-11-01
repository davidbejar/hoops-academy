package com.hoopsacademy.core.rls;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.TestDatabases;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * {@code core.tenant} has no tenant_id (it IS the tenant), so the generic suite skips it: these tests pin its own
 * policies and grants, and the platform role's restricted reach (registry, usage, billing — never tenant content).
 */
@Tag("rls")
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class TenantRegistryRlsTest {

    private static final String INSUFFICIENT_PRIVILEGE = "42501";
    private final String tenantA = UUID.randomUUID().toString();
    private final String tenantB = UUID.randomUUID().toString();

    @BeforeEach
    void twoTenants() {
        CoreDb.tenant(tenantA);
        CoreDb.tenant(tenantB);
    }

    @Test
    void appRoleSeesOnlyTheBoundTenant() throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            CoreDb.bindTenant(app, TenantId.parse(tenantA));
            assertThat(count(app, "select count(*) from core.tenant")).isEqualTo(1);
            assertThat(count(app, "select count(*) from core.tenant where id = '" + tenantB + "'")).isZero();
            app.rollback();
        }
    }

    @Test
    void appRoleWithoutTenantRaises() throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            assertThatThrownBy(() -> count(app, "select count(*) from core.tenant"))
                    .isInstanceOfSatisfying(SQLException.class,
                            e -> assertThat(e.getSQLState()).isEqualTo(INSUFFICIENT_PRIVILEGE));
        }
    }

    @Test
    void appRoleCannotCreateDeleteOrChangeTheStatusOfTenants() throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            CoreDb.bindTenant(app, TenantId.parse(tenantA));
            assertThat(sqlState(app, "update core.tenant set status = 'ACTIVE'")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(app, "delete from core.tenant")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(app, "insert into core.tenant (id, slug, name, timezone, default_locale) values ('"
                    + tenantA + "', 'x-new', 'x', 'UTC', 'en')")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(CoreDb.update(app, "update core.tenant set name = 'Renamed'")).isEqualTo(1);
            app.rollback();
        }
    }

    @Test
    void platformRoleSeesEveryTenantButNoTenantContent() throws SQLException {
        try (Connection platform = TestDatabases.openAsPlatform()) {
            assertThat(count(platform, "select count(*) from core.tenant where id in ('" + tenantA + "', '"
                    + tenantB + "')")).isEqualTo(2);
            for (String table : new String[] {"core.person", "core.membership_role", "core.player",
                    "core.guardian_link", "core.tenant_settings", "core.tenant_logo", "core.app_user",
                    "core.user_membership_index"}) {
                assertThat(sqlState(platform, "select count(*) from " + table))
                        .as("platform must not read %s", table).isEqualTo(INSUFFICIENT_PRIVILEGE);
            }
            assertThat(count(platform, "select count(*) from billing.plan where code = 'FREE'")).isEqualTo(1);
            assertThat(count(platform, "select count(*) from core.usage_snapshot")).isGreaterThanOrEqualTo(0);
        }
    }

    @Test
    void platformRoleMayAppendButNotReadOutboxEvents() throws SQLException {
        try (Connection platform = TestDatabases.openAsPlatform()) {
            assertThat(CoreDb.update(platform, """
                    insert into core.outbox (id, tenant_id, event_type, aggregate_type, aggregate_id, payload)
                    values (gen_random_uuid(), ?, 'tenant.suspended', 'tenant', ?, '{}')""",
                    UUID.fromString(tenantA), tenantA)).isEqualTo(1);
            assertThat(sqlState(platform, "select count(*) from core.outbox")).isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
    }

    private static long count(Connection connection, String sql) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            rs.next();
            return rs.getLong(1);
        }
    }

    private static String sqlState(Connection connection, String sql) throws SQLException {
        var savepoint = connection.getAutoCommit() ? null : connection.setSavepoint();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.execute();
            return "no error";
        } catch (SQLException e) {
            return e.getSQLState();
        } finally {
            if (savepoint != null) {
                connection.rollback(savepoint);
            }
        }
    }
}
