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
 * training_plan and plan_item hold global templates (owner_tenant_id null) next to tenant rows, so they use a custom
 * policy and cannot be covered by the generic suite: every tenant reads templates, nobody but the migrator writes them,
 * and a tenant never sees or touches another tenant's plans.
 */
@QuarkusTest
@Tag("rls")
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class TemplateRlsIsolationTest {

    private static final String INSUFFICIENT_PRIVILEGE = "42501";

    private final TenantId tenantA = TenantId.random();
    private final TenantId tenantB = TenantId.random();
    private final UUID planA = UUID.randomUUID();
    private final UUID planB = UUID.randomUUID();
    private final UUID templateId = UUID.randomUUID();
    private RlsTestDatabase db;

    @BeforeEach
    void insertFixtures() throws SQLException {
        db = RlsTestDatabase.fromConfig();
        try (Connection migrator = db.openAsMigrator()) {
            migrator.setAutoCommit(false);
            insertPlan(migrator, tenantA, planA, false);
            insertPlan(migrator, tenantB, planB, false);
            insertTemplateAsOwner(migrator);
            migrator.commit();
        }
    }

    @AfterEach
    void deleteFixtures() throws SQLException {
        try (Connection migrator = db.openAsMigrator()) {
            migrator.setAutoCommit(false);
            for (TenantId tenant : new TenantId[] {tenantA, tenantB}) {
                bind(migrator, tenant);
                exec(migrator, "delete from athlete.plan_item where owner_tenant_id = ?", tenant.value());
                exec(migrator, "delete from athlete.training_plan where owner_tenant_id = ?", tenant.value());
            }
            migrator.commit();
        }
        try (Connection migrator = db.openAsMigrator()) {
            migrator.setAutoCommit(false);
            exec(migrator, "alter table athlete.training_plan no force row level security");
            exec(migrator, "alter table athlete.plan_item no force row level security");
            exec(migrator, "delete from athlete.plan_item where plan_id = ?", templateId);
            exec(migrator, "delete from athlete.training_plan where id = ?", templateId);
            exec(migrator, "alter table athlete.training_plan force row level security");
            exec(migrator, "alter table athlete.plan_item force row level security");
            migrator.commit();
        }
    }

    @Test
    void bothTenantsSeeTheTemplateAndOnlyTheirOwnPlans() throws SQLException {
        for (TenantId tenant : new TenantId[] {tenantA, tenantB}) {
            try (Connection app = db.openAsApp()) {
                app.setAutoCommit(false);
                bind(app, tenant);
                UUID own = tenant.equals(tenantA) ? planA : planB;
                UUID foreign = tenant.equals(tenantA) ? planB : planA;
                assertThat(count(app, "select count(*) from athlete.training_plan where id = ?", templateId)).isEqualTo(1);
                assertThat(count(app, "select count(*) from athlete.plan_item where plan_id = ?", templateId)).isEqualTo(1);
                assertThat(count(app, "select count(*) from athlete.training_plan where id = ?", own)).isEqualTo(1);
                assertThat(count(app, "select count(*) from athlete.training_plan where id = ?", foreign)).isZero();
                assertThat(count(app, "select count(*) from athlete.plan_item where plan_id = ?", foreign)).isZero();
            }
        }
    }

    @Test
    void aTenantCannotUpdateOrDeleteATemplate() throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantA);
            assertThat(exec(app, "update athlete.training_plan set name = 'hacked' where id = ?", templateId)).isZero();
            assertThat(exec(app, "delete from athlete.training_plan where id = ?", templateId)).isZero();
            assertThat(exec(app, "update athlete.plan_item set title = 'hacked' where plan_id = ?", templateId)).isZero();
            assertThat(exec(app, "delete from athlete.plan_item where plan_id = ?", templateId)).isZero();
            app.rollback();
        }
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantB);
            assertThat(count(app, "select count(*) from athlete.training_plan where id = ? and name = 'Template'", templateId))
                    .isEqualTo(1);
            assertThat(count(app, "select count(*) from athlete.plan_item where plan_id = ? and title = 'Item'", templateId))
                    .isEqualTo(1);
        }
    }

    @Test
    void aTenantCannotInsertATemplateOrAPlanForAnotherTenant() throws SQLException {
        assertThat(sqlStateOfInsertAs(tenantA, null, UUID.randomUUID())).isEqualTo(INSUFFICIENT_PRIVILEGE);
        assertThat(sqlStateOfInsertAs(tenantA, tenantB, UUID.randomUUID())).isEqualTo(INSUFFICIENT_PRIVILEGE);
        assertThat(sqlStateOfInsertAs(tenantA, tenantA, UUID.randomUUID())).isEqualTo("no error");
    }

    @Test
    void aTenantCannotTurnItsPlanIntoATemplateOrHandItToAnotherTenant() throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantA);
            assertThat(sqlStateOf(app, "update athlete.training_plan set owner_tenant_id = null where id = ?", planA))
                    .isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantA);
            assertThat(sqlStateOf(app, "update athlete.training_plan set owner_tenant_id = '" + tenantB + "' where id = ?", planA))
                    .isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
    }

    @Test
    void aTenantCannotAttachItemsToATemplateOrToAnotherTenantsPlan() throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantA);
            assertThat(sqlStateOf(app, "insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title) "
                    + "values (gen_random_uuid(), ?, null, 5, 'x')", templateId)).isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantA);
            // the composite foreign key ties an item to a plan of the same owner
            assertThat(sqlStateOf(app, "insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title) "
                    + "values (gen_random_uuid(), ?, '" + tenantA + "', 5, 'x')", planB)).isEqualTo("23503");
        }
    }

    @Test
    void withoutATenantTenantRowsRaiseInsteadOfLeaking() throws SQLException {
        try (Connection app = db.openAsApp()) {
            assertThat(sqlStateOf(app, "select count(*) from athlete.training_plan")).isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
    }

    @Test
    void bothTablesForceRlsWithAPolicyOnTheCurrentTenant() throws SQLException {
        try (Connection app = db.openAsApp(); PreparedStatement ps = app.prepareStatement("""
                select c.relname, c.relrowsecurity, c.relforcerowsecurity,
                       exists (select 1 from pg_policy p join pg_depend d on d.classid = 'pg_policy'::regclass and d.objid = p.oid
                                where p.polrelid = c.oid and d.refobjid = 'app.current_tenant()'::regprocedure)
                  from pg_class c join pg_namespace n on n.oid = c.relnamespace
                 where n.nspname = 'athlete' and c.relname in ('training_plan', 'plan_item') order by 1""");
                ResultSet rs = ps.executeQuery()) {
            int tables = 0;
            while (rs.next()) {
                tables++;
                assertThat(rs.getBoolean(2)).as(rs.getString(1) + " rls enabled").isTrue();
                assertThat(rs.getBoolean(3)).as(rs.getString(1) + " rls forced").isTrue();
                assertThat(rs.getBoolean(4)).as(rs.getString(1) + " tenant policy").isTrue();
            }
            assertThat(tables).isEqualTo(2);
        }
    }

    // ------------------------------------------------------------------ helpers
    private String sqlStateOfInsertAs(TenantId caller, TenantId owner, UUID id) throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, caller);
            String ownerSql = owner == null ? "null" : "'" + owner + "'";
            return sqlStateOf(app, "insert into athlete.training_plan (id, owner_tenant_id, name, is_template) values (?, "
                    + ownerSql + ", 'p', " + (owner == null) + ")", id);
        }
    }

    private static String sqlStateOf(Connection connection, String sql, Object... params) {
        try {
            exec(connection, sql, params);
            return "no error";
        } catch (SQLException e) {
            return e.getSQLState();
        }
    }

    private void insertPlan(Connection c, TenantId tenant, UUID id, boolean template) throws SQLException {
        bind(c, tenant);
        exec(c, "insert into athlete.training_plan (id, owner_tenant_id, name, is_template) values (?, ?, 'Plan', ?)",
                id, tenant.value(), template);
        exec(c, "insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title) values (gen_random_uuid(), ?, ?, 0, 'Item')",
                id, tenant.value());
    }

    /** Templates are written by the migrator only (the seed migration lifts FORCE for the duration of its transaction). */
    private void insertTemplateAsOwner(Connection migrator) throws SQLException {
        exec(migrator, "alter table athlete.training_plan no force row level security");
        exec(migrator, "alter table athlete.plan_item no force row level security");
        exec(migrator, "insert into athlete.training_plan (id, owner_tenant_id, name, is_template) values (?, null, 'Template', true)", templateId);
        exec(migrator, "insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title) values (gen_random_uuid(), ?, null, 0, 'Item')", templateId);
        exec(migrator, "alter table athlete.training_plan force row level security");
        exec(migrator, "alter table athlete.plan_item force row level security");
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
