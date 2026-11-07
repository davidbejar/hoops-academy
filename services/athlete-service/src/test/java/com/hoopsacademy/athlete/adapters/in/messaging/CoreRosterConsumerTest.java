package com.hoopsacademy.athlete.adapters.in.messaging;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.athlete.adapters.out.persistence.ReplicaRosterRepository;
import com.hoopsacademy.athlete.application.TeamRoster;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.support.CoreEvents;
import com.hoopsacademy.athlete.support.CoreTopics;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RlsTestDatabase;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import jakarta.inject.Inject;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Duration;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Pattern;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * The consumer on a real broker (RosterBrokerResource, the pinned Redpanda): records of the seven roster topics reach
 * the replica, redeliveries and late older events change nothing, a record that breaks the contract is parked and the
 * next one is still applied, tombstones are skipped, and the outcomes are counted on /q/metrics.
 */
@QuarkusTest
@TestProfile(ReplicaProfile.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class CoreRosterConsumerTest {

    static final Duration TIMEOUT = Duration.ofSeconds(30);
    static final LocalDate SEASON_END = LocalDate.now().plusMonths(6);

    @Inject ReplicaRosterRepository replica;
    @Inject TenantScope tenantScope;

    CoreTopics topics;
    TenantId tenant;
    UUID team;

    @BeforeEach
    void setUp() {
        topics = new CoreTopics();
        tenant = TenantId.random();
        team = UUID.randomUUID();
        topics.publish(CoreEvents.tenant(tenant, "ACTIVE", "Europe/Madrid"));
    }

    @AfterEach
    void close() {
        topics.close();
    }

    @Test
    void recordsOfEveryTopicReachTheReplica() {
        UUID person = UUID.randomUUID();
        UUID player = UUID.randomUUID();
        UUID coach = UUID.randomUUID();
        topics.publish(CoreEvents.team(tenant, team, "U12", SEASON_END),
                CoreEvents.person(tenant, person, "Pia Player", null, List.of("PLAYER"), true),
                CoreEvents.player(tenant, player, person, "Pia Player", "ACTIVE", LocalDate.of(2013, 2, 3), "FEMALE"),
                CoreEvents.teamPlayer(tenant, UUID.randomUUID(), team, player, "9", LocalDate.of(2026, 9, 1), null, null),
                CoreEvents.teamStaff(tenant, team, coach, "COACH"),
                CoreEvents.guardianLink(tenant, UUID.randomUUID(), UUID.randomUUID(), player));

        CoreTopics.await("the roster", TIMEOUT, () -> roster().map(r -> r.playerIds().size() == 1 && r.staff().size() == 1)
                .orElse(false));
        CoreTopics.await("the guardian link (topics are read independently)", TIMEOUT,
                () -> count("athlete.guardian_link_ref") == 1);

        TeamRoster roster = roster().orElseThrow();
        assertThat(roster.teamName()).isEqualTo("U12");
        assertThat(roster.players()).containsExactly(new TeamRoster.RosterPlayer(new PlayerId(player), "Pia Player"));
        assertThat(count("athlete.guardian_link_ref")).isEqualTo(1);
    }

    @Test
    void redeliveriesAndLateOlderEventsChangeNothing() {
        CoreEvents.Record first = CoreEvents.team(tenant, team, "First", SEASON_END);
        CoreEvents.Record latest = CoreEvents.team(tenant, team, "Latest", SEASON_END);
        CoreEvents.Record older = CoreEvents.team(tenant, team, "Older", SEASON_END).at(first.occurredAt().minusSeconds(60));
        CoreEvents.Record marker = CoreEvents.team(tenant, UUID.randomUUID(), "Marker", SEASON_END);
        double duplicatesBefore = events("core.team", "duplicate");
        double staleBefore = events("core.team", "stale");

        topics.publish(first, latest, first, latest, older, marker);
        awaitTeam(marker);

        assertThat(roster().orElseThrow().teamName()).isEqualTo("Latest");
        assertThat(events("core.team", "duplicate")).isGreaterThanOrEqualTo(duplicatesBefore + 2);
        assertThat(events("core.team", "stale")).isGreaterThanOrEqualTo(staleBefore + 1);
    }

    @Test
    void aRecordThatBreaksTheContractIsParkedAndTheNextOneIsApplied() {
        CoreEvents.Record valid = CoreEvents.team(tenant, team, "U12", SEASON_END);
        CoreEvents.Record broken = valid.withValue(valid.value().replace("\"name\":\"U12\"", "\"name\":42"));
        double parkedBefore = parked("core.team");

        topics.publish(broken, CoreEvents.team(tenant, team, "After the broken one", SEASON_END));

        CoreTopics.await("the event after the broken one", TIMEOUT,
                () -> roster().map(r -> r.teamName().equals("After the broken one")).orElse(false));
        assertThat(parkedReasons(broken.key())).singleElement().satisfies(reason -> assertThat(reason).contains("/payload/name"));
        assertThat(parked("core.team")).isGreaterThanOrEqualTo(parkedBefore + 1);
    }

    @Test
    void aRecordWhoseKeyNamesAnotherTenantIsParkedAndNeverApplied() {
        TenantId victim = TenantId.random();
        CoreEvents.Record forged = CoreEvents.team(tenant, team, "Forged", SEASON_END)
                .withKey(victim + ":" + team);
        CoreEvents.Record marker = CoreEvents.team(tenant, UUID.randomUUID(), "Marker", SEASON_END);

        topics.publish(forged, marker);
        awaitTeam(marker);

        assertThat(roster()).isEmpty();
        assertThat(parkedReasons(victim + ":" + team)).singleElement().satisfies(reason -> assertThat(reason).contains("key"));
    }

    /** WP82: every removal is applied as a soft removal; its tombstone is skipped, nothing is parked. */
    @Test
    void aRemovalIsAppliedAndItsTombstoneSkipped() {
        CoreEvents.Record lions = CoreEvents.team(tenant, team, "U12", SEASON_END);
        CoreEvents.Record removal = CoreEvents.removed(tenant, "team", team);
        CoreEvents.Record marker = CoreEvents.team(tenant, UUID.randomUUID(), "Marker", SEASON_END);
        double appliedBefore = events("core.team", "applied");
        double tombstonesBefore = events("core.team", "tombstone");
        double parkedBefore = parked("core.team");

        topics.publish(lions, removal).tombstone(removal.topic(), removal.key()).publish(marker);
        awaitTeam(marker);

        assertThat(roster()).as("a removed team is not found").isEmpty();
        assertThat(events("core.team", "applied")).isEqualTo(appliedBefore + 3);
        assertThat(events("core.team", "tombstone")).isEqualTo(tombstonesBefore + 1);
        assertThat(parked("core.team")).isEqualTo(parkedBefore);
    }

    @Test
    void theAppRoleCannotReadWhatParkedRecordsSaid() throws SQLException {
        try (Connection app = RlsTestDatabase.fromConfig().openAsApp();
                PreparedStatement ps = app.prepareStatement("select reason from athlete.parked_event")) {
            assertThatThrownBy(ps::executeQuery).isInstanceOf(SQLException.class)
                    .satisfies(e -> assertThat(((SQLException) e).getSQLState()).isEqualTo("42501"));
        }
    }

    @Test
    void tombstonesAreSkipped() {
        UUID coach = UUID.randomUUID();
        UUID assistant = UUID.randomUUID();
        CoreEvents.Record teamEvent = CoreEvents.team(tenant, team, "U12", SEASON_END);
        CoreEvents.Record added = CoreEvents.teamStaff(tenant, team, coach, "COACH");
        CoreEvents.Record removed = CoreEvents.teamStaffRemoved(tenant, team, coach);
        CoreEvents.Record marker = CoreEvents.teamStaff(tenant, team, assistant, "ASSISTANT_COACH");
        double tombstonesBefore = events("core.team-staff", "tombstone");

        topics.publish(teamEvent, added, removed).tombstone(removed.topic(), removed.key()).publish(marker);

        CoreTopics.await("only the staff entry after the tombstone", TIMEOUT,
                () -> roster().map(r -> r.staff().equals(List.of(new PersonId(assistant)))).orElse(false));
        assertThat(events("core.team-staff", "tombstone")).isGreaterThanOrEqualTo(tombstonesBefore + 1);
    }

    @Test
    void theReplicaLagIsMeasuredPerTopic() {
        CoreEvents.Record marker = CoreEvents.team(tenant, team, "U12", SEASON_END);
        topics.publish(marker);
        awaitTeam(marker);

        assertThat(metrics()).containsPattern(Pattern.compile("hoops_roster_replica_lag_seconds\\{[^}]*topic=\"core.team\""));
        assertThat(metrics()).as("the Kafka client's offset lag (runbook)").contains("kafka_consumer_fetch_manager_records_lag");
    }

    private void awaitTeam(CoreEvents.Record teamEvent) {
        UUID id = UUID.fromString(teamEvent.json().get("aggregateId").asText());
        CoreTopics.await("team " + id, TIMEOUT,
                () -> tenantScope.runAs(tenant, () -> replica.teamRoster(tenant, new TeamId(id))) != null);
    }

    private Optional<TeamRoster> roster() {
        try {
            return Optional.of(tenantScope.runAs(tenant, () -> replica.teamRoster(tenant, new TeamId(team))));
        } catch (com.hoopsacademy.common.problem.NotFoundException notYet) {
            return Optional.empty();
        }
    }

    static String metrics() {
        return given().get("/q/metrics").then().statusCode(200).extract().asString();
    }

    /** The events_total counter of one topic and outcome (0 before the first one); an exemplar may follow the value. */
    static double events(String topic, String outcome) {
        Pattern line = Pattern.compile("^hoops_roster_replica_events_total\\{(?=[^}]*outcome=\"" + outcome + "\")(?=[^}]*topic=\""
                + Pattern.quote(topic) + "\")[^}]*} (\\S+)", Pattern.MULTILINE);
        var matcher = line.matcher(metrics());
        return matcher.find() ? Double.parseDouble(matcher.group(1)) : 0;
    }

    static double parked(String topic) {
        Pattern line = Pattern.compile("^hoops_roster_replica_parked_total\\{[^}]*topic=\"" + Pattern.quote(topic)
                + "\"[^}]*} (\\S+)", Pattern.MULTILINE);
        var matcher = line.matcher(metrics());
        return matcher.find() ? Double.parseDouble(matcher.group(1)) : 0;
    }

    private long count(String table) {
        try (Connection c = RlsTestDatabase.fromConfig().openAsApp()) {
            c.setAutoCommit(false);
            bind(c);
            try (PreparedStatement ps = c.prepareStatement("select count(*) from " + table + " where tenant_id = ?")) {
                ps.setObject(1, tenant.value());
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    return rs.getLong(1);
                }
            }
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    /** Read as the schema owner: the app role may only insert into parked_event. */
    private static List<String> parkedReasons(String key) {
        try (Connection c = RlsTestDatabase.fromConfig().openAsMigrator();
                PreparedStatement ps = c.prepareStatement("select reason from athlete.parked_event where record_key = ?")) {
            ps.setString(1, key);
            try (ResultSet rs = ps.executeQuery()) {
                List<String> reasons = new java.util.ArrayList<>();
                while (rs.next()) {
                    reasons.add(rs.getString(1));
                }
                return reasons;
            }
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    private void bind(Connection c) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("select set_config('app.tenant_id', ?, true)")) {
            ps.setString(1, tenant.toString());
            ps.execute();
        }
    }
}
