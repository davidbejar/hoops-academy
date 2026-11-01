package com.hoopsacademy.common.testing;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Savepoint;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Data-driven isolation check for one tenant table: rows for tenants A and B are inserted as the migrator; then,
 * as the app role with {@code app.tenant_id = A}, A sees exactly its row, cannot update/delete B's row, cannot
 * insert a row for B (SQLSTATE 42501), and without the variable any select raises 42501.
 */
public final class RlsIsolationCheck {

    static final String INSUFFICIENT_PRIVILEGE = "42501";

    private final RlsTestDatabase db;
    private final String table;
    private final Map<String, ColumnFixture> overrides;
    private final TenantId tenantA = TenantId.random();
    private final TenantId tenantB = TenantId.random();

    private RlsIsolationCheck(RlsTestDatabase db, String table, Map<String, ColumnFixture> overrides) {
        this.db = db;
        this.table = table;
        this.overrides = overrides;
    }

    public static void verify(RlsTestDatabase db, String qualifiedTable, Map<String, ColumnFixture> overrides)
            throws SQLException {
        new RlsIsolationCheck(db, qualifiedTable, overrides).run();
    }

    private record Fixtures(TableShape shape, Map<String, Object> rowBKey, Map<String, Object> crossTenantRow) {}

    private void run() throws SQLException {
        Fixtures fixtures = insertFixtures();
        try {
            assertTenantSeesOnlyItsOwnRows(fixtures);
            assertSelectWithoutTenantRaises();
        } finally {
            deleteFixtures();
        }
    }

    private Fixtures insertFixtures() throws SQLException {
        try (Connection migrator = db.openAsMigrator()) {
            migrator.setAutoCommit(false);
            TableShape shape = TableShape.load(migrator, table);
            try {
                bindTenant(migrator, tenantA);
                FixtureRows.insert(migrator, shape, FixtureRows.rowFor(shape, tenantA, overrides, migrator));
                bindTenant(migrator, tenantB);
                Map<String, Object> rowBKey =
                        FixtureRows.insert(migrator, shape, FixtureRows.rowFor(shape, tenantB, overrides, migrator));
                Map<String, Object> crossTenantRow = FixtureRows.rowFor(shape, tenantB, overrides, migrator);
                migrator.commit();
                return new Fixtures(shape, rowBKey, crossTenantRow);
            } catch (SQLException e) {
                throw FixtureRows.missingOverride(shape, "insert failed: " + e.getMessage());
            }
        }
    }

    private void assertTenantSeesOnlyItsOwnRows(Fixtures fixtures) throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bindTenant(app, tenantA);
            assertThat(count(app, "select count(*) from " + table))
                    .as("%s: tenant A must see exactly its own row", table).isEqualTo(1);
            assertThat(executeUpdateByKey(app, "update " + table + " set tenant_id = tenant_id", fixtures.rowBKey()))
                    .as("%s: tenant A must not update tenant B's row", table).isZero();
            assertThat(executeUpdateByKey(app, "delete from " + table, fixtures.rowBKey()))
                    .as("%s: tenant A must not delete tenant B's row", table).isZero();
            assertThat(crossTenantInsertSqlState(app, fixtures))
                    .as("%s: insert with tenant B's id must fail with SQLSTATE 42501", table)
                    .isEqualTo(INSUFFICIENT_PRIVILEGE);
            app.rollback();
        }
    }

    private void assertSelectWithoutTenantRaises() throws SQLException {
        try (Connection app = db.openAsApp()) {
            assertThat(sqlStateOf(() -> count(app, "select count(*) from " + table)))
                    .as("%s: select without app.tenant_id must raise SQLSTATE 42501", table)
                    .isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
    }

    private String crossTenantInsertSqlState(Connection app, Fixtures fixtures) throws SQLException {
        Savepoint savepoint = app.setSavepoint();
        String sqlState = sqlStateOf(() -> {
            FixtureRows.insertOnly(app, fixtures.shape(), fixtures.crossTenantRow());
            return null;
        });
        app.rollback(savepoint);
        return sqlState;
    }

    private void deleteFixtures() throws SQLException {
        try (Connection migrator = db.openAsMigrator()) {
            migrator.setAutoCommit(false);
            for (TenantId tenant : List.of(tenantA, tenantB)) {
                bindTenant(migrator, tenant);
                try (PreparedStatement delete = migrator.prepareStatement("delete from " + table + " where tenant_id = ?")) {
                    delete.setObject(1, tenant.value());
                    delete.executeUpdate();
                }
            }
            migrator.commit();
        }
    }

    private int executeUpdateByKey(Connection app, String statementPrefix, Map<String, Object> key) throws SQLException {
        String where = key.keySet().stream().map(column -> column + " = ?").collect(Collectors.joining(" and "));
        try (PreparedStatement statement = app.prepareStatement(statementPrefix + " where " + where)) {
            FixtureRows.bind(statement, List.copyOf(key.values()));
            return statement.executeUpdate();
        }
    }

    private static long count(Connection connection, String sql) throws SQLException {
        try (ResultSet rs = connection.createStatement().executeQuery(sql)) {
            rs.next();
            return rs.getLong(1);
        }
    }

    private static void bindTenant(Connection connection, TenantId tenant) throws SQLException {
        try (PreparedStatement statement = connection.prepareStatement("select set_config('app.tenant_id', ?, true)")) {
            statement.setString(1, tenant.toString());
            statement.execute();
        }
    }

    @FunctionalInterface
    private interface SqlAction {
        Object run() throws SQLException;
    }

    /** @return the SQLSTATE the action failed with, or "no error" when it succeeded */
    private static String sqlStateOf(SqlAction action) {
        try {
            action.run();
            return "no error";
        } catch (SQLException e) {
            return e.getSQLState();
        }
    }
}
