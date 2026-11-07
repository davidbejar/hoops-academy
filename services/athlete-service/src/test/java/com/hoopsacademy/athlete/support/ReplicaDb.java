package com.hoopsacademy.athlete.support;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/** SQL on the replica's bookkeeping tables: as athlete_app with a tenant bound (RLS applies), or as the owner. */
public final class ReplicaDb {

    private ReplicaDb() {}

    /** The first column of every row of {@code sql} in {@code tenant}. */
    public static List<Object> column(TenantId tenant, String sql) {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenant);
            try (PreparedStatement statement = app.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
                List<Object> values = new ArrayList<>();
                while (rs.next()) {
                    values.add(rs.getObject(1));
                }
                app.rollback();
                return values;
            }
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    /** Runs {@code sql} as athlete_app with {@code tenant} bound and commits. */
    public static void execute(TenantId tenant, String sql) {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenant);
            try (PreparedStatement statement = app.prepareStatement(sql)) {
                statement.execute();
            }
            app.commit();
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    /** Runs {@code sql} as the owner, as an operator does on the parking table. */
    public static void executeAsOwner(String sql) {
        try (Connection migrator = RlsTestDatabase.fromConfig().openAsMigrator();
                PreparedStatement statement = migrator.prepareStatement(sql)) {
            statement.execute();
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    /** The offsets of the parked records (read as the owner: athlete_app may not read what they said). */
    public static List<Long> parkedOffsets() {
        try (Connection migrator = RlsTestDatabase.fromConfig().openAsMigrator();
                PreparedStatement statement = migrator.prepareStatement("select kafka_offset from athlete.parked_event");
                ResultSet rs = statement.executeQuery()) {
            List<Long> offsets = new ArrayList<>();
            while (rs.next()) {
                offsets.add(rs.getLong(1));
            }
            return offsets;
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    private static void bind(Connection app, TenantId tenant) throws SQLException {
        try (PreparedStatement bind = app.prepareStatement("select set_config('app.tenant_id', ?, true)")) {
            bind.setString(1, tenant.toString());
            bind.execute();
        }
    }
}
