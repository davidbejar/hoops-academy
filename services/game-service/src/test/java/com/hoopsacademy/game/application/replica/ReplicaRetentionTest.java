package com.hoopsacademy.game.application.replica;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.adapters.in.messaging.RosterEventDecoder;
import com.hoopsacademy.game.application.replica.ReplicaRetention.Report;
import com.hoopsacademy.game.application.replica.ReplicateRoster.Outcome;
import com.hoopsacademy.game.support.CoreEvents;
import com.hoopsacademy.game.support.CoreEvents.Record;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.ReplicaDb;
import com.hoopsacademy.game.support.ReplicaFeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Replica housekeeping (WP82): applied event ids older than the retention (never below the topics' 7-day tombstone
 * retention) are deleted in every tenant, in batches; parked records only once an operator inspected them, and long
 * enough ago. Runs on a fixed clock; rows are aged by setting their timestamps.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class ReplicaRetentionTest {

    private static final Instant NOW = Instant.now();
    private static final Clock CLOCK = Clock.fixed(NOW, ZoneOffset.UTC);
    private static final Duration WEEK = Duration.ofDays(7);
    private static final Duration MONTH = Duration.ofDays(30);
    private static final LocalDate SEASON_END = LocalDate.parse("2027-06-30");

    @Inject
    ReplicaHistory history;

    @Inject
    TenantScope tenantScope;

    @Inject
    RosterEventDecoder decoder;

    @Inject
    ReplicateRoster replicate;

    private TenantId tenant;
    private CoreEvents core;

    @BeforeEach
    void newTenant() {
        tenant = TenantId.random();
        core = CoreEvents.of(tenant);
    }

    @Test
    void appliedEventIdsOlderThanTheRetentionAreDeletedInEveryTenantInBatches() {
        TenantId other = TenantId.random();
        List<Record> old = List.of(team("A"), team("B"), team("C"), team("D"), team("E"));
        Record recent = team("F");
        Record otherOld = CoreEvents.of(other).team(UUID.randomUUID(), UUID.randomUUID(), SEASON_END, "Other");
        ReplicaFeed.apply(decoder, replicate, old.toArray(Record[]::new));
        ReplicaFeed.apply(decoder, replicate, recent, otherOld);
        old.forEach(record -> age(tenant, record, WEEK.plusMinutes(1)));
        age(tenant, recent, WEEK.minusMinutes(1));
        age(other, otherOld, WEEK.plusDays(3));

        Report report = retention(WEEK, MONTH, 2).prune();

        assertThat(appliedIds(tenant)).containsExactly(recent.eventId());
        assertThat(appliedIds(other)).isEmpty();
        assertThat(report.appliedEvents()).as("at least ours; other test classes may have aged rows too")
                .isGreaterThanOrEqualTo(6);
        assertThat(report.appliedBefore()).isEqualTo(NOW.minus(WEEK));
        assertThat(report.failedTenants()).isZero();
    }

    @Test
    void anEventWhoseIdWasPrunedCannotOverwriteANewerState() {
        UUID team = UUID.randomUUID();
        UUID season = UUID.randomUUID();
        Record lions = core.team(team, season, SEASON_END, "Lions");
        Record bigLions = core.team(team, season, SEASON_END, "Big Lions");
        ReplicaFeed.apply(decoder, replicate, lions, bigLions);
        age(tenant, lions, WEEK.plusDays(1));

        retention(WEEK, MONTH, 100).prune();

        assertThat(appliedIds(tenant)).containsExactly(bigLions.eventId());
        assertThat(apply(lions)).as("a redelivery after the retention is stale, not applied").isEqualTo(Outcome.STALE);
        assertThat(ReplicaDb.value(tenant, "select name from game.team_ref")).isEqualTo("Big Lions");
    }

    @Test
    void aRetentionBelowTheTombstoneRetentionIsRefused() {
        assertThatThrownBy(() -> retention(WEEK.minusSeconds(1), MONTH, 100))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("hoops.roster.replica.retention.applied-events").hasMessageContaining("P7D");
        assertThatThrownBy(() -> retention(WEEK, MONTH, 0)).isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("hoops.roster.replica.retention.batch-size");
        assertThatThrownBy(() -> retention(WEEK, Duration.ofDays(-1), 100))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("hoops.roster.replica.retention.parked-events");
    }

    @Test
    void parkedRecordsGoOnlyLongEnoughAfterAnOperatorInspectedThem() {
        long base = Math.abs(UUID.randomUUID().getMostSignificantBits() % 1_000_000_000L);
        park(base, "'" + NOW.minus(MONTH).minusSeconds(1) + "'");
        park(base + 1, "'" + NOW.minus(MONTH).plusSeconds(60) + "'");
        park(base + 2, "null");

        Report report = retention(WEEK, MONTH, 100).prune();

        assertThat(report.parkedEvents()).contains(new ParkedPosition("core.team", 7, base))
                .doesNotContain(new ParkedPosition("core.team", 7, base + 1), new ParkedPosition("core.team", 7, base + 2));
        assertThat(report.inspectedBefore()).isEqualTo(NOW.minus(MONTH));
        assertThat(ReplicaDb.parked()).extracting(row -> row.get("kafka_offset"))
                .doesNotContain(base).contains(base + 1, base + 2);
    }

    private ReplicaRetention retention(Duration appliedEvents, Duration parkedEvents, int batchSize) {
        return new ReplicaRetention(history, tenantScope, CLOCK, appliedEvents, parkedEvents, batchSize);
    }

    private Record team(String name) {
        return core.team(UUID.randomUUID(), UUID.randomUUID(), SEASON_END, name);
    }

    private Outcome apply(Record record) {
        return replicate.apply(((RosterEventDecoder.Decoded.Valid) decoder.decode(record.topic(), record.key(),
                record.value())).event());
    }

    /** Sets the applied event's {@code applied_at} to {@code age} before the fixed clock's now. */
    private static void age(TenantId tenant, Record record, Duration age) {
        ReplicaDb.execute(tenant, "update game.applied_event set applied_at = '" + NOW.minus(age) + "' where event_id = '"
                + record.eventId() + "'");
    }

    private static List<Object> appliedIds(TenantId tenant) {
        return ReplicaDb.rows(tenant, "select event_id::text from game.applied_event order by applied_at desc").stream()
                .map(row -> row.values().iterator().next()).toList();
    }

    private static void park(long offset, String inspectedAt) {
        ReplicaDb.executeAsOwner("insert into game.parked_event (topic, kafka_partition, kafka_offset, reason, inspected_at)"
                + " values ('core.team', 7, " + offset + ", 'schema violation', " + inspectedAt + ")");
    }
}
