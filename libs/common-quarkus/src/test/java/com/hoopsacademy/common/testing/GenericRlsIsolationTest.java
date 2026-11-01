package com.hoopsacademy.common.testing;

import static org.junit.jupiter.api.DynamicTest.dynamicTest;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.TestFactory;

/**
 * Generic isolation suite every service subclasses ({@code @QuarkusTest @WithTestResource(PostgresRlsResource.class)}):
 * one dynamic test per table with a {@code tenant_id} column, see {@link RlsIsolationCheck}. Tables needing special
 * values (foreign keys, check constraints) get them via {@link #fixtureOverrides()} — never exclude a table.
 */
@Tag("rls")
public abstract class GenericRlsIsolationTest {

    private static final String TENANT_TABLES_SQL = """
            select n.nspname || '.' || c.relname
              from pg_class c
              join pg_namespace n on n.oid = c.relnamespace
              join pg_attribute a on a.attrelid = c.oid and a.attname = 'tenant_id' and not a.attisdropped
             where n.nspname = ? and c.relkind in ('r', 'p')
             order by c.relname
            """;

    /** Schemas owned by the service; defaults to the schema named like the service. */
    protected List<String> schemas() {
        return List.of(RlsTestDatabase.fromConfig().service());
    }

    /** {@code "schema.table" -> column -> fixture} for columns the generic value generator cannot fill. */
    protected Map<String, Map<String, ColumnFixture>> fixtureOverrides() {
        return Map.of();
    }

    /**
     * Shared global+tenant tables (same map as {@link RlsSchemaMetaTest#nullableTenantTables()}): skipped here because
     * a tenant legitimately sees the global rows; they need a dedicated isolation test.
     */
    protected Map<String, String> nullableTenantTables() {
        return Map.of();
    }

    @TestFactory
    Stream<DynamicTest> everyTenantTableIsIsolatedBetweenTenants() throws SQLException {
        RlsTestDatabase db = RlsTestDatabase.fromConfig();
        Map<String, Map<String, ColumnFixture>> overrides = fixtureOverrides();
        Map<String, String> shared = nullableTenantTables();
        return tenantTables(db).stream().filter(table -> !shared.containsKey(table)).map(table -> dynamicTest(table,
                () -> RlsIsolationCheck.verify(db, table, overrides.getOrDefault(table, Map.of()))));
    }

    private List<String> tenantTables(RlsTestDatabase db) throws SQLException {
        List<String> tables = new ArrayList<>();
        try (Connection connection = db.openAsApp();
                PreparedStatement statement = connection.prepareStatement(TENANT_TABLES_SQL)) {
            for (String schema : schemas()) {
                statement.setString(1, schema);
                try (ResultSet rs = statement.executeQuery()) {
                    while (rs.next()) {
                        tables.add(rs.getString(1));
                    }
                }
            }
        }
        return tables;
    }
}
