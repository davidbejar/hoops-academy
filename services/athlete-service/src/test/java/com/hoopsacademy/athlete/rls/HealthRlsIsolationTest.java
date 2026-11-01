package com.hoopsacademy.athlete.rls;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.common.tenancy.TenantId;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * physical_test_type and physical_test_norm hold global rows (owner_tenant_id null) next to tenant overrides, so they
 * use the select / insert / update / delete policy pattern instead of the generic suite: every tenant reads the
 * global rows, nobody but the migrator writes them, and a tenant never sees or touches another tenant's rows.
 */
@QuarkusTest
@Tag("rls")
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class HealthRlsIsolationTest {

    private static final String INSUFFICIENT_PRIVILEGE = "42501";

    private final TenantId tenantA = TenantId.random();
    private final TenantId tenantB = TenantId.random();
    private final UUID typeA = UUID.randomUUID();
    private final UUID typeB = UUID.randomUUID();
    private final UUID globalType = UUID.randomUUID();
    private final UUID normA = UUID.randomUUID();
    private final UUID normB = UUID.randomUUID();
    private final UUID globalNorm = UUID.randomUUID();
    private RlsTestDatabase db;

    @BeforeEach
    void insertFixtures() throws SQLException {
        db = RlsTestDatabase.fromConfig();
        try (Connection migrator = db.openAsMigrator()) {
            migrator.setAutoCommit(false);
            insertTenantRows(migrator, tenantA, typeA, normA);
            insertTenantRows(migrator, tenantB, typeB, normB);
            migrator.commit();
        }
        try (Connection migrator = db.openAsMigrator()) {
            migrator.setAutoCommit(false);
            exec(migrator, "alter table athlete.physical_test_type no force row level security");
            exec(migrator, "alter table athlete.physical_test_norm no force row level security");
            exec(migrator, "insert into athlete.physical_test_type (id, owner_tenant_id, code, name, unit, higher_is_better) "
                    + "values (?, null, 'GLOBALX', 'Global', 'm', true)", globalType);
            exec(migrator, "insert into athlete.physical_test_norm (id, owner_tenant_id, test_type_id, gender, min_age, max_age, band, "
                    + "min_value, max_value, reference_pending, source) values (?, null, ?, 'MALE', 10, 11, 'AVERAGE', 1, 2, true, 'placeholder')",
                    globalNorm, globalType);
            exec(migrator, "alter table athlete.physical_test_type force row level security");
            exec(migrator, "alter table athlete.physical_test_norm force row level security");
            migrator.commit();
        }
    }

    @AfterEach
    void deleteFixtures() throws SQLException {
        try (Connection migrator = db.openAsMigrator()) {
            migrator.setAutoCommit(false);
            exec(migrator, "alter table athlete.physical_test_type no force row level security");
            exec(migrator, "alter table athlete.physical_test_norm no force row level security");
            exec(migrator, "delete from athlete.physical_test_norm where test_type_id in (?, ?, ?)", typeA, typeB, globalType);
            exec(migrator, "delete from athlete.physical_test_type where id in (?, ?, ?)", typeA, typeB, globalType);
            exec(migrator, "alter table athlete.physical_test_type force row level security");
            exec(migrator, "alter table athlete.physical_test_norm force row level security");
            migrator.commit();
        }
    }

    @Test
    void bothTenantsSeeTheGlobalRowsAndOnlyTheirOwnOverrides() throws SQLException {
        for (TenantId tenant : new TenantId[] {tenantA, tenantB}) {
            UUID ownType = tenant.equals(tenantA) ? typeA : typeB;
            UUID foreignType = tenant.equals(tenantA) ? typeB : typeA;
            UUID ownNorm = tenant.equals(tenantA) ? normA : normB;
            UUID foreignNorm = tenant.equals(tenantA) ? normB : normA;
            try (Connection app = db.openAsApp()) {
                app.setAutoCommit(false);
                bind(app, tenant);
                assertThat(count(app, "select count(*) from athlete.physical_test_type where id = ?", globalType)).isEqualTo(1);
                assertThat(count(app, "select count(*) from athlete.physical_test_norm where id = ?", globalNorm)).isEqualTo(1);
                assertThat(count(app, "select count(*) from athlete.physical_test_type where id = ?", ownType)).isEqualTo(1);
                assertThat(count(app, "select count(*) from athlete.physical_test_norm where id = ?", ownNorm)).isEqualTo(1);
                assertThat(count(app, "select count(*) from athlete.physical_test_type where id = ?", foreignType)).isZero();
                assertThat(count(app, "select count(*) from athlete.physical_test_norm where id = ?", foreignNorm)).isZero();
            }
        }
    }

    @Test
    void aTenantCannotUpdateOrDeleteGlobalRowsNorAnotherTenantsOverrides() throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantA);
            assertThat(exec(app, "update athlete.physical_test_type set name = 'hacked' where id = ?", globalType)).isZero();
            assertThat(exec(app, "delete from athlete.physical_test_type where id = ?", globalType)).isZero();
            assertThat(exec(app, "update athlete.physical_test_norm set band = 'EXCELLENT' where id = ?", globalNorm)).isZero();
            assertThat(exec(app, "delete from athlete.physical_test_norm where id = ?", globalNorm)).isZero();
            assertThat(exec(app, "update athlete.physical_test_type set name = 'hacked' where id = ?", typeB)).isZero();
            assertThat(exec(app, "delete from athlete.physical_test_norm where id = ?", normB)).isZero();
            app.rollback();
        }
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantB);
            assertThat(count(app, "select count(*) from athlete.physical_test_type where id = ? and name = 'Global'", globalType)).isEqualTo(1);
            assertThat(count(app, "select count(*) from athlete.physical_test_norm where id = ? and band = 'AVERAGE'", globalNorm)).isEqualTo(1);
            assertThat(count(app, "select count(*) from athlete.physical_test_type where id = ? and name = 'Type'", typeB)).isEqualTo(1);
            assertThat(count(app, "select count(*) from athlete.physical_test_norm where id = ?", normB)).isEqualTo(1);
        }
    }

    @Test
    void aTenantCanChangeItsOwnOverrides() throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantA);
            assertThat(exec(app, "update athlete.physical_test_type set name = 'mine' where id = ?", typeA)).isEqualTo(1);
            assertThat(exec(app, "update athlete.physical_test_norm set band = 'EXCELLENT' where id = ?", normA)).isEqualTo(1);
            assertThat(exec(app, "delete from athlete.physical_test_norm where id = ?", normA)).isEqualTo(1);
            app.rollback();
        }
    }

    @Test
    void aTenantCannotInsertGlobalRowsOrRowsForAnotherTenant() throws SQLException {
        assertThat(sqlStateOfTypeInsert(tenantA, null)).isEqualTo(INSUFFICIENT_PRIVILEGE);
        assertThat(sqlStateOfTypeInsert(tenantA, tenantB)).isEqualTo(INSUFFICIENT_PRIVILEGE);
        assertThat(sqlStateOfTypeInsert(tenantA, tenantA)).isEqualTo("no error");
        assertThat(sqlStateOfNormInsert(tenantA, null, globalType)).isEqualTo(INSUFFICIENT_PRIVILEGE);
        assertThat(sqlStateOfNormInsert(tenantA, tenantB, globalType)).isEqualTo(INSUFFICIENT_PRIVILEGE);
        assertThat(sqlStateOfNormInsert(tenantA, tenantA, globalType)).isEqualTo("no error");
    }

    @Test
    void aTenantCannotTurnItsRowsIntoGlobalOnesOrHandThemOver() throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantA);
            assertThat(sqlStateOf(app, "update athlete.physical_test_type set owner_tenant_id = null where id = ?", typeA))
                    .isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantA);
            assertThat(sqlStateOf(app, "update athlete.physical_test_norm set owner_tenant_id = '" + tenantB + "' where id = ?", normA))
                    .isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
    }

    @Test
    void withoutATenantTheTablesRaiseInsteadOfLeaking() throws SQLException {
        try (Connection app = db.openAsApp()) {
            assertThat(sqlStateOf(app, "select count(*) from athlete.physical_test_type")).isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
        try (Connection app = db.openAsApp()) {
            assertThat(sqlStateOf(app, "select count(*) from athlete.physical_test_norm")).isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
    }

    @Test
    void bothTablesForceRlsWithPoliciesPerCommandOnTheCurrentTenant() throws SQLException {
        try (Connection app = db.openAsApp(); PreparedStatement ps = app.prepareStatement("""
                select c.relname, c.relrowsecurity, c.relforcerowsecurity,
                       (select count(distinct p.polcmd) from pg_policy p join pg_depend d
                          on d.classid = 'pg_policy'::regclass and d.objid = p.oid
                         where p.polrelid = c.oid and d.refobjid = 'app.current_tenant()'::regprocedure),
                       (select count(*) from pg_policy p where p.polrelid = c.oid and p.polcmd = '*')
                  from pg_class c join pg_namespace n on n.oid = c.relnamespace
                 where n.nspname = 'athlete' and c.relname in ('physical_test_type', 'physical_test_norm') order by 1""");
                ResultSet rs = ps.executeQuery()) {
            int tables = 0;
            while (rs.next()) {
                tables++;
                assertThat(rs.getBoolean(2)).as(rs.getString(1) + " rls enabled").isTrue();
                assertThat(rs.getBoolean(3)).as(rs.getString(1) + " rls forced").isTrue();
                assertThat(rs.getInt(4)).as(rs.getString(1) + " commands with a tenant policy").isEqualTo(4);
                assertThat(rs.getInt(5)).as(rs.getString(1) + " FOR ALL policies (would let DELETE through)").isZero();
            }
            assertThat(tables).isEqualTo(2);
        }
    }

    // ------------------------------------------------------------------ helpers
    private String sqlStateOfTypeInsert(TenantId caller, TenantId owner) throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, caller);
            String ownerSql = owner == null ? "null" : "'" + owner + "'";
            return sqlStateOf(app, "insert into athlete.physical_test_type (id, owner_tenant_id, code, name, unit, higher_is_better) "
                    + "values (gen_random_uuid(), " + ownerSql + ", 'C' || upper(substr(md5(random()::text), 1, 8)), 'n', 's', false)");
        }
    }

    private String sqlStateOfNormInsert(TenantId caller, TenantId owner, UUID type) throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, caller);
            String ownerSql = owner == null ? "null" : "'" + owner + "'";
            return sqlStateOf(app, "insert into athlete.physical_test_norm (id, owner_tenant_id, test_type_id, gender, min_age, max_age, band, "
                    + "reference_pending, source) values (gen_random_uuid(), " + ownerSql + ", ?, 'FEMALE', 12, 13, 'POOR', false, 'academy table')", type);
        }
    }

    private static void insertTenantRows(Connection migrator, TenantId tenant, UUID type, UUID norm) throws SQLException {
        bind(migrator, tenant);
        exec(migrator, "insert into athlete.physical_test_type (id, owner_tenant_id, code, name, unit, higher_is_better) "
                + "values (?, ?, 'T' || upper(substr(md5(?::text), 1, 8)), 'Type', 's', false)", type, tenant.value(), type.toString());
        exec(migrator, "insert into athlete.physical_test_norm (id, owner_tenant_id, test_type_id, gender, min_age, max_age, band, "
                + "reference_pending, source) values (?, ?, ?, 'MALE', 12, 13, 'AVERAGE', false, 'academy table')", norm, tenant.value(), type);
    }

    private static String sqlStateOf(Connection connection, String sql, Object... params) {
        try {
            exec(connection, sql, params);
            return "no error";
        } catch (SQLException e) {
            return e.getSQLState();
        }
    }

    private static void bind(Connection connection, TenantId tenant) throws SQLException {
        exec(connection, "select set_config('app.tenant_id', ?, true)", tenant.toString());
    }

    private static int exec(Connection connection, String sql, Object... params) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            ps.execute();
            return ps.getUpdateCount();
        }
    }

    private static long count(Connection connection, String sql, Object... params) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getLong(1);
            }
        }
    }
}
