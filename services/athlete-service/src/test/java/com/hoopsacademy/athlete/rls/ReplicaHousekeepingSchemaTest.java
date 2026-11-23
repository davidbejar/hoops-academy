package com.hoopsacademy.athlete.rls;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
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
 * V9 (WP82): the retention job may delete parked records and read their coordinates, never what a record said; the
 * global list of the replica's tenants is append-only for athlete_app; the parking table has the shape game's has.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class ReplicaHousekeepingSchemaTest {

    @Test
    void theAppRoleMayParkAndPruneButNeverReadWhatAParkedRecordSaid() throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            app.createStatement().execute("insert into athlete.parked_event (topic, partition, kafka_offset, record_key, "
                    + "reason) values ('core.team', 0, 4242, 'k', 'schema violation')");
            app.createStatement().execute("select topic, partition, kafka_offset, parked_at, inspected_at "
                    + "from athlete.parked_event");
            app.createStatement().execute("delete from athlete.parked_event where inspected_at < now()");
            refused(app, "select record_key from athlete.parked_event", "select event_id from athlete.parked_event",
                    "select reason from athlete.parked_event", "update athlete.parked_event set reason = 'x'",
                    "update athlete.parked_event set inspected_at = now()");
            app.rollback();
        }
    }

    @Test
    void theAppRoleMayListAndAddReplicaTenantsButNeverChangeThem() throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            app.createStatement().execute("insert into athlete.replica_tenant (id) values (gen_random_uuid())");
            app.createStatement().execute("select id, first_seen_at from athlete.replica_tenant");
            refused(app, "update athlete.replica_tenant set first_seen_at = now()", "delete from athlete.replica_tenant");
            app.rollback();
        }
    }

    /**
     * WP130 (ADR-0062): {@code parked_event} has one shape in athlete and game (game V10), so common's stores and one
     * runbook procedure serve both: the record's position in its topic is the primary key, no surrogate id.
     */
    @Test
    void theParkingTableHasTheSharedShape() throws SQLException {
        try (Connection owner = RlsTestDatabase.fromConfig().openAsMigrator();
                PreparedStatement columns = owner.prepareStatement("""
                        select column_name from information_schema.columns
                         where table_schema = 'athlete' and table_name = 'parked_event' order by ordinal_position""");
                PreparedStatement key = owner.prepareStatement("""
                        select a.attname from pg_index i
                          join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any (i.indkey)
                         where i.indrelid = 'athlete.parked_event'::regclass and i.indisprimary
                         order by array_position(i.indkey::smallint[], a.attnum)""")) {
            assertThat(names(columns)).containsExactly("topic", "partition", "kafka_offset", "record_key", "event_id",
                    "reason", "parked_at", "inspected_at");
            assertThat(names(key)).containsExactly("topic", "partition", "kafka_offset");
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

    private static void refused(Connection app, String... statements) throws SQLException {
        for (String sql : List.of(statements)) {
            app.createStatement().execute("savepoint attempt");
            assertThatThrownBy(() -> app.createStatement().execute(sql)).as(sql).isInstanceOf(SQLException.class)
                    .extracting(e -> ((SQLException) e).getSQLState()).isEqualTo("42501");
            app.createStatement().execute("rollback to savepoint attempt");
        }
    }
}
