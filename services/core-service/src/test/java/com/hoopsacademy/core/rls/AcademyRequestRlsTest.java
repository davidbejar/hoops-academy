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
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * {@code core.academy_request} (V17, ADR-0044) belongs to no tenant: only core_platform reads and writes it, the
 * requester's data is immutable, nobody deletes, an academy name is held by one open request at a time.
 */
@Tag("rls")
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class AcademyRequestRlsTest {

    private static final String INSUFFICIENT_PRIVILEGE = "42501";
    private static final String UNIQUE_VIOLATION = "23505";
    private static final String CHECK_VIOLATION = "23514";

    @Test
    void theAppRoleCannotReadOrWriteRequestsEvenInsideATenant() throws SQLException {
        UUID request = insertPending("App Hidden " + UUID.randomUUID());
        String tenant = UUID.randomUUID().toString();
        CoreDb.tenant(tenant);
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            CoreDb.bindTenant(app, TenantId.parse(tenant));
            assertThat(sqlState(app, "select count(*) from core.academy_request")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(app, "update core.academy_request set status = 'REJECTED' where id = '" + request
                    + "'")).isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(app, insertSql(UUID.randomUUID(), "App Insert"))).isEqualTo(INSUFFICIENT_PRIVILEGE);
            app.rollback();
        }
    }

    @Test
    void thePlatformRoleDecidesButNeverRewritesTheRequesterOrDeletes() throws SQLException {
        UUID request = insertPending("Platform Decides " + UUID.randomUUID());
        try (Connection platform = TestDatabases.openAsPlatform()) {
            platform.setAutoCommit(false);
            assertThat(sqlState(platform, "update core.academy_request set status = 'REJECTED', decided_at = now(), "
                    + "decided_by = 'sub', reason = 'no', notified_at = now() where id = '" + request + "'"))
                    .isEqualTo("no error");
            for (String column : new String[] {"email = 'x@example.com'", "academy_name = 'Other'",
                    "requester_name = 'X'", "requester_role = 'ADMIN'", "locale = 'es'", "requested_at = now()"}) {
                assertThat(sqlState(platform, "update core.academy_request set " + column + " where id = '"
                        + request + "'")).as(column).isEqualTo(INSUFFICIENT_PRIVILEGE);
            }
            assertThat(sqlState(platform, "delete from core.academy_request where id = '" + request + "'"))
                    .isEqualTo(INSUFFICIENT_PRIVILEGE);
            platform.rollback();
        }
    }

    @Test
    void aDecisionMustBeComplete() throws SQLException {
        UUID request = insertPending("Complete Decision " + UUID.randomUUID());
        try (Connection platform = TestDatabases.openAsPlatform()) {
            platform.setAutoCommit(false);
            assertThat(sqlState(platform, "update core.academy_request set status = 'REJECTED' where id = '"
                    + request + "'")).isEqualTo(CHECK_VIOLATION);
            assertThat(sqlState(platform, "update core.academy_request set status = 'ACCEPTED', decided_at = now(), "
                    + "decided_by = 'sub' where id = '" + request + "'")).isEqualTo(CHECK_VIOLATION);
            platform.rollback();
        }
    }

    @Test
    void anOpenRequestHoldsItsNameCaseAndSpacingInsensitivelyUntilRejected() throws SQLException {
        String name = "Hold Name " + UUID.randomUUID();
        UUID first = insertPending(name);
        try (Connection platform = TestDatabases.openAsPlatform()) {
            assertThat(sqlState(platform, insertSql(UUID.randomUUID(), "  " + name.toUpperCase().replace(" ", "   ")
                    + " "))).isEqualTo(UNIQUE_VIOLATION);
            CoreDb.update(platform, "update core.academy_request set status = 'REJECTED', decided_at = now(), "
                    + "decided_by = 'sub', reason = 'no' where id = ?", first);
            assertThat(sqlState(platform, insertSql(UUID.randomUUID(), name))).isEqualTo("no error");
        }
    }

    @Test
    void theNameKeyComparesRegistryAndRequestsTheSameWay() throws SQLException {
        try (Connection platform = TestDatabases.openAsPlatform();
                PreparedStatement statement = platform.prepareStatement(
                        "select core.academy_name_key(?) = core.academy_name_key(?)")) {
            statement.setString(1, " Club  Norte\t");
            statement.setString(2, "club norte");
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                assertThat(rs.getBoolean(1)).isTrue();
            }
        }
    }

    private static UUID insertPending(String academyName) throws SQLException {
        UUID id = UUID.randomUUID();
        try (Connection platform = TestDatabases.openAsPlatform()) {
            assertThat(sqlState(platform, insertSql(id, academyName))).isEqualTo("no error");
        }
        return id;
    }

    private static String insertSql(UUID id, String academyName) {
        return "insert into core.academy_request (id, email, requester_role, academy_name, locale) values ('" + id
                + "', 'r@example.com', 'COACH', '" + academyName.replace("'", "''") + "', 'en')";
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
