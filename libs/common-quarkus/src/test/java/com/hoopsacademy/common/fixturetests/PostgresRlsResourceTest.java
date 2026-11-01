package com.hoopsacademy.common.fixturetests;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import io.agroal.api.AgroalDataSource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class PostgresRlsResourceTest {

    @Inject
    AgroalDataSource dataSource;

    @Test
    void applicationConnectsAsNonOwnerAppRoleWithoutBypassRls() throws SQLException {
        try (Connection c = dataSource.getConnection();
                ResultSet rs = c.createStatement().executeQuery(
                        "select rolname, rolsuper, rolbypassrls from pg_roles where rolname = current_user")) {
            rs.next();
            assertThat(rs.getString(1)).isEqualTo("core_app");
            assertThat(rs.getBoolean(2)).isFalse();
            assertThat(rs.getBoolean(3)).isFalse();
        }
    }

    @Test
    void flywayRanAsMigratorWhichOwnsTheTables() throws SQLException {
        try (Connection c = dataSource.getConnection();
                ResultSet rs = c.createStatement().executeQuery(
                        "select tableowner from pg_tables where schemaname = 'core' and tablename = 'sample_widget'")) {
            assertThat(rs.next()).isTrue();
            assertThat(rs.getString(1)).isEqualTo("core_migrator");
        }
    }

    @Test
    void exposesMigratorCredentialsForFixtures() throws SQLException {
        try (Connection c = RlsTestDatabase.fromConfig().openAsMigrator();
                ResultSet rs = c.createStatement().executeQuery("select current_user")) {
            rs.next();
            assertThat(rs.getString(1)).isEqualTo("core_migrator");
        }
    }
}
