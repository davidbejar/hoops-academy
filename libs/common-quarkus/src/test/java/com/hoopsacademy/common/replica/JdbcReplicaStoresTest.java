package com.hoopsacademy.common.replica;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;

/**
 * The shared bookkeeping stores (WP130) on the replica tables' shape (test migration V3, as game's and athlete's
 * {@code parked_event}, {@code applied_event} and {@code replica_tenant}), as the app role: a record parked twice is
 * kept once; applied ids are pruned in the bound tenant only, in batches; inspected parked rows are pruned and reported.
 */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class JdbcReplicaStoresTest {

    private static final ReplicaSchema SCHEMA = new ReplicaSchema("core");
    private static final Instant NOW = Instant.now();

    @Inject
    DataSource dataSource;

    @Inject
    TenantScope tenantScope;

    @Test
    void aRecordParkedTwiceIsKeptOnceWithoutAnythingTheAppRoleCouldReadBack() throws SQLException {
        JdbcParkedEvents parked = new JdbcParkedEvents(dataSource, SCHEMA);
        long offset = System.nanoTime();
        UUID eventId = UUID.randomUUID();

        parked.park(new ParkedEvent("core.team", 1, offset, Optional.of("t:a"), Optional.of(eventId), "schema"));
        parked.park(new ParkedEvent("core.team", 1, offset, Optional.of("t:a"), Optional.of(eventId), "again"));
        parked.park(new ParkedEvent("core.team", 1, offset + 1, Optional.empty(), Optional.empty(), "not JSON"));

        assertThat(asOwner("select record_key, event_id, reason from core.parked_event where topic = 'core.team' "
                + "and partition = 1 and kafka_offset >= " + offset + " order by kafka_offset"))
                .containsExactly("t:a|" + eventId + "|schema", "null|null|not JSON");
    }

    @Test
    void theTenantsAreListedAndAppliedIdsArePrunedInTheBoundTenantOnlyAndInBatches() {
        JdbcReplicaHistory history = new JdbcReplicaHistory(dataSource, SCHEMA);
        TenantId a = TenantId.random();
        TenantId b = TenantId.random();
        applied(a, 3, NOW.minusSeconds(3600));
        applied(a, 1, NOW);
        applied(b, 2, NOW.minusSeconds(3600));

        assertThat(history.tenants()).contains(a, b);
        assertThat(tenantScope.runAs(a, () -> history.deleteAppliedBefore(NOW.minusSeconds(60), 2))).isEqualTo(2);
        assertThat(tenantScope.runAs(a, () -> history.deleteAppliedBefore(NOW.minusSeconds(60), 2))).isEqualTo(1);
        assertThat(tenantScope.runAs(a, () -> history.deleteAppliedBefore(NOW.minusSeconds(60), 2))).isZero();
        assertThat(tenantScope.runAs(b, () -> appliedCount())).isEqualTo(2);
        assertThat(tenantScope.runAs(a, () -> appliedCount())).isEqualTo(1);
    }

    @Test
    void inspectedParkedRecordsArePrunedAndReportedByTheirPosition() throws SQLException {
        JdbcReplicaHistory history = new JdbcReplicaHistory(dataSource, SCHEMA);
        long offset = System.nanoTime();
        try (Connection owner = RlsTestDatabase.fromConfig().openAsMigrator()) {
            owner.createStatement().execute("insert into core.parked_event (topic, partition, kafka_offset, reason, "
                    + "inspected_at) values ('core.person', 4, " + offset + ", 'x', now() - interval '40 days'), "
                    + "('core.person', 4, " + (offset + 1) + ", 'x', now()), "
                    + "('core.person', 4, " + (offset + 2) + ", 'x', null)");
        }

        assertThat(history.deleteParkedInspectedBefore(NOW.minusSeconds(30 * 86_400L)))
                .contains(new ParkedPosition("core.person", 4, offset))
                .doesNotContain(new ParkedPosition("core.person", 4, offset + 1),
                        new ParkedPosition("core.person", 4, offset + 2));
        assertThat(asOwner("select kafka_offset from core.parked_event where partition = 4 and kafka_offset >= " + offset))
                .containsExactlyInAnyOrder(String.valueOf(offset + 1), String.valueOf(offset + 2));
    }

    private void applied(TenantId tenant, int count, Instant at) {
        tenantScope.runAs(tenant, () -> {
            try (Connection connection = dataSource.getConnection()) {
                try (PreparedStatement statement = connection.prepareStatement(
                        "insert into core.replica_tenant (id) values (?) on conflict do nothing")) {
                    statement.setObject(1, tenant.value());
                    statement.executeUpdate();
                }
                for (int i = 0; i < count; i++) {
                    try (PreparedStatement statement = connection.prepareStatement("insert into core.applied_event "
                            + "(tenant_id, event_id, topic, applied_at) values (app.current_tenant(), ?, 'core.team', ?)")) {
                        statement.setObject(1, UUID.randomUUID());
                        statement.setObject(2, OffsetDateTime.ofInstant(at, ZoneOffset.UTC));
                        statement.executeUpdate();
                    }
                }
            } catch (SQLException e) {
                throw new IllegalStateException(e);
            }
        });
    }

    private long appliedCount() {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement("select count(*) from core.applied_event");
                ResultSet rows = statement.executeQuery()) {
            rows.next();
            return rows.getLong(1);
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    private static List<String> asOwner(String sql) throws SQLException {
        try (Connection owner = RlsTestDatabase.fromConfig().openAsMigrator();
                ResultSet rows = owner.createStatement().executeQuery(sql)) {
            List<String> result = new ArrayList<>();
            int columns = rows.getMetaData().getColumnCount();
            while (rows.next()) {
                List<String> values = new ArrayList<>();
                for (int i = 1; i <= columns; i++) {
                    values.add(String.valueOf(rows.getObject(i)));
                }
                result.add(String.join("|", values));
            }
            return result;
        }
    }
}
