package com.hoopsacademy.common.testing;

import com.hoopsacademy.common.tenancy.TenantId;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/** Builds and inserts minimal rows: tenant_id, overrides, and generic values for required columns. */
final class FixtureRows {

    private static final String TENANT_COLUMN = "tenant_id";

    private FixtureRows() {}

    static Map<String, Object> rowFor(
            TableShape shape, TenantId tenant, Map<String, ColumnFixture> overrides, Connection migrator)
            throws SQLException {
        Map<String, Object> row = new LinkedHashMap<>();
        for (TableShape.Column column : shape.columns()) {
            if (column.name().equals(TENANT_COLUMN)) {
                row.put(column.name(), tenant.value());
            } else if (overrides.containsKey(column.name())) {
                row.put(column.name(), overrides.get(column.name()).valueFor(migrator, tenant));
            } else if (column.isRequired()) {
                row.put(column.name(), GenericColumnValues.forType(column.sqlType()).orElseThrow(
                        () -> missingOverride(shape, column.name() + " of type " + column.sqlType())));
            }
        }
        return row;
    }

    /** Inserts {@code row} and returns its primary key values. */
    static Map<String, Object> insert(Connection connection, TableShape shape, Map<String, Object> row)
            throws SQLException {
        List<String> primaryKey = shape.primaryKey();
        String sql = insertSql(shape, row) + " returning " + String.join(", ", primaryKey);
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            bind(statement, List.copyOf(row.values()));
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                Map<String, Object> key = new LinkedHashMap<>();
                for (String column : primaryKey) {
                    key.put(column, rs.getObject(column));
                }
                return key;
            }
        }
    }

    /**
     * Inserts without RETURNING: a RETURNING clause would also apply the SELECT policy to the new row and could
     * mask a lax WITH CHECK expression.
     */
    static void insertOnly(Connection connection, TableShape shape, Map<String, Object> row) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(insertSql(shape, row))) {
            bind(statement, List.copyOf(row.values()));
            statement.executeUpdate();
        }
    }

    private static String insertSql(TableShape shape, Map<String, Object> row) {
        return "insert into " + shape.qualifiedName()
                + " (" + String.join(", ", row.keySet()) + ") values ("
                + shape.columns().stream().filter(c -> row.containsKey(c.name()))
                        .map(c -> "?::" + c.sqlType()).collect(Collectors.joining(", "))
                + ")";
    }

    static void bind(PreparedStatement statement, List<Object> values) throws SQLException {
        for (int i = 0; i < values.size(); i++) {
            statement.setObject(i + 1, values.get(i));
        }
    }

    static IllegalStateException missingOverride(TableShape shape, String reason) {
        return new IllegalStateException("Cannot build a fixture row for " + shape.qualifiedName() + " (" + reason
                + "). Provide the value in fixtureOverrides() of your GenericRlsIsolationTest subclass.");
    }
}
