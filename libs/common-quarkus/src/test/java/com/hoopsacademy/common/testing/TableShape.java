package com.hoopsacademy.common.testing;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/** Columns and primary key of a table, read from the catalogue. */
record TableShape(String qualifiedName, List<Column> columns) {

    record Column(String name, String sqlType, boolean notNull, boolean hasDefault, boolean primaryKey) {

        /** Must be supplied by the fixture: NOT NULL and the database cannot fill it. */
        boolean isRequired() {
            return notNull && !hasDefault;
        }
    }

    private static final String COLUMNS_SQL = """
            select a.attname,
                   format_type(a.atttypid, a.atttypmod),
                   a.attnotnull,
                   a.atthasdef or a.attidentity <> '' or a.attgenerated <> '',
                   coalesce(a.attnum = any(i.indkey), false)
              from pg_attribute a
              left join pg_index i on i.indrelid = a.attrelid and i.indisprimary
             where a.attrelid = to_regclass(?) and a.attnum > 0 and not a.attisdropped
             order by a.attnum
            """;

    static TableShape load(Connection connection, String qualifiedName) throws SQLException {
        List<Column> columns = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(COLUMNS_SQL)) {
            statement.setString(1, qualifiedName);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    columns.add(new Column(rs.getString(1), rs.getString(2), rs.getBoolean(3), rs.getBoolean(4),
                            rs.getBoolean(5)));
                }
            }
        }
        if (columns.isEmpty()) {
            throw new IllegalStateException("Table not found: " + qualifiedName);
        }
        return new TableShape(qualifiedName, List.copyOf(columns));
    }

    List<String> primaryKey() {
        List<String> primaryKey = columns.stream().filter(Column::primaryKey).map(Column::name).toList();
        if (primaryKey.isEmpty()) {
            throw new IllegalStateException(qualifiedName + " has no primary key; tenant tables need one");
        }
        return primaryKey;
    }
}
