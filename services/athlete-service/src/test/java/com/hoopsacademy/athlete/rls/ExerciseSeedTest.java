package com.hoopsacademy.athlete.rls;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

/**
 * The global exercise catalogue (decision 72, ADR-0047): every distinct item of the seeded templates plus the Cooper
 * test, in English with Spanish and Indonesian texts; every template item references its exercise and shows its texts;
 * both repeatable seeds can run again in any order without changing anything.
 */
@QuarkusTest
@Tag("rls")
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class ExerciseSeedTest {

    private static final String SNAPSHOT = """
            select e.id || '|' || e.name_key || '|' || e.title || '|' || coalesce(e.description, '') || '|' ||
                   coalesce(e.duration_min::text, '') || '|' || e.locale || '|' || e.i18n::text || '|' || e.archived
              from athlete.exercise e where e.owner_tenant_id is null
            union all
            select i.id || '|' || i.plan_id || '|' || i.position || '|' || i.title || '|' || coalesce(i.duration_min::text, '')
                   || '|' || coalesce(i.i18n::text, '') || '|' || coalesce(i.exercise_id::text, 'none')
              from athlete.plan_item i where i.owner_tenant_id is null
            order by 1""";

    @Test
    void theCatalogueHoldsEveryDistinctTemplateItemAndTheCooperTest() throws Exception {
        assertThat(rows("select count(*) from athlete.exercise where owner_tenant_id is null")).containsExactly("60");
        assertThat(rows("select count(distinct title) from athlete.plan_item where owner_tenant_id is null"))
                .containsExactly("59");
        assertThat(rows("select name_key || ' ' || title || ' ' || duration_min || ' ' || (i18n -> 'es' ->> 'title') || ' / '"
                + " || (i18n -> 'id' ->> 'title') from athlete.exercise where name_key = 'cooper-test'"))
                .containsExactly("cooper-test Cooper test (12 min) 12 Test de Cooper (12 min) / Tes Cooper (12 menit)");
        assertThat(rows("select name_key from athlete.exercise where owner_tenant_id is null"))
                .hasSize(60).doesNotHaveDuplicates().allMatch(key -> key.matches("[a-z0-9]+(-[a-z0-9]+)*"));
        assertThat(rows("select title from athlete.exercise where owner_tenant_id is null")).doesNotHaveDuplicates();
    }

    @Test
    void everyGlobalExerciseHasSpanishAndIndonesianTexts() throws Exception {
        assertThat(rows("""
                select e.name_key || ' ' || l.code from athlete.exercise e cross join (values ('es'), ('id')) l(code)
                 where e.owner_tenant_id is null
                   and (coalesce(e.i18n -> l.code ->> 'title', '') = ''
                        or (e.description is not null and coalesce(e.i18n -> l.code ->> 'description', '') = ''))"""))
                .as("missing es/id texts").isEmpty();
        assertThat(rows("select locale from athlete.exercise where owner_tenant_id is null")).containsOnly("en");
    }

    @Test
    void everyTemplateItemReferencesAnExerciseWithItsTexts() throws Exception {
        assertThat(rows("select id from athlete.plan_item where owner_tenant_id is null and exercise_id is null"))
                .as("template items without an exercise").isEmpty();
        assertThat(rows("""
                select i.id from athlete.plan_item i join athlete.exercise e on e.id = i.exercise_id
                 where i.owner_tenant_id is null
                   and (i.title <> e.title or i.description is distinct from e.description
                        or i.i18n is distinct from e.i18n)"""))
                .as("template items whose texts differ from their exercise").isEmpty();
        assertThat(rows("select count(distinct exercise_id) from athlete.plan_item where owner_tenant_id is null"))
                .containsExactly("59");
    }

    @Test
    void runningBothSeedsAgainInEitherOrderChangesNothing() throws Exception {
        List<String> before = rows(SNAPSHOT);

        runSeed("R__exercise_catalogue.sql");
        runSeed("R__plan_templates.sql");
        runSeed("R__plan_templates.sql");
        runSeed("R__exercise_catalogue.sql");

        assertThat(rows(SNAPSHOT)).isEqualTo(before);
        try (Connection migrator = RlsTestDatabase.fromConfig().openAsMigrator(); Statement st = migrator.createStatement();
                ResultSet rs = st.executeQuery("""
                        select bool_and(relforcerowsecurity) from pg_class
                         where oid in ('athlete.exercise'::regclass, 'athlete.plan_item'::regclass, 'athlete.training_plan'::regclass)""")) {
            rs.next();
            assertThat(rs.getBoolean(1)).as("FORCE restored after the seeds").isTrue();
        }
    }

    private static void runSeed(String file) throws IOException, SQLException {
        String sql;
        try (var in = ExerciseSeedTest.class.getResourceAsStream("/db/migration/" + file)) {
            sql = new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
        try (Connection migrator = RlsTestDatabase.fromConfig().openAsMigrator()) {
            migrator.setAutoCommit(false);
            try (Statement st = migrator.createStatement()) {
                st.execute(sql);
            }
            migrator.commit();
        }
    }

    private static List<String> rows(String query) throws SQLException {
        List<String> rows = new ArrayList<>();
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp(); Statement st = app.createStatement()) {
            app.setAutoCommit(false);
            st.execute("select set_config('app.tenant_id', '00000000-0000-4000-8000-00000000feed', true)");
            try (ResultSet rs = st.executeQuery(query)) {
                while (rs.next()) {
                    rows.add(rs.getString(1));
                }
            }
        }
        return rows;
    }
}
