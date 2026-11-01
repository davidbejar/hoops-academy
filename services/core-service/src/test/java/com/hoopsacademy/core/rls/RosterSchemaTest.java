package com.hoopsacademy.core.rls;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Database-level roster invariants as the runtime role core_app (ADR-0014). */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class RosterSchemaTest {

    private String tenant;

    @BeforeEach
    void tenant() {
        tenant = UUID.randomUUID().toString();
        CoreDb.tenant(tenant);
    }

    @Test
    void overlappingSeasonsOfOneTenantAreRejectedWithAnExclusionViolation() {
        asApp(tenant, app -> insertSeason(app, tenant, LocalDate.of(2026, 9, 1), LocalDate.of(2027, 6, 30)));
        asApp(tenant, app -> insertSeason(app, tenant, LocalDate.of(2027, 7, 1), LocalDate.of(2028, 6, 30)));
        assertThat(sqlStateOf(() -> asApp(tenant,
                app -> insertSeason(app, tenant, LocalDate.of(2027, 6, 30), LocalDate.of(2027, 8, 1)))))
                .isEqualTo("23P01");
    }

    @Test
    void movingASeasonOntoAnotherIsRejectedButTheSameDatesInAnotherTenantAreFine() {
        String other = UUID.randomUUID().toString();
        CoreDb.tenant(other);
        asApp(tenant, app -> insertSeason(app, tenant, LocalDate.of(2026, 9, 1), LocalDate.of(2027, 6, 30)));
        UUID second = asApp(tenant, app -> insertSeason(app, tenant, LocalDate.of(2027, 9, 1), LocalDate.of(2028, 6, 30)));
        assertThat(sqlStateOf(() -> asApp(tenant, app -> CoreDb.update(app,
                "update core.season set start_date = date '2027-06-01' where id = ?", second)))).isEqualTo("23P01");
        asApp(other, app -> insertSeason(app, other, LocalDate.of(2026, 9, 1), LocalDate.of(2027, 6, 30)));
        int renamed = asApp(tenant, app -> CoreDb.update(app, "update core.season set name = 'renamed' where id = ?", second));
        assertThat(renamed)
                .isEqualTo(1);
    }

    @Test
    void aPlayerHasAtMostOneOpenAssignmentPerTeamAndJerseysAreUniqueAmongOpenOnes() throws SQLException {
        UUID team = CoreDb.inTenant(tenant, c -> {
            UUID season = UUID.randomUUID();
            UUID category = UUID.randomUUID();
            UUID id = UUID.randomUUID();
            CoreDb.update(c, "insert into core.season (id, tenant_id, name, start_date, end_date, reference_year) "
                    + "values (?, ?::uuid, 'S', date '2026-09-01', date '2027-06-30', 2026)", season, tenant);
            CoreDb.update(c, "insert into core.age_category (id, tenant_id, code, name, max_age, sort_rank) "
                    + "values (?, ?::uuid, 'U12', 'U12', 11, 2)", category, tenant);
            CoreDb.update(c, "insert into core.team (id, tenant_id, season_id, name, age_category_id, gender_policy) "
                    + "values (?, ?::uuid, ?, 'T', ?, 'MIXED')", id, tenant, season, category);
            return id;
        });
        UUID player = CoreDb.player(tenant, CoreDb.person(tenant, "P", "One", null));
        UUID otherPlayer = CoreDb.player(tenant, CoreDb.person(tenant, "P", "Two", null));
        UUID first = asApp(tenant, app -> assign(app, team, player, "7"));
        assertThat(sqlStateOf(() -> asApp(tenant, app -> assign(app, team, player, null)))).isEqualTo("23505");
        assertThat(sqlStateOf(() -> asApp(tenant, app -> assign(app, team, otherPlayer, "7")))).isEqualTo("23505");
        asApp(tenant, app -> CoreDb.update(app, "update core.team_player set left_on = date '2026-10-01' where id = ?", first));
        asApp(tenant, app -> assign(app, team, player, "7"));
        asApp(tenant, app -> assign(app, team, otherPlayer, null));
    }

    /** One app-role transaction with the tenant bound (the setting is transaction-local). */
    private static <T> T asApp(String tenant, CoreDb.Work<T> work) {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp()) {
            app.setAutoCommit(false);
            CoreDb.bindTenant(app, TenantId.parse(tenant));
            T result = work.run(app);
            app.commit();
            return result;
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    private static String sqlStateOf(Runnable statement) {
        try {
            statement.run();
            return "none";
        } catch (IllegalStateException e) {
            return ((SQLException) e.getCause()).getSQLState();
        }
    }

    private static UUID insertSeason(Connection app, String tenant, LocalDate from, LocalDate to) throws SQLException {
        UUID id = UUID.randomUUID();
        CoreDb.update(app, "insert into core.season (id, tenant_id, name, start_date, end_date, reference_year) "
                + "values (?, ?::uuid, 'S', ?, ?, ?)", id, tenant, from, to, from.getYear());
        return id;
    }

    private static UUID assign(Connection app, UUID team, UUID player, String jersey) throws SQLException {
        UUID id = UUID.randomUUID();
        CoreDb.update(app, "insert into core.team_player (id, tenant_id, team_id, player_id, jersey_number, joined_on) "
                + "values (?, app.current_tenant(), ?, ?, ?, date '2026-09-01')", id, team, player, jersey);
        return id;
    }
}
