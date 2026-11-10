package com.hoopsacademy.athlete.rls;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import java.io.IOException;
import java.io.InputStream;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Stream;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/**
 * V10 and the catalogue seeds on a database that already has tenant data (decision 72, ADR-0047): a database migrated to
 * V9 with the seed of that time gets an academy's plans, plan items (one copied from a template), a session with its own
 * plan and a session on a template; migrating to the current version changes none of what the academy wrote, its items
 * reference no exercise, and the templates (same ids) now reference the catalogue.
 */
@Tag("rls")
class ExerciseCatalogueMigrationTest {

    private static final UUID TENANT = UUID.fromString("92000000-0000-4000-8000-0000000000f1");
    private static final UUID FINISHING = UUID.fromString("7bdee8e3-0ee8-5f9e-ad50-b24203a86937");
    private static final UUID EURO_STEP_ITEM = UUID.fromString("dac9351e-bbb0-51e9-8e02-1a1f83be52a4");

    private static final PostgresRlsResource DATABASE = new PostgresRlsResource();
    private static Map<String, String> config;

    @TempDir
    static Path v9Migrations;

    @BeforeAll
    static void startDatabase() {
        DATABASE.init(Map.of(PostgresRlsResource.SERVICE_ARG, "athlete"));
        config = DATABASE.start();
    }

    @AfterAll
    static void stopDatabase() {
        DATABASE.stop();
    }

    @Test
    void migratingADatabaseWithTenantDataChangesNothingTheAcademyWrote() throws Exception {
        migrate("filesystem:" + migrationsOfV9());
        UUID ownPlan = UUID.randomUUID();
        UUID sessionPlan = UUID.randomUUID();
        writeTenantData(ownPlan, sessionPlan);
        List<String> tenantRowsBefore = tenantRows();
        List<String> templateItemsBefore = rows("select id || ' ' || plan_id || ' ' || position || ' ' || title "
                + "from athlete.plan_item where owner_tenant_id is null order by id");

        migrate("classpath:db/migration");

        assertThat(tenantRows()).as("plans, items and sessions of the academy").isEqualTo(tenantRowsBefore);
        assertThat(rows("select count(*) || ' ' || count(exercise_id) from athlete.plan_item where owner_tenant_id = '"
                + TENANT + "'")).containsExactly("3 0");
        assertThat(rows("select id || ' ' || plan_id || ' ' || position || ' ' || title "
                + "from athlete.plan_item where owner_tenant_id is null order by id")).isEqualTo(templateItemsBefore);
        assertThat(rows("select count(*) from athlete.plan_item where owner_tenant_id is null and exercise_id is null"))
                .containsExactly("0");
        assertThat(rows("select count(*) from athlete.exercise where owner_tenant_id is null")).containsExactly("60");
        assertThat(rows("select e.title from athlete.plan_item i join athlete.exercise e on e.id = i.exercise_id "
                + "where i.id = '" + EURO_STEP_ITEM + "'")).containsExactly("Euro step");
        assertThat(rows("select count(*) from athlete.flyway_schema_history where version = '10' and success"))
                .as("V10 applied after the tenant data").containsExactly("1");
        assertThat(rows("select count(*) from athlete.flyway_schema_history where not success")).containsExactly("0");
    }

    /** V1..V9 and the norms seed as they are, the template seed as it was before V10. */
    private Path migrationsOfV9() throws IOException, URISyntaxException {
        Path current = Path.of(ExerciseCatalogueMigrationTest.class.getResource("/db/migration").toURI());
        try (Stream<Path> files = Files.list(current)) {
            for (Path file : files.toList()) {
                String name = file.getFileName().toString();
                boolean upToV9 = name.matches("V[1-9]__.*\\.sql");
                if (upToV9 || name.equals("R__physical_test_norms.sql")) {
                    Files.copy(file, v9Migrations.resolve(name), StandardCopyOption.REPLACE_EXISTING);
                }
            }
        }
        try (InputStream oldSeed = ExerciseCatalogueMigrationTest.class.getResourceAsStream(
                "/db/athlete-v9/R__plan_templates.sql")) {
            Files.copy(oldSeed, v9Migrations.resolve("R__plan_templates.sql"), StandardCopyOption.REPLACE_EXISTING);
        }
        return v9Migrations;
    }

