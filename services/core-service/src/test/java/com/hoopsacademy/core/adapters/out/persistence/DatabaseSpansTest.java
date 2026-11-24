package com.hoopsacademy.core.adapters.out.persistence;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.RecordedSpans;
import com.hoopsacademy.common.testing.RequestTrace;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.common.testing.SampledTrace;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.common.testing.TracingProfile;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.CoreTestResources;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import io.agroal.api.AgroalDataSource;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Scope;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import io.quarkus.test.security.TestSecurity;
import jakarta.inject.Inject;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * The SQL of a request shows in its trace (WP143, ADR-0074): with the SDK on, the team roster read yields database
 * spans under the request's server span, and no span carries a seeded name, e-mail, team name or the tenant id, not
 * even the span of a statement the database refuses (the driver's error text quotes the refused key).
 */
@QuarkusTest
@CoreTestResources
@TestProfile(TracingProfile.class)
@TestSecurity(user = TenantUser.SUBJECT)
class DatabaseSpansTest {

    private static final String GIVEN = "Zelphine";
    private static final String FAMILY = "Quorrowby";
    private static final String EMAIL = "zelphine.quorrowby@privacy.example";
    /** A team name already used in the season: inserting it again is a unique violation. */
    private static final String TAKEN_NAME = "Quorrowby Cubs";

    @Inject
    RecordedSpans recorded;

    @Inject
    AgroalDataSource dataSource;

    @Inject
    Tracer tracer;

    private String tenant;
    private UUID season;
    private UUID u14;
    private UUID team;

    @BeforeEach
    void twoTeamsOneWithAPlayer() {
        tenant = Members.newTenant();
        season = RosterDb.currentSeason(tenant);
        Map<String, UUID> categories = RosterDb.defaultCategories(tenant);
        u14 = categories.get("U14");
        team = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        RosterDb.team(tenant, season, TAKEN_NAME, u14, "MIXED");
        UUID person = CoreDb.person(tenant, null, GIVEN, FAMILY, EMAIL, LocalDate.of(RosterDb.YEAR - 11, 6, 15),
                "FEMALE", TenantRole.PLAYER);
        RosterDb.assignment(tenant, team, CoreDb.player(tenant, person), "7");
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void theRosterReadShowsItsSqlUnderTheRequestSpan() {
        RequestTrace trace = rosterRead();

        assertThat(trace.databaseSpans()).as("database spans of %s", trace.names()).isNotEmpty()
                .allSatisfy(span -> assertThat(trace.isUnderRoot(span)).as(span.getName()).isTrue());
        System.out.printf("WP143 core team roster read: %d spans, %d database spans%n", trace.spans().size(),
                trace.databaseSpans().size());
    }

    @Test
    void noSpanOfTheRosterReadCarriesAValueATenantOrAName() {
        RequestTrace trace = rosterRead();

        assertThat(trace.databaseSpans()).as("the check needs database spans").isNotEmpty();
        assertThat(trace.exportedText()).doesNotContain(GIVEN, FAMILY, EMAIL, tenant);
    }

    /**
     * A statement with no request or job span around it (the outbox poll, every second) starts no trace of its own;
     * the same statement under a span is exported.
     */
    @Test
    void aStatementOutsideAnySpanStartsNoTrace() throws SQLException {
        String orphan = "wp143_orphan_" + UUID.randomUUID().toString().replace("-", "");
        String traced = "wp143_traced_" + UUID.randomUUID().toString().replace("-", "");
        selectAs(orphan);
        SampledTrace trace = SampledTrace.random();
        Span probe = tracer.spanBuilder("traced select").setParent(trace.context()).startSpan();
        try (Scope scope = probe.makeCurrent()) {
            selectAs(traced);
        } finally {
            probe.end();
        }

        assertThat(recorded.of(trace).exportedText()).contains(traced);
        assertThat(recorded.all().exportedText()).doesNotContain(orphan);
    }

    /** Quarkus keeps the management paths out of traces, their database checks included, even when asked to trace. */
    @Test
    void aHealthCheckLeavesNoSpan() {
        SampledTrace health = SampledTrace.random();
        given().header("traceparent", health.traceparent()).get("/q/health/ready");
        rosterRead();

        assertThat(recorded.all().spans()).noneMatch(span -> span.getTraceId().equals(health.traceId()));
    }

    /** The race {@code ConstraintConflicts} turns into a 409: the database refuses the row and names the key. */
    @Test
    void theSpanOfARefusedStatementQuotesNeitherTheKeyNorTheTenant() {
        SampledTrace trace = SampledTrace.random();
        Span probe = tracer.spanBuilder("duplicate team").setParent(trace.context()).startSpan();
        try (Scope scope = probe.makeCurrent()) {
            assertThatThrownBy(this::insertTheTakenName).isInstanceOf(SQLException.class)
                    .hasFieldOrPropertyWithValue("SQLState", "23505");
        } finally {
            probe.end();
        }
        RequestTrace spans = recorded.of(trace);

        assertThat(spans.databaseSpans()).as("the refused insert is a span with its error")
                .anySatisfy(span -> assertThat(span.getEvents()).isNotEmpty());
        assertThat(spans.exportedText()).doesNotContain(TAKEN_NAME, tenant);
    }

    private void selectAs(String alias) throws SQLException {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement select = connection.prepareStatement("select 1 as " + alias)) {
            select.execute();
        }
    }

    private void insertTheTakenName() throws SQLException {
        try (Connection connection = dataSource.getConnection()) {
            connection.setAutoCommit(false);
            try (PreparedStatement insert = connection.prepareStatement("insert into core.team "
                    + "(id, tenant_id, season_id, name, age_category_id, gender_policy) values (?, ?::uuid, ?, ?, ?, ?)")) {
                RlsTestDatabase.bindTenant(connection, TenantId.parse(tenant));
                insert.setObject(1, UUID.randomUUID());
                insert.setString(2, tenant);
                insert.setObject(3, season);
                insert.setString(4, TAKEN_NAME);
                insert.setObject(5, u14);
                insert.setString(6, "MIXED");
                insert.executeUpdate();
            } finally {
                connection.rollback();
            }
        }
    }

    private RequestTrace rosterRead() {
        SampledTrace trace = SampledTrace.random();
        Contract.forTenant(tenant).header("traceparent", trace.traceparent())
                .get("/api/core/teams/" + team + "/players").then().statusCode(200);
        return recorded.of(trace);
    }
}
