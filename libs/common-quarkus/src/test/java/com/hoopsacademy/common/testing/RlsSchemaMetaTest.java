package com.hoopsacademy.common.testing;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * Schema meta-test every service subclasses (annotated {@code @QuarkusTest @WithTestResource(PostgresRlsResource.class)}).
 * Fails when a migration forgot {@code select app.enable_tenant_rls('schema.table')} or added an undeclared global table.
 */
@Tag("rls")
public abstract class RlsSchemaMetaTest {

    /** Schemas owned by the service; defaults to the schema named like the service ({@code core}, {@code game}, …). */
    protected List<String> schemas() {
        return List.of(RlsTestDatabase.fromConfig().service());
    }

    /** {@code "schema.table" -> one-line justification} for every table without tenant_id. */
    protected Map<String, String> globalTables() {
        return Map.of();
    }

    /**
     * {@code "schema.table" -> owner column} for shared tables holding GLOBAL rows (owner null, read-only for tenants)
     * next to tenant rows, e.g. templates and norms. They may keep a column named {@code tenant_id} (nullable) or use
     * another name ({@code owner_tenant_id}, as WP9/WP10 did before this hook existed). Expected shape: uuid owner
     * column, RLS enabled + FORCEd, a policy on {@code app.current_tenant()} and SEPARATE select/insert/update/delete
     * policies (no {@code FOR ALL}: DELETE only evaluates USING, which admits the global rows). Declare the same map in
     * {@link GenericRlsIsolationTest#nullableTenantTables()} and give such tables their own isolation test.
     */
    protected Map<String, String> nullableTenantTables() {
        return Map.of();
    }

    @Test
    void everyTenantTableHasForcedRlsAndATenantPolicy() throws SQLException {
        try (Connection connection = RlsTestDatabase.fromConfig().openAsApp()) {
            assertThat(RlsSchemaInspector.violations(connection, schemas(), globalTables(), nullableTenantTables()))
                    .as("tenancy violations in schemas %s", schemas())
                    .isEmpty();
        }
    }
}
