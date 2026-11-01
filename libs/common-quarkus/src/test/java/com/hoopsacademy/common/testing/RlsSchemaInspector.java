package com.hoopsacademy.common.testing;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

/**
 * Reads the catalogue and reports every table of the given schemas that breaks the tenancy rules (ADR-0006):
 * a table with {@code tenant_id} needs RLS enabled + FORCEd, {@code tenant_id uuid not null} and a policy that
 * depends on {@code app.current_tenant()}; a table without it must be a declared global table.
 */
public final class RlsSchemaInspector {

    private static final String FLYWAY_HISTORY = "flyway_schema_history";

    private static final String TABLE_FACTS_SQL = """
            select c.relname,
                   c.relrowsecurity,
                   c.relforcerowsecurity,
                   a.attname is not null as has_tenant_column,
                   coalesce(format_type(a.atttypid, a.atttypmod) = 'uuid' and a.attnotnull, false) as tenant_column_ok,
                   exists (select 1
                             from pg_policy p
                             join pg_depend d on d.classid = 'pg_policy'::regclass and d.objid = p.oid
                            where p.polrelid = c.oid
                              and d.refclassid = 'pg_proc'::regclass
                              and d.refobjid = 'app.current_tenant()'::regprocedure) as has_tenant_policy
              from pg_class c
              join pg_namespace n on n.oid = c.relnamespace
              left join pg_attribute a on a.attrelid = c.oid and a.attname = 'tenant_id' and not a.attisdropped
             where n.nspname = ? and c.relkind in ('r', 'p') and c.relname <> ?
             order by c.relname
            """;

    private RlsSchemaInspector() {}

    private record TableFacts(
            String name, boolean rlsEnabled, boolean rlsForced, boolean hasTenantColumn,
            boolean tenantColumnOk, boolean hasTenantPolicy) {}

    /** @param globalTables {@code "schema.table" -> reason} for tables that intentionally have no tenant_id */
    public static List<String> violations(Connection connection, List<String> schemas, Map<String, String> globalTables)
            throws SQLException {
        List<String> violations = new ArrayList<>();
        Set<String> actualGlobalTables = new TreeSet<>();
        for (String schema : schemas) {
            for (TableFacts table : tableFacts(connection, schema)) {
                String qualified = schema + "." + table.name();
                if (table.hasTenantColumn()) {
                    violations.addAll(tenantTableViolations(qualified, table));
                } else {
                    actualGlobalTables.add(qualified);
                    if (!globalTables.containsKey(qualified)) {
                        violations.add(qualified + ": no tenant_id column and not declared in globalTables()");
                    }
                }
            }
        }
        new TreeSet<>(globalTables.keySet()).stream()
                .filter(declared -> !actualGlobalTables.contains(declared))
                .forEach(stale -> violations.add(stale + ": declared in globalTables() but is not a global table of the schema"));
        return violations;
    }

    private static List<String> tenantTableViolations(String qualified, TableFacts table) {
        List<String> violations = new ArrayList<>();
        if (!table.rlsEnabled()) {
            violations.add(qualified + ": row level security not enabled");
        }
        if (!table.rlsForced()) {
            violations.add(qualified + ": row level security not FORCEd");
        }
        if (!table.tenantColumnOk()) {
            violations.add(qualified + ": tenant_id must be 'uuid not null'");
        }
        if (!table.hasTenantPolicy()) {
            violations.add(qualified + ": no policy referencing app.current_tenant()");
        }
        return violations;
    }

    private static List<TableFacts> tableFacts(Connection connection, String schema) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(TABLE_FACTS_SQL)) {
            statement.setString(1, schema);
            statement.setString(2, FLYWAY_HISTORY);
            List<TableFacts> tables = new ArrayList<>();
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    tables.add(new TableFacts(rs.getString(1), rs.getBoolean(2), rs.getBoolean(3), rs.getBoolean(4),
                            rs.getBoolean(5), rs.getBoolean(6)));
                }
            }
            return tables;
        }
    }
}
