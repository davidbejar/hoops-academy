package com.hoopsacademy.game.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.game.application.replica.ParkedRecord;
import com.hoopsacademy.game.application.replica.ReplicateRoster;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.ReplicaDb;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * V4 (WP68, ADR-0037): the roster replica tables are tenant tables (so the generic RLS suites cover them); the parking
 * table has no tenant, so the app role may write it and (V6, WP82) prune it, never read what a record said.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class RosterReplicaSchemaTest {

    private static final List<String> TENANT_TABLES = List.of("applied_event", "guardian_link_ref", "person_ref",
            "player_ref", "team_player_ref", "team_ref", "team_staff_ref", "tenant_ref");

    @Inject
    ReplicateRoster replicate;

    @Test
    void replicaTablesAreTenantTables() throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp();
                PreparedStatement statement = app.prepareStatement("""
                        select c.relname from pg_class c
                          join pg_namespace n on n.oid = c.relnamespace
                          join pg_attribute a on a.attrelid = c.oid and a.attname = 'tenant_id'
                         where n.nspname = 'game' and c.relrowsecurity and c.relforcerowsecurity
                           and c.relname = any (?) order by 1""")) {
            statement.setArray(1, app.createArrayOf("text", TENANT_TABLES.toArray()));
            assertThat(names(statement)).containsExactlyElementsOf(TENANT_TABLES);
        }
    }

    /** WP82: the retention job may delete inspected rows and read their coordinates, never what a record said. */
    @Test
    void theAppRoleMayParkAndPruneButNeverReadWhatAParkedRecordSaid() throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            try (PreparedStatement insert = app.prepareStatement("""
                    insert into game.parked_event (topic, kafka_partition, kafka_offset, record_key, reason)
                    values ('core.team', 0, 42, 'k', 'schema violation')""")) {
                assertThat(insert.executeUpdate()).isOne();
            }
            app.createStatement().execute("select id, topic, kafka_partition, kafka_offset, parked_at, inspected_at "
                    + "from game.parked_event");
            app.createStatement().execute("delete from game.parked_event where inspected_at < now()");
            for (String sql : List.of("select record_key from game.parked_event",
                    "select event_id from game.parked_event", "select reason from game.parked_event",
                    "update game.parked_event set reason = 'x'",
                    "update game.parked_event set inspected_at = now()")) {
                app.createStatement().execute("savepoint attempt");
                assertThatThrownBy(() -> app.createStatement().execute(sql)).as(sql)
                        .isInstanceOf(SQLException.class)
                        .extracting(e -> ((SQLException) e).getSQLState()).isEqualTo("42501");
                app.createStatement().execute("rollback to savepoint attempt");
            }
            app.rollback();
        }
    }

    /**
     * X-01 (WP126): a replay (reset offsets, events-backfill) parks the same record again; its position in the topic is
     * unique, so the second park is a no-op, as in athlete.
     */
    @Test
    void aReplayedRecordIsParkedOnce() {
        long offset = Math.abs(UUID.randomUUID().getMostSignificantBits() % 1_000_000_000L);
        ParkedRecord record = new ParkedRecord("core.team", 3, offset, "k", Optional.empty(), "schema violation");

        replicate.park(record);
        replicate.park(record);

        assertThat(ReplicaDb.parked()).filteredOn(row -> "core.team".equals(row.get("topic"))
                && Integer.valueOf(3).equals(row.get("kafka_partition")) && Long.valueOf(offset).equals(row.get("kafka_offset")))
                .hasSize(1);
    }

    /**
     * WP130 (ADR-0062): {@code parked_event} has one shape in game and athlete, so the shared store and one runbook
     * procedure serve both: the record's position in its topic is the primary key, no surrogate id.
     */
    @Test
    void theParkingTableHasTheSharedShape() throws SQLException {
        try (Connection owner = RlsTestDatabase.fromConfig().openAsMigrator();
                PreparedStatement columns = owner.prepareStatement("""
                        select column_name from information_schema.columns
                         where table_schema = 'game' and table_name = 'parked_event' order by ordinal_position""");
                PreparedStatement key = owner.prepareStatement("""
                        select a.attname from pg_index i
                          join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any (i.indkey)
                         where i.indrelid = 'game.parked_event'::regclass and i.indisprimary
                         order by array_position(i.indkey::smallint[], a.attnum)""")) {
            assertThat(names(columns)).containsExactly("topic", "partition", "kafka_offset", "record_key", "event_id",
                    "reason", "parked_at", "inspected_at");
            assertThat(names(key)).containsExactly("topic", "partition", "kafka_offset");
        }
    }

    /** WP82: the global list of the replica's tenants is append-only for the app role. */
    @Test
    void theAppRoleMayListAndAddReplicaTenantsButNeverChangeThem() throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            app.createStatement().execute("insert into game.replica_tenant (id) values (gen_random_uuid())");
            app.createStatement().execute("select id, first_seen_at from game.replica_tenant");
            for (String sql : List.of("update game.replica_tenant set first_seen_at = now()",
                    "delete from game.replica_tenant")) {
                app.createStatement().execute("savepoint attempt");
                assertThatThrownBy(() -> app.createStatement().execute(sql)).as(sql)
                        .isInstanceOf(SQLException.class)
                        .extracting(e -> ((SQLException) e).getSQLState()).isEqualTo("42501");
                app.createStatement().execute("rollback to savepoint attempt");
            }
            app.rollback();
        }
    }

    private static List<String> names(PreparedStatement statement) throws SQLException {
        List<String> names = new ArrayList<>();
        try (ResultSet rows = statement.executeQuery()) {
            while (rows.next()) {
                names.add(rows.getString(1));
            }
        }
        return names;
    }
}
