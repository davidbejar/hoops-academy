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

    @Test
    void everyTenantTableHasForcedRlsAndATenantPolicy() throws SQLException {
        try (Connection connection = RlsTestDatabase.fromConfig().openAsApp()) {
            assertThat(RlsSchemaInspector.violations(connection, schemas(), globalTables()))
                    .as("tenancy violations in schemas %s", schemas())
                    .isEmpty();
        }
    }
}
