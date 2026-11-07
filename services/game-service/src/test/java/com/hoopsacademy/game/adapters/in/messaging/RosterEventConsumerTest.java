package com.hoopsacademy.game.adapters.in.messaging;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.support.CoreEvents;
import com.hoopsacademy.game.support.CoreEvents.Record;
import com.hoopsacademy.game.support.CoreTopics;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.ReplicaDb;
import com.hoopsacademy.game.support.RosterBrokerResource;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * The consumer of core's roster topics against a Redpanda broker (RosterBrokerResource, the pinned image,
 * ADR-0036/0037): records of every topic reach the replica in their own tenant; a redelivered event is applied once, an
 * older one never wins, a tombstone is skipped, an invalid record is parked without stopping the records behind it; the
 * metrics count it.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
@WithTestResource(RosterBrokerResource.class)
class RosterEventConsumerTest {

    private static final Duration WAIT = Duration.ofSeconds(30);
    private static final LocalDate SEASON_END = LocalDate.parse("2027-06-30");

    @Inject
    MeterRegistry metrics;

    private TenantId tenant;
    private CoreEvents core;

    @BeforeEach
    void newTenant() {
        tenant = TenantId.random();
        core = CoreEvents.of(tenant);
    }

    @Test
    void recordsOfEveryTopicReachTheReplicaInTheirTenant() {
        UUID person = UUID.randomUUID();
        UUID player = UUID.randomUUID();
        UUID team = UUID.randomUUID();
        UUID link = UUID.randomUUID();
        TenantId other = TenantId.random();

        CoreTopics.publish(core.tenant("ACTIVE", "Europe/Madrid"),
                core.person(person, "Cora Coach", "sub-cora", true, TenantRole.COACH, TenantRole.PARENT),
                core.player(player, UUID.randomUUID(), "Kid Coach", "ACTIVE", LocalDate.parse("2014-02-03"), "MALE"),
                CoreEvents.of(other).team(team, UUID.randomUUID(), SEASON_END, "Other Lions"),
                core.team(team, UUID.randomUUID(), SEASON_END, "Lions"),
                core.assignment(UUID.randomUUID(), team, player, "9", LocalDate.parse("2026-09-01"), null, null),
                core.staff(team, person, "COACH"), core.link(link, person, player));

        await().atMost(WAIT).untilAsserted(() -> assertThat(count("game.guardian_link_ref")).isOne());
        for (String table : ReplicaDb.TABLES) {
            assertThat(count(table)).as(table).isEqualTo(table.equals("game.applied_event") ? 7 : 1);
        }
        assertThat(ReplicaDb.value(tenant, "select name from game.team_ref")).isEqualTo("Lions");
        assertThat(ReplicaDb.value(other, "select name from game.team_ref")).isEqualTo("Other Lions");
    }

    @Test
    void aRedeliveredEventIsAppliedOnce() {
        UUID team = UUID.randomUUID();
        UUID season = UUID.randomUUID();
        Record lions = core.team(team, season, SEASON_END, "Lions");
        double duplicates = events("core.team", "duplicate");

        CoreTopics.publish(lions, lions, core.team(team, season, SEASON_END, "Big Lions"));

        await().atMost(WAIT).untilAsserted(() -> assertThat(teamName(team)).isEqualTo("Big Lions"));
        assertThat(events("core.team", "duplicate") - duplicates).isEqualTo(1.0);
        assertThat(count("game.applied_event")).isEqualTo(2);
    }

    @Test
    void anOlderEventArrivingLateNeverWins() {
        UUID team = UUID.randomUUID();
        UUID season = UUID.randomUUID();
        Record newer = core.at(Instant.parse("2026-11-06T12:00:00Z")).team(team, season, SEASON_END, "Big Lions");
        Record older = core.at(Instant.parse("2026-11-06T11:00:00Z")).team(team, season, SEASON_END, "Lions");
        UUID marker = UUID.randomUUID();
        double stale = events("core.team", "stale");

        CoreTopics.publish(newer, older, core.team(marker, season, SEASON_END, "Marker"));

        await().atMost(WAIT).untilAsserted(() -> assertThat(teamName(marker)).isEqualTo("Marker"));
        assertThat(teamName(team)).isEqualTo("Big Lions");
        assertThat(events("core.team", "stale") - stale).isEqualTo(1.0);
    }

