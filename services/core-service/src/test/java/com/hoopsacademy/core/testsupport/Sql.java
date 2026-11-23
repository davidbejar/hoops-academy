package com.hoopsacademy.core.testsupport;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/** Plain JDBC probes of the RLS tests, on a connection they opened as one of the database roles. */
public final class Sql {

    private Sql() {}

    /** The first column of the first row of {@code sql}, e.g. a {@code count(*)}. */
    public static long count(Connection connection, String sql) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
            rs.next();
            return rs.getLong(1);
        }
    }

    /**
     * Runs {@code sql} and answers its SQLSTATE, or {@code "no error"}. Inside a transaction the statement runs under a
     * savepoint that is rolled back, so a refused statement does not abort the transaction for the next probe.
     */
    public static String sqlState(Connection connection, String sql) throws SQLException {
        var savepoint = connection.getAutoCommit() ? null : connection.setSavepoint();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.execute();
            return "no error";
        } catch (SQLException e) {
            return e.getSQLState();
        } finally {
            if (savepoint != null) {
                connection.rollback(savepoint);
            }
        }
    }
}
