package com.hoopsacademy.game.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.game.support.CoreWireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
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
