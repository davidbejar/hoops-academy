package com.hoopsacademy.athlete.rls;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

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
 * The repeatable seed: ten global templates of 4 to 8 timed items, written in English with Spanish and Indonesian
 * texts (decision 43), safe to run any number of times.
 */
@QuarkusTest
@Tag("rls")
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class TemplateSeedTest {

    private static final String SNAPSHOT = """
            select p.id || '|' || p.name || '|' || p.locale || '|' || p.is_template || '|' ||
                   (select count(*) from athlete.plan_item i where i.plan_id = p.id) || '|' ||
                   (select string_agg(i.id || ':' || i.position || ':' || i.duration_min, ',' order by i.position)
                      from athlete.plan_item i where i.plan_id = p.id) || '|' ||
                   p.name_key || '|' || p.i18n::text || '|' ||
                   (select string_agg(i.i18n::text, ',' order by i.position) from athlete.plan_item i where i.plan_id = p.id)
              from athlete.training_plan p where p.owner_tenant_id is null order by p.id""";

    /** Texts a template or one of its items lacks in Spanish or Indonesian (a description only where English has one). */
    private static final String MISSING_TRANSLATIONS = """
            select p.id || ' ' || l.code from athlete.training_plan p cross join (values ('es'), ('id')) l(code)
             where p.owner_tenant_id is null
               and (coalesce(p.i18n -> l.code ->> 'name', '') = ''
                    or (p.description is not null and coalesce(p.i18n -> l.code ->> 'description', '') = ''))
            union all
            select i.id || ' ' || l.code from athlete.plan_item i cross join (values ('es'), ('id')) l(code)
             where i.owner_tenant_id is null
               and (coalesce(i.i18n -> l.code ->> 'title', '') = ''
                    or (i.description is not null and coalesce(i.i18n -> l.code ->> 'description', '') = ''))""";

    @Test
    void tenTemplatesWithFourToEightTimedItemsEach() throws Exception {
        List<String> rows = snapshot();

        assertThat(rows).hasSize(10);
        for (String row : rows) {
            String[] parts = row.split("\\|");
            assertThat(parts[2]).isEqualTo("en");
            assertThat(parts[3]).isEqualTo("true");
            assertThat(Integer.parseInt(parts[4])).isBetween(4, 8);
            assertThat(parts[5].split(",")).allSatisfy(item -> assertThat(item.split(":")[2]).isNotEqualTo("null"));
        }
    }

    @Test
    void everyTemplateHasAStableKeyAndSpanishAndIndonesianTexts() throws Exception {
        assertThat(rows(MISSING_TRANSLATIONS)).as("missing es/id texts").isEmpty();
        assertThat(rows("select name_key from athlete.training_plan where owner_tenant_id is null"))
                .hasSize(10).doesNotHaveDuplicates().allMatch(key -> key.matches("[a-z]+(-[a-z]+)*"));
        assertThat(rows("""
                select i18n -> 'es' ->> 'name' from athlete.training_plan where owner_tenant_id is null
                union all select i18n -> 'id' ->> 'name' from athlete.training_plan where owner_tenant_id is null
                union all select i18n -> l ->> 'title' from athlete.plan_item, (values ('es'), ('id')) v(l)
                 where owner_tenant_id is null"""))
                .allSatisfy(text -> assertThat(text.length()).isBetween(1, 120));
    }

    @Test
    void tenantPlansCannotCarryTemplateTexts() throws Exception {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp(); Statement st = app.createStatement()) {
            app.setAutoCommit(false);
            st.execute("select set_config('app.tenant_id', '00000000-0000-4000-8000-00000000feed', true)");
            for (String insert : List.of(
                    "insert into athlete.training_plan (id, owner_tenant_id, name, i18n) values (gen_random_uuid(), "
                            + "app.current_tenant(), 'Mine', '{\"es\": {\"name\": \"Mío\"}}')",
                    "insert into athlete.training_plan (id, owner_tenant_id, name, name_key) values (gen_random_uuid(), "
                            + "app.current_tenant(), 'Mine', 'form-shooting')")) {
                st.execute("savepoint attempt");
                assertThatThrownBy(() -> st.execute(insert)).isInstanceOfSatisfying(SQLException.class,
                        e -> assertThat(e.getSQLState()).as(insert).isEqualTo("23514"));
                st.execute("rollback to savepoint attempt");
            }
            app.rollback();
        }
    }

    @Test
    void runningTheSeedAgainChangesNothing() throws Exception {
        List<String> before = snapshot();

        runSeed();
        runSeed();

        assertThat(snapshot()).isEqualTo(before);
        try (Connection migrator = RlsTestDatabase.fromConfig().openAsMigrator(); Statement st = migrator.createStatement();
                ResultSet rs = st.executeQuery("select relforcerowsecurity from pg_class where oid = 'athlete.training_plan'::regclass")) {
            rs.next();
            assertThat(rs.getBoolean(1)).as("FORCE restored after the seed").isTrue();
        }
    }

    private static void runSeed() throws IOException, SQLException {
        String sql;
        try (var in = TemplateSeedTest.class.getResourceAsStream("/db/migration/R__plan_templates.sql")) {
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

    private static List<String> snapshot() throws SQLException {
        return rows(SNAPSHOT);
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
