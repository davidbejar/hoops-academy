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
 * athlete.exercise holds the global catalogue (owner_tenant_id null, seeded) next to the academies' own exercises, so
 * like training_plan it has one policy per command instead of the generic tenant policy (V10, ADR-0047): every tenant
 * reads the global exercises, nobody but the migrator writes them, a tenant never sees or touches another's exercises.
 */
@QuarkusTest
@Tag("rls")
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class ExerciseRlsIsolationTest {

    private static final String INSUFFICIENT_PRIVILEGE = "42501";

    private final TenantId tenantA = TenantId.random();
    private final TenantId tenantB = TenantId.random();
    private final UUID exerciseA = UUID.randomUUID();
    private final UUID exerciseB = UUID.randomUUID();
    private RlsTestDatabase db;
    private UUID global;

    @BeforeEach
    void insertFixtures() throws SQLException {
        db = RlsTestDatabase.fromConfig();
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantA);
            exec(app, "insert into athlete.exercise (id, owner_tenant_id, title) values (?, ?, 'Mine')", exerciseA,
                    tenantA.value());
            bind(app, tenantB);
            exec(app, "insert into athlete.exercise (id, owner_tenant_id, title) values (?, ?, 'Theirs')", exerciseB,
                    tenantB.value());
            global = uuid(app, "select id from athlete.exercise where name_key = 'cooper-test'");
            app.commit();
        }
    }

    @AfterEach
    void deleteFixtures() throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            for (TenantId tenant : new TenantId[] {tenantA, tenantB}) {
                bind(app, tenant);
                exec(app, "delete from athlete.plan_item where owner_tenant_id = ?", tenant.value());
                exec(app, "delete from athlete.training_plan where owner_tenant_id = ?", tenant.value());
                exec(app, "delete from athlete.exercise where owner_tenant_id = ?", tenant.value());
            }
            app.commit();
        }
    }

    @Test
    void bothTenantsReadTheGlobalCatalogueAndOnlyTheirOwnExercises() throws SQLException {
        for (TenantId tenant : new TenantId[] {tenantA, tenantB}) {
            try (Connection app = db.openAsApp()) {
                app.setAutoCommit(false);
                bind(app, tenant);
                UUID own = tenant.equals(tenantA) ? exerciseA : exerciseB;
                UUID foreign = tenant.equals(tenantA) ? exerciseB : exerciseA;
                assertThat(count(app, "select count(*) from athlete.exercise where id = ?", global)).isEqualTo(1);
                assertThat(count(app, "select count(*) from athlete.exercise where id = ?", own)).isEqualTo(1);
                assertThat(count(app, "select count(*) from athlete.exercise where id = ?", foreign)).isZero();
                assertThat(count(app, "select count(*) from athlete.exercise where owner_tenant_id is not null"))
                        .isEqualTo(1);
            }
        }
    }

    @Test
    void aTenantCannotUpdateOrDeleteAGlobalExerciseOrAnotherTenantsExercise() throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantA);
            for (UUID target : new UUID[] {global, exerciseB}) {
                assertThat(exec(app, "update athlete.exercise set title = 'hacked' where id = ?", target)).isZero();
                assertThat(exec(app, "update athlete.exercise set archived = true where id = ?", target)).isZero();
                assertThat(exec(app, "delete from athlete.exercise where id = ?", target)).isZero();
            }
            assertThat(exec(app, "update athlete.exercise set title = 'renamed' where id = ?", exerciseA)).isEqualTo(1);
            app.rollback();
        }
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantB);
            assertThat(count(app, "select count(*) from athlete.exercise where id = ? and title = 'Theirs'", exerciseB))
                    .isEqualTo(1);
            assertThat(count(app, "select count(*) from athlete.exercise where id = ? and not archived", global))
                    .isEqualTo(1);
        }
    }

    @Test
    void aTenantCannotInsertAGlobalExerciseOrOneForAnotherTenant() throws SQLException {
        assertThat(sqlStateOfInsertAs(tenantA, null)).isEqualTo(INSUFFICIENT_PRIVILEGE);
        assertThat(sqlStateOfInsertAs(tenantA, tenantB)).isEqualTo(INSUFFICIENT_PRIVILEGE);
        assertThat(sqlStateOfInsertAs(tenantA, tenantA)).isEqualTo("no error");
    }

    @Test
    void aTenantCannotMakeItsExerciseGlobalOrHandItToAnotherTenant() throws SQLException {
        for (String owner : new String[] {"null", "'" + tenantB + "'"}) {
            try (Connection app = db.openAsApp()) {
                app.setAutoCommit(false);
                bind(app, tenantA);
                assertThat(sqlStateOf(app, "update athlete.exercise set owner_tenant_id = " + owner + " where id = ?",
                        exerciseA)).as(owner).isEqualTo(INSUFFICIENT_PRIVILEGE);
            }
        }
    }

    @Test
    void anAcademysExerciseCarriesNeitherAKeyNorTranslations() throws SQLException {
        for (String columns : new String[] {"name_key) values (gen_random_uuid(), app.current_tenant(), 'x', 'cooper-x'",
                "i18n) values (gen_random_uuid(), app.current_tenant(), 'x', '{\"es\": {\"title\": \"y\"}}'"}) {
            try (Connection app = db.openAsApp()) {
                app.setAutoCommit(false);
                bind(app, tenantA);
                assertThat(sqlStateOf(app, "insert into athlete.exercise (id, owner_tenant_id, title, " + columns + ")"))
                        .as(columns).isEqualTo("23514");
            }
        }
    }

    @Test
    void anItemReferencesAnExerciseThatExists() throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, tenantA);
            UUID plan = UUID.randomUUID();
            exec(app, "insert into athlete.training_plan (id, owner_tenant_id, name) values (?, ?, 'P')", plan,
                    tenantA.value());
            assertThat(sqlStateOf(app, "insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, "
                    + "exercise_id) values (gen_random_uuid(), ?, ?, 0, 'x', ?)", plan, tenantA.value(), global))
                    .isEqualTo("no error");
            assertThat(sqlStateOf(app, "insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, "
                    + "exercise_id) values (gen_random_uuid(), ?, ?, 1, 'x', gen_random_uuid())", plan, tenantA.value()))
                    .isEqualTo("23503");
            app.rollback();
        }
    }

    @Test
    void withoutATenantTheCatalogueRaisesInsteadOfLeaking() throws SQLException {
        try (Connection app = db.openAsApp()) {
            assertThat(sqlStateOf(app, "select count(*) from athlete.exercise")).isEqualTo(INSUFFICIENT_PRIVILEGE);
        }
    }

    // ------------------------------------------------------------------ helpers
    private String sqlStateOfInsertAs(TenantId caller, TenantId owner) throws SQLException {
        try (Connection app = db.openAsApp()) {
            app.setAutoCommit(false);
            bind(app, caller);
            String ownerSql = owner == null ? "null" : "'" + owner + "'";
            String key = owner == null ? "'global-" + UUID.randomUUID() + "'" : "null";
            return sqlStateOf(app, "insert into athlete.exercise (id, owner_tenant_id, name_key, title) values "
                    + "(gen_random_uuid(), " + ownerSql + ", " + key + ", 'x')");
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

    private static UUID uuid(Connection connection, String sql) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            rs.next();
            return rs.getObject(1, UUID.class);
        }
    }
}
