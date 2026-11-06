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
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * {@code core.outbox} after V14 (WP67): the publisher reads each tenant's rows as core_app under the tenant policy, and
 * finds the tenants with a backlog through the platform role, which sees the queue columns of every tenant but never a
 * payload (personal data) and changes nothing.
 */
@Tag("rls")
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class OutboxRlsTest {

    private static final String INSUFFICIENT_PRIVILEGE = "42501";
    private static final String CHECK_VIOLATION = "23514";
    private final String tenantA = UUID.randomUUID().toString();
    private final String tenantB = UUID.randomUUID().toString();

    @BeforeEach
    void twoTenantsWithOneEventEach() {
        CoreDb.tenant(tenantA);
        CoreDb.tenant(tenantB);
        append(tenantA, "core.person");
        append(tenantB, "core.person");
    }

    @Test
    void platformRoleSeesTheBacklogOfEveryTenantButNoPayloadAndChangesNothing() throws SQLException {
        try (Connection platform = TestDatabases.openAsPlatform()) {
            assertThat(count(platform, """
                    select count(distinct tenant_id) from core.outbox
                     where tenant_id in ('%s', '%s') and published_at is null and topic is not null
                       and occurred_at <= now()""".formatted(tenantA, tenantB))).isEqualTo(2);
            for (String column : List.of("payload", "aggregate_id", "event_type", "aggregate_type", "id", "seq")) {
                assertThat(sqlState(platform, "select " + column + " from core.outbox"))
                        .as("platform must not read core.outbox.%s", column).isEqualTo(INSUFFICIENT_PRIVILEGE);
            }
            assertThat(sqlState(platform, "update core.outbox set published_at = now()"))
                    .isEqualTo(INSUFFICIENT_PRIVILEGE);
            assertThat(sqlState(platform, "delete from core.outbox")).isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
    }

    @Test
    void appRoleReadsAndMarksOnlyTheBoundTenantsRows() throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            CoreDb.bindTenant(app, TenantId.parse(tenantA));
            assertThat(count(app, "select count(*) from core.outbox where tenant_id = '" + tenantB + "'")).isZero();
            assertThat(CoreDb.update(app, "update core.outbox set published_at = clock_timestamp() where published_at is null"))
                    .isEqualTo(1);
            app.commit();
        }
        assertThat(CoreDb.count(tenantB, "select count(*) from core.outbox where published_at is null")).isEqualTo(1);
    }

    @Test
    void rowsAreNumberedInInsertOrderAndStampedWithTheClockNotTheTransactionStart() {
        List<Object[]> rows = CoreDb.inTenant(tenantA, c -> {
            append(c, tenantA, "core.team");
            append(c, tenantA, "core.team");
            List<Object[]> result = new ArrayList<>();
            try (PreparedStatement statement = c.prepareStatement(
                    "select seq, occurred_at from core.outbox where topic = 'core.team' order by seq");
                    ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    result.add(new Object[] {rs.getLong(1), rs.getTimestamp(2)});
                }
            }
            return result;
        });

        assertThat(rows).hasSize(2);
        assertThat((Long) rows.get(1)[0]).isGreaterThan((Long) rows.get(0)[0]);
        assertThat(((java.sql.Timestamp) rows.get(1)[1])).isAfter((java.sql.Timestamp) rows.get(0)[1]);
    }

    @Test
    void aTopicMustBeACoreTopicName() {
        String state = CoreDb.inTenant(tenantA, c -> sqlState(c, """
                insert into core.outbox (id, tenant_id, event_type, aggregate_type, aggregate_id, payload, topic)
                values (gen_random_uuid(), '%s', 'x.changed', 'x', gen_random_uuid()::text, '{}', 'Game.Person')"""
                .formatted(tenantA)));

        assertThat(state).isEqualTo(CHECK_VIOLATION);
    }

    private static void append(String tenant, String topic) {
        CoreDb.inTenant(tenant, c -> {
            append(c, tenant, topic);
            return null;
        });
    }

    private static void append(Connection c, String tenant, String topic) throws SQLException {
        CoreDb.update(c, """
                insert into core.outbox (id, tenant_id, event_type, aggregate_type, aggregate_id, payload, topic)
                values (gen_random_uuid(), ?, 'x.changed', 'x', gen_random_uuid()::text, '{}', ?)""",
                UUID.fromString(tenant), topic);
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
