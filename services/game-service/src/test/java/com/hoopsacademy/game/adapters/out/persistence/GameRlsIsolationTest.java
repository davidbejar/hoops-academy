package com.hoopsacademy.game.adapters.out.persistence;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.testing.ColumnFixture;
import com.hoopsacademy.common.testing.GenericRlsIsolationTest;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.support.CoreWireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;
import java.util.UUID;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class GameRlsIsolationTest extends GenericRlsIsolationTest {

    @Override
    protected Map<String, Map<String, ColumnFixture>> fixtureOverrides() {
        Map<String, ColumnFixture> matchColumns = Map.of(
                "home_away", (c, t) -> "HOME",
                "status", (c, t) -> "SCHEDULED");
        Map<String, ColumnFixture> parentMatch = Map.of("match_id", GameRlsIsolationTest::insertMatch);
        Map<String, ColumnFixture> eventColumns = Map.of(
                "match_id", GameRlsIsolationTest::insertMatch,
                "type", (c, t) -> "NOTE",
                "period", (c, t) -> 1,
                "clock_seconds_remaining", (c, t) -> 0);
        return Map.of(
                "game.match", matchColumns,
                "game.match_roster", parentMatch,
                "game.sync_receipt", parentMatch,
                "game.match_event", eventColumns,
                "game.match_player_stats", parentMatch,
                "game.match_summary", parentMatch,
                "game.person_ref", Map.of("roles", (c, t) -> "{COACH}"));
    }

    /** Parent match in the same tenant (the migrator connection has app.tenant_id set). */
    static UUID insertMatch(Connection migrator, TenantId tenant) throws SQLException {
        try (PreparedStatement ps = migrator.prepareStatement("""
                insert into game.match (id, tenant_id, team_id, season_id, opponent_name, home_away, scheduled_at, status,
                                        created_by_person_id)
                values (gen_random_uuid(), ?, gen_random_uuid(), gen_random_uuid(), 'parent', 'HOME', now(), 'SCHEDULED',
                        gen_random_uuid()) returning id""")) {
            ps.setObject(1, tenant.value());
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getObject(1, UUID.class);
            }
        }
    }
}
