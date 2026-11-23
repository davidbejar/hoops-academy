package com.hoopsacademy.athlete.rls;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Listings filtered by player have an index that leads with the tenant (RLS) and the player (ATH-18). */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class ListingIndexSchemaTest {

    @Test
    void completionsOfAPlayerAreIndexedNewestFirst() throws SQLException {
        assertThat(indexesOf("plan_completion")).anyMatch(index -> index.contains("(tenant_id, player_id, marked_at DESC)"));
    }

    private static List<String> indexesOf(String table) throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp();
                PreparedStatement statement = app.prepareStatement(
                        "select indexdef from pg_indexes where schemaname = 'athlete' and tablename = ?")) {
            statement.setString(1, table);
            List<String> indexes = new ArrayList<>();
            try (ResultSet rows = statement.executeQuery()) {
                while (rows.next()) {
                    indexes.add(rows.getString(1));
                }
            }
            return indexes;
        }
    }
}
