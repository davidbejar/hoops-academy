package com.hoopsacademy.core.rls;

import static org.assertj.core.api.Assertions.assertThat;

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
 * {@code core.audit_event} is append-only for the application (ASVS 16.4.2): core_app may insert and read its own
 * tenant's rows but never change or delete one; core_platform (tenant lifecycle) may only append. The generic RLS
 * suites cover the tenant isolation itself.
 */
@Tag("rls")
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class AuditEventRlsTest {

    private static final String INSUFFICIENT_PRIVILEGE = "42501";
    private final String tenant = UUID.randomUUID().toString();

    @BeforeEach
    void aTenant() {
        CoreDb.tenant(tenant);
    }

    @Test
    void theAppRoleAppendsAndReadsButNeverRewritesHistory() throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            CoreDb.bindTenant(app, TenantId.parse(tenant));
            assertThat(sqlState(app, insert(tenant))).isEqualTo("no error");
            CoreDb.update(app, insert(tenant));
            assertThat(count(app, "select count(*) from core.audit_event")).isEqualTo(1);
            assertThat(sqlState(app, "update core.audit_event set action = 'forged'")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(app, "delete from core.audit_event")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(app, "truncate core.audit_event")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            app.rollback();
        }
    }

    @Test
    void thePlatformRoleMayOnlyAppend() throws SQLException {
        try (Connection platform = TestDatabases.openAsPlatform()) {
            platform.setAutoCommit(false);
            assertThat(sqlState(platform, insert(tenant))).isEqualTo("no error");
            assertThat(sqlState(platform, "select count(*) from core.audit_event")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(platform, "update core.audit_event set action = 'x'")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(platform, "delete from core.audit_event")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            platform.rollback();
        }
    }

    private static String insert(String tenant) {
        return "insert into core.audit_event (id, tenant_id, actor_sub, action, target_type, target_id) values ('"
                + UUID.randomUUID() + "', '" + tenant + "', 'someone', 'member.invited', 'person', 'p-1')";
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
