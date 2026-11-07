package com.hoopsacademy.athlete.rls;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * V9 (WP82): the retention job may delete parked records and read their coordinates, never what a record said; the
 * global list of the replica's tenants is append-only for athlete_app.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
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

    private static void refused(Connection app, String... statements) throws SQLException {
        for (String sql : List.of(statements)) {
            app.createStatement().execute("savepoint attempt");
            assertThatThrownBy(() -> app.createStatement().execute(sql)).as(sql).isInstanceOf(SQLException.class)
                    .extracting(e -> ((SQLException) e).getSQLState()).isEqualTo("42501");
            app.createStatement().execute("rollback to savepoint attempt");
        }
    }
}