    private static void migrate(String location) {
        Flyway.configure()
                .dataSource(config.get("quarkus.datasource.jdbc.url"), config.get("quarkus.flyway.username"),
                        config.get("quarkus.flyway.password"))
                .schemas("athlete").createSchemas(false).locations(location)
                .load().migrate();
    }

    /** What an academy wrote by V9: a plan with a hand-written item and a template copy, sessions with plans. */
    private static void writeTenantData(UUID ownPlan, UUID sessionPlan) throws SQLException {
        UUID sessionOnPlan = UUID.randomUUID();
        UUID sessionWithOwnPlan = UUID.randomUUID();
        UUID sessionOnTemplate = UUID.randomUUID();
        try (Connection app = openAsApp()) {
            app.setAutoCommit(false);
            exec(app, "select set_config('app.tenant_id', ?, true)", TENANT.toString());
            exec(app, "insert into athlete.training_plan (id, owner_tenant_id, name, description, source_plan_id) "
                    + "values (?, ?, 'Week 1', 'My notes', ?)", ownPlan, TENANT, FINISHING);
            exec(app, "insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, description, "
                    + "duration_min) values (gen_random_uuid(), ?, ?, 0, 'Euro step', 'Attack, step through, finish.', 6)",
                    ownPlan, TENANT);
            exec(app, "insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, sets, repetitions) "
                    + "values (gen_random_uuid(), ?, ?, 1, 'Our own drill', 3, 10)", ownPlan, TENANT);
            for (UUID[] session : new UUID[][] {{sessionOnPlan, ownPlan}, {sessionWithOwnPlan, null},
                    {sessionOnTemplate, FINISHING}}) {
                exec(app, "insert into athlete.training_session (id, tenant_id, team_id, starts_at, ends_at, plan_id) "
                        + "values (?, ?, gen_random_uuid(), '2027-09-07T15:00:00Z', '2027-09-07T16:30:00Z', ?)",
                        session[0], TENANT, session[1]);
            }
            exec(app, "insert into athlete.training_plan (id, owner_tenant_id, name, locale, ad_hoc_for_session) "
                    + "values (?, ?, 'Sesión 2027-09-07', 'es', ?)", sessionPlan, TENANT, sessionWithOwnPlan);
            exec(app, "insert into athlete.plan_item (id, plan_id, owner_tenant_id, position, title, duration_min) "
                    + "values (gen_random_uuid(), ?, ?, 0, 'Bomba', 6)", sessionPlan, TENANT);
            exec(app, "update athlete.training_session set plan_id = ? where id = ?", sessionPlan, sessionWithOwnPlan);
            app.commit();
        }
    }

    /** Every row the academy owns, as JSON without the column V10 adds. */
    private static List<String> tenantRows() throws SQLException {
        return rows("""
                select 'plan ' || (to_jsonb(p))::text from athlete.training_plan p where owner_tenant_id = '%1$s'
                union all
                select 'item ' || (to_jsonb(i) - 'exercise_id')::text from athlete.plan_item i where owner_tenant_id = '%1$s'
                union all
                select 'session ' || (to_jsonb(s))::text from athlete.training_session s where tenant_id = '%1$s'
                order by 1""".formatted(TENANT));
    }

    private static List<String> rows(String query) throws SQLException {
        List<String> rows = new ArrayList<>();
        try (Connection app = openAsApp()) {
            app.setAutoCommit(false);
            exec(app, "select set_config('app.tenant_id', ?, true)", TENANT.toString());
            try (PreparedStatement ps = app.prepareStatement(query); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(rs.getString(1));
                }
            }
            app.rollback();
        }
        return rows;
    }

    private static Connection openAsApp() throws SQLException {
        return DriverManager.getConnection(config.get("quarkus.datasource.jdbc.url"),
                config.get("quarkus.datasource.username"), config.get("quarkus.datasource.password"));
    }

    private static void exec(Connection connection, String sql, Object... params) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            ps.execute();
        }
    }
}
