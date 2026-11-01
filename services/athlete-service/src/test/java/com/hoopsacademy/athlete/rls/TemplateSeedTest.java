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

/** The repeatable seed: ten English global templates of 4 to 8 timed items, safe to run any number of times. */
@QuarkusTest
@Tag("rls")
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class TemplateSeedTest {

    private static final String SNAPSHOT = """
            select p.id || '|' || p.name || '|' || p.locale || '|' || p.is_template || '|' ||
                   (select count(*) from athlete.plan_item i where i.plan_id = p.id) || '|' ||
                   (select string_agg(i.id || ':' || i.position || ':' || i.duration_min, ',' order by i.position)
                      from athlete.plan_item i where i.plan_id = p.id)
              from athlete.training_plan p where p.owner_tenant_id is null order by p.id""";

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
        List<String> rows = new ArrayList<>();
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp(); Statement st = app.createStatement()) {
            app.setAutoCommit(false);
            st.execute("select set_config('app.tenant_id', '00000000-0000-4000-8000-00000000feed', true)");
            try (ResultSet rs = st.executeQuery(SNAPSHOT)) {
                while (rs.next()) {
                    rows.add(rs.getString(1));
                }
            }
        }
        return rows;
    }
}
