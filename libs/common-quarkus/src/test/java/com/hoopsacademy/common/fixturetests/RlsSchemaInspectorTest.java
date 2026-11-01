package com.hoopsacademy.common.fixturetests;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsSchemaInspector;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Proves the meta-test detects broken schemas: each case mutates the schema in a transaction that is rolled back. */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class RlsSchemaInspectorTest {

    private static final Map<String, String> GLOBALS = Map.of("core.sample_colour", "catalogue");

    private Connection migrator;

    @BeforeEach
    void openMigratorTransaction() throws SQLException {
        migrator = RlsTestDatabase.fromConfig().openAsMigrator();
        migrator.setAutoCommit(false);
    }

    @AfterEach
    void rollback() throws SQLException {
        migrator.rollback();
        migrator.close();
    }

    private List<String> violations() throws SQLException {
        return RlsSchemaInspector.violations(migrator, List.of("core"), GLOBALS);
    }

    @Test
    void sampleSchemaIsClean() throws SQLException {
        assertThat(violations()).isEmpty();
    }

    @Test
    void droppingThePolicyIsDetected() throws SQLException {
        migrator.createStatement().execute("drop policy tenant_isolation on core.sample_widget");

        assertThat(violations()).containsExactly(
                "core.sample_widget: no policy referencing app.current_tenant()");
    }

    @Test
    void policyNotUsingTheTenantFunctionIsDetected() throws SQLException {
        migrator.createStatement().execute("drop policy tenant_isolation on core.sample_widget");
        migrator.createStatement().execute("create policy open_door on core.sample_widget using (true)");

        assertThat(violations()).containsExactly(
                "core.sample_widget: no policy referencing app.current_tenant()");
    }

    @Test
    void rlsNotForcedIsDetected() throws SQLException {
        migrator.createStatement().execute("alter table core.sample_widget no force row level security");

        assertThat(violations()).containsExactly("core.sample_widget: row level security not FORCEd");
    }

    @Test
    void rlsDisabledIsDetected() throws SQLException {
        migrator.createStatement().execute("alter table core.sample_widget_part disable row level security");

        assertThat(violations()).containsExactly("core.sample_widget_part: row level security not enabled");
    }

    @Test
    void nullableTenantColumnIsDetected() throws SQLException {
        migrator.createStatement().execute("create table core.sample_loose (id uuid primary key, tenant_id uuid)");
        migrator.createStatement().execute("select app.enable_tenant_rls('core.sample_loose')");

        assertThat(violations()).containsExactly("core.sample_loose: tenant_id must be 'uuid not null'");
    }

    @Test
    void undeclaredGlobalTableIsDetected() throws SQLException {
        migrator.createStatement().execute("create table core.sample_settings (key text primary key)");

        assertThat(violations()).containsExactly(
                "core.sample_settings: no tenant_id column and not declared in globalTables()");
    }

    @Test
    void staleGlobalDeclarationIsDetected() throws SQLException {
        var declared = Map.of("core.sample_colour", "catalogue", "core.gone", "removed long ago");

        assertThat(RlsSchemaInspector.violations(migrator, List.of("core"), declared))
                .containsExactly("core.gone: declared in globalTables() but is not a global table of the schema");
    }
}
