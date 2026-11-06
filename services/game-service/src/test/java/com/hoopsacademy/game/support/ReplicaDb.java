package com.hoopsacademy.game.support;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import java.sql.Array;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Reads the replica tables as game_app with a tenant bound (RLS applies), and empties them as the migrator. */
public final class ReplicaDb {

    /** Every replica table, emptied by a replay from empty (ADR-0037). */
    public static final List<String> TABLES = List.of("game.tenant_ref", "game.person_ref", "game.player_ref",
            "game.team_ref", "game.team_player_ref", "game.team_staff_ref", "game.guardian_link_ref", "game.applied_event");

    private ReplicaDb() {}

    /** Rows of {@code sql} in {@code tenant}, each as column -> value. */
    public static List<Map<String, Object>> rows(TenantId tenant, String sql) {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            try (PreparedStatement bind = app.prepareStatement("select set_config('app.tenant_id', ?, true)")) {
                bind.setString(1, tenant.toString());
                bind.execute();
            }
            try (PreparedStatement statement = app.prepareStatement(sql); ResultSet rs = statement.executeQuery()) {
                List<Map<String, Object>> rows = read(rs);
                app.rollback();
                return rows;
            }
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    /** The single value of {@code sql} in {@code tenant}, or null without a row. */
    public static Object value(TenantId tenant, String sql) {
        List<Map<String, Object>> rows = rows(tenant, sql);
        return rows.isEmpty() ? null : rows.getFirst().values().iterator().next();
    }

    /** Rows of the parking table (readable only by the owner). */
    public static List<Map<String, Object>> parked() {
        try (Connection migrator = RlsTestDatabase.fromConfig().openAsMigrator();
                PreparedStatement statement = migrator.prepareStatement("select * from game.parked_event order by id");
                ResultSet rs = statement.executeQuery()) {
            return read(rs);
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    /** Empties the replica of every tenant, as the operator does before a replay from empty. */
    public static void truncate() {
        try (Connection migrator = RlsTestDatabase.fromConfig().openAsMigrator();
                PreparedStatement statement = migrator.prepareStatement("truncate " + String.join(", ", TABLES))) {
            statement.execute();
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    private static List<Map<String, Object>> read(ResultSet rs) throws SQLException {
        List<Map<String, Object>> rows = new ArrayList<>();
        ResultSetMetaData meta = rs.getMetaData();
        while (rs.next()) {
            Map<String, Object> row = new LinkedHashMap<>();
            for (int i = 1; i <= meta.getColumnCount(); i++) {
                Object value = rs.getObject(i);
                row.put(meta.getColumnLabel(i), value instanceof Array array ? List.of((Object[]) array.getArray()) : value);
            }
            rows.add(row);
        }
        return rows;
    }
}
