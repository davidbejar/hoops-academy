package com.hoopsacademy.game.adapters.out.persistence;

import jakarta.persistence.EntityManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.hibernate.Session;

/**
 * Plain JDBC on the transaction's connection (so {@code app.tenant_id} and RLS apply). Inserts use
 * {@code app.current_tenant()} for tenant_id; isolation of reads relies on RLS (ADR-0006).
 */
abstract class JdbcRepository {

    @FunctionalInterface
    interface Binder {
        void bind(PreparedStatement statement) throws SQLException;
    }

    @FunctionalInterface
    interface RowMapper<T> {
        T map(ResultSet row) throws SQLException;
    }

    /** The request's entity manager; its connection carries the transaction. */
    abstract EntityManager entityManager();

    <T> List<T> query(String sql, Binder binder, RowMapper<T> mapper) {
        return work(connection -> {
            try (PreparedStatement statement = connection.prepareStatement(sql)) {
                binder.bind(statement);
                try (ResultSet rows = statement.executeQuery()) {
                    List<T> result = new ArrayList<>();
                    while (rows.next()) {
                        result.add(mapper.map(rows));
                    }
                    return result;
                }
            }
        });
    }

    int update(String sql, Binder binder) {
        return work(connection -> {
            try (PreparedStatement statement = connection.prepareStatement(sql)) {
                binder.bind(statement);
                return statement.executeUpdate();
            }
        });
    }

    void batch(String sql, List<Binder> rows) {
        work(connection -> {
            try (PreparedStatement statement = connection.prepareStatement(sql)) {
                for (Binder row : rows) {
                    row.bind(statement);
                    statement.addBatch();
                }
                return statement.executeBatch();
            }
        });
    }

    private <T> T work(org.hibernate.jdbc.ReturningWork<T> work) {
        Session session = entityManager().unwrap(Session.class);
        session.flush();
        return session.doReturningWork(work);
    }

    static void setUuid(PreparedStatement statement, int index, UUID value) throws SQLException {
        if (value == null) {
            statement.setNull(index, Types.OTHER);
        } else {
            statement.setObject(index, value);
        }
    }

    static Instant instant(ResultSet row, String column) throws SQLException {
        Timestamp timestamp = row.getTimestamp(column);
        return timestamp == null ? null : timestamp.toInstant();
    }

    static UUID uuid(ResultSet row, String column) throws SQLException {
        return row.getObject(column, UUID.class);
    }

}
