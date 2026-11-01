package com.hoopsacademy.core.rls;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.testing.ColumnFixture;
import com.hoopsacademy.common.testing.GenericRlsIsolationTest;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class CoreRlsIsolationTest extends GenericRlsIsolationTest {

    @Override
    protected List<String> schemas() {
        return List.of("core", "billing");
    }

    @Override
    protected Map<String, Map<String, ColumnFixture>> fixtureOverrides() {
        return Map.ofEntries(
                Map.entry("core.tenant_settings", Map.of("age_rule", CoreRlsIsolationTest::tenantRowThenAgeRule)),
                Map.entry("core.tenant_logo", Map.of("content_type", (c, t) -> "image/png")),
                Map.entry("core.membership_role", Map.of("person_id", CoreRlsIsolationTest::person, "role", (c, t) -> "COACH")),
                Map.entry("core.player", Map.of("person_id", CoreRlsIsolationTest::person)),
                Map.entry("core.guardian_link", Map.of(
                        "guardian_person_id", CoreRlsIsolationTest::person,
                        "player_id", CoreRlsIsolationTest::player)),
                Map.entry("core.user_membership_index", Map.of("person_id", CoreRlsIsolationTest::person)),
                Map.entry("billing.tenant_subscription", Map.of("plan_code", (c, t) -> "FREE")),
                Map.entry("core.season", Map.of("start_date", (c, t) -> nextFixtureDay(), "end_date", (c, t) -> lastFixtureDay(),
                        "reference_year", (c, t) -> 2026)),
                Map.entry("core.age_category", Map.of("code", (c, t) -> "C" + FIXTURE_SEQ.incrementAndGet(),
                        "sort_rank", (c, t) -> FIXTURE_SEQ.incrementAndGet())),
                Map.entry("core.team", Map.of("season_id", CoreRlsIsolationTest::season,
                        "age_category_id", CoreRlsIsolationTest::ageCategory, "gender_policy", (c, t) -> "MIXED")),
                Map.entry("core.team_staff", Map.of("team_id", CoreRlsIsolationTest::team, "person_id", CoreRlsIsolationTest::person,
                        "role", (c, t) -> "COACH")),
                Map.entry("core.team_player", Map.of("team_id", CoreRlsIsolationTest::team,
                        "player_id", CoreRlsIsolationTest::player)),
                Map.entry("core.approval_request", Map.of("player_id", CoreRlsIsolationTest::player,
                        "requested_by_person_id", CoreRlsIsolationTest::person, "action", (c, t) -> "ADD_PLAYER")),
                Map.entry("core.eligibility_case", Map.of("player_id", CoreRlsIsolationTest::player,
                        "team_player_id", CoreRlsIsolationTest::teamPlayer, "reason", (c, t) -> "CATEGORY_TOO_LOW")));
    }

    /** Seasons of one tenant must not overlap: every fixture season is a distinct single day. */
    private static final AtomicInteger FIXTURE_SEQ = new AtomicInteger();
    private static final ThreadLocal<LocalDate> FIXTURE_DAY = new ThreadLocal<>();

    private static LocalDate nextFixtureDay() {
        LocalDate day = LocalDate.of(2000, 1, 1).plusDays(FIXTURE_SEQ.incrementAndGet());
        FIXTURE_DAY.set(day);
        return day;
    }

    private static LocalDate lastFixtureDay() {
        return FIXTURE_DAY.get();
    }

    private static Object season(Connection migrator, TenantId tenant) throws SQLException {
        LocalDate day = nextFixtureDay();
        UUID id = UUID.randomUUID();
        CoreDb.update(migrator, """
                insert into core.season (id, tenant_id, name, start_date, end_date, reference_year)
                values (?, ?, 'S', ?, ?, 2026)""", id, tenant.value(), day, day);
        return id;
    }

    private static Object ageCategory(Connection migrator, TenantId tenant) throws SQLException {
        int seq = FIXTURE_SEQ.incrementAndGet();
        UUID id = UUID.randomUUID();
        CoreDb.update(migrator, "insert into core.age_category (id, tenant_id, code, name, sort_rank) values (?, ?, ?, 'C', ?)",
                id, tenant.value(), "C" + seq, seq);
        return id;
    }

    private static Object team(Connection migrator, TenantId tenant) throws SQLException {
        UUID id = UUID.randomUUID();
        CoreDb.update(migrator, """
                insert into core.team (id, tenant_id, season_id, name, age_category_id, gender_policy)
                values (?, ?, ?, 'T', ?, 'MIXED')""", id, tenant.value(), season(migrator, tenant),
                ageCategory(migrator, tenant));
        return id;
    }

    private static Object teamPlayer(Connection migrator, TenantId tenant) throws SQLException {
        UUID id = UUID.randomUUID();
        CoreDb.update(migrator, """
                insert into core.team_player (id, tenant_id, team_id, player_id, joined_on)
                values (?, ?, ?, ?, date '2026-09-01')""", id, tenant.value(), team(migrator, tenant),
                player(migrator, tenant));
        return id;
    }

    /** tenant_settings.tenant_id references the registry: create the tenant row first. */
    private static Object tenantRowThenAgeRule(Connection migrator, TenantId tenant) throws SQLException {
        CoreDb.insertTenantRow(migrator, tenant.value(), "ACTIVE");
        return "BIRTH_YEAR";
    }

    private static Object person(Connection migrator, TenantId tenant) throws SQLException {
        return insertReturningId(migrator,
                "insert into core.person (id, tenant_id, given_name, family_name) values (?, ?, 'Fix', 'Ture')",
                tenant);
    }

    private static Object player(Connection migrator, TenantId tenant) throws SQLException {
        Object personId = person(migrator, tenant);
        UUID id = UUID.randomUUID();
        CoreDb.update(migrator, "insert into core.player (id, tenant_id, person_id) values (?, ?, ?)",
                id, tenant.value(), personId);
        return id;
    }

    private static Object insertReturningId(Connection migrator, String sql, TenantId tenant) throws SQLException {
        UUID id = UUID.randomUUID();
        try (PreparedStatement statement = migrator.prepareStatement(sql + " returning id")) {
            statement.setObject(1, id);
            statement.setObject(2, tenant.value());
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getObject(1);
            }
        }
    }
}