    @Test
    void aRemovalFollowedByItsTombstoneLeavesTheEntryRemoved() {
        UUID team = UUID.randomUUID();
        UUID coach = UUID.randomUUID();
        Record attached = core.staff(team, coach, "COACH");
        Record removal = core.staffRemoved(team, coach);
        UUID marker = UUID.randomUUID();
        double tombstones = events("core.team-staff", "tombstone");

        CoreTopics.publish(attached, removal, CoreEvents.tombstone(removal), core.staff(marker, coach, "COACH"));

        await().atMost(WAIT).untilAsserted(() -> assertThat(count("game.team_staff_ref")).isEqualTo(2));
        assertThat(ReplicaDb.rows(tenant, "select removed from game.team_staff_ref where team_id = '" + team + "'"))
                .containsExactly(Map.of("removed", true));
        assertThat(events("core.team-staff", "tombstone") - tombstones).isEqualTo(1.0);
    }

    /** WP82: every removal is applied as a soft removal; its tombstone is skipped, nothing is parked. */
    @Test
    void aRemovalIsAppliedAndItsTombstoneSkipped() {
        UUID team = UUID.randomUUID();
        UUID season = UUID.randomUUID();
        Record lions = core.team(team, season, SEASON_END, "Lions");
        Record removal = core.removed("team", team);
        UUID marker = UUID.randomUUID();
        double applied = events("core.team", "applied");
        double tombstones = events("core.team", "tombstone");
        double parked = parked("core.team");

        CoreTopics.publish(lions, removal, CoreEvents.tombstone(removal), core.team(marker, season, SEASON_END, "Marker"));

        await().atMost(WAIT).untilAsserted(() -> assertThat(teamName(marker)).isEqualTo("Marker"));
        assertThat(ReplicaDb.value(tenant, "select removed from game.team_ref where id = '" + team + "'")).isEqualTo(true);
        assertThat(teamName(team)).as("a removal keeps only the identity").isNull();
        assertThat(events("core.team", "applied") - applied).isEqualTo(3.0);
        assertThat(events("core.team", "tombstone") - tombstones).isEqualTo(1.0);
        assertThat(parked("core.team") - parked).isZero();
    }

    @Test
    void anInvalidRecordIsParkedAndTheRecordsBehindItAreApplied() {
        UUID team = UUID.randomUUID();
        Record valid = core.team(team, UUID.randomUUID(), SEASON_END, "Lions");
        Record broken = core.team(UUID.randomUUID(), UUID.randomUUID(), SEASON_END, "Broken");
        Record withoutName = new Record(broken.topic(), broken.key(), broken.value().replace("\"name\":\"Broken\",", ""));
        Record wrongKey = new Record(valid.topic(), "not-the-key", valid.value());
        double parked = parked("core.team");

        CoreTopics.publish(withoutName, wrongKey, valid);

        await().atMost(WAIT).untilAsserted(() -> assertThat(teamName(team)).isEqualTo("Lions"));
        assertThat(parked("core.team") - parked).isEqualTo(2.0);
        assertThat(ReplicaDb.parked()).filteredOn(row -> broken.eventId().equals(String.valueOf(row.get("event_id"))))
                .singleElement().satisfies(row -> {
                    assertThat(row).containsEntry("topic", "core.team").containsEntry("record_key", broken.key());
                    assertThat((String) row.get("reason")).contains("schema");
                    assertThat((Long) row.get("kafka_offset")).isNotNegative();
                });
        assertThat(ReplicaDb.parked()).filteredOn(row -> "not-the-key".equals(row.get("record_key"))).hasSize(1);
    }

    @Test
    void theLagIsTheAgeOfTheLastEventWhenItWasProcessed() {
        UUID team = UUID.randomUUID();

        CoreTopics.publish(core.at(Instant.now().minusSeconds(120)).team(team, UUID.randomUUID(), SEASON_END, "Lions"));

        await().atMost(WAIT).untilAsserted(() -> assertThat(teamName(team)).isEqualTo("Lions"));
        Gauge lag = metrics.find("hoops.roster.replica.lag").tag("topic", "core.team").gauge();
        assertThat(lag).isNotNull();
        assertThat(lag.value()).isBetween(119.0, 600.0);
        assertThat(metrics.find("hoops.roster.replica.parked").tag("topic", "core.tenant").counter())
                .as("every topic has its parked counter from the start").isNotNull();
    }

    private double events(String topic, String outcome) {
        Counter counter = metrics.find("hoops.roster.replica.events").tag("topic", topic).tag("outcome", outcome).counter();
        return counter == null ? 0 : counter.count();
    }

    private double parked(String topic) {
        Counter counter = metrics.find("hoops.roster.replica.parked").tag("topic", topic).counter();
        return counter == null ? 0 : counter.count();
    }

    private long count(String table) {
        return (Long) ReplicaDb.value(tenant, "select count(*) from " + table);
    }

    private Object teamName(UUID team) {
        return ReplicaDb.value(tenant, "select name from game.team_ref where id = '" + team + "'");
    }
}
