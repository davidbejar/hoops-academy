package com.hoopsacademy.athlete.application.replica;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.athlete.adapters.in.messaging.CoreEventDecoder;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent.Outcome;
import com.hoopsacademy.athlete.support.CoreEvents;
import com.hoopsacademy.athlete.support.CoreEvents.Record;
import com.hoopsacademy.athlete.support.ReplicaDb;
import com.hoopsacademy.athlete.support.ReplicaFeed;
import com.hoopsacademy.common.replica.ParkedPosition;
import com.hoopsacademy.common.replica.ReplicaHistory;
import com.hoopsacademy.common.replica.ReplicaRetention;
import com.hoopsacademy.common.replica.ReplicaRetention.Report;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
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
 * Replica housekeeping (WP82, as game's): applied event ids older than the retention (never below the topics' 7-day
 * tombstone retention) are deleted in every tenant, in batches; parked records only once an operator inspected them,
 * and long enough ago. Runs on a fixed clock; rows are aged by setting their timestamps.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class ReplicaRetentionTest {

    private static final Instant NOW = Instant.now();
    private static final Clock CLOCK = Clock.fixed(NOW, ZoneOffset.UTC);
    private static final Duration WEEK = Duration.ofDays(7);
    private static final Duration MONTH = Duration.ofDays(30);
    private static final LocalDate SEASON_END = LocalDate.now().plusMonths(6);

    @Inject ReplicaHistory history;
    @Inject TenantScope tenantScope;
    @Inject CoreEventDecoder decoder;
    @Inject ApplyRosterEvent apply;

    ReplicaFeed feed;
    TenantId tenant;

    @BeforeEach
    void setUp() {
        feed = new ReplicaFeed(decoder, apply);
        tenant = TenantId.random();
    }

    @Test
    void appliedEventIdsOlderThanTheRetentionAreDeletedInEveryTenantInBatches() {
        TenantId other = TenantId.random();
        List<Record> old = List.of(team("A"), team("B"), team("C"), team("D"), team("E"));
        Record recent = team("F");
        Record otherOld = CoreEvents.team(other, UUID.randomUUID(), "Other", SEASON_END);
        feed.apply(old.toArray(Record[]::new));
        feed.apply(recent, otherOld);
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
        Record u12 = CoreEvents.team(tenant, team, "U12", SEASON_END);
        Record lions = CoreEvents.team(tenant, team, "U12 Lions", SEASON_END);
        feed.apply(u12, lions);
        age(tenant, u12, WEEK.plusDays(1));

        retention(WEEK, MONTH, 100).prune();

        assertThat(appliedIds(tenant)).containsExactly(lions.eventId());
        assertThat(feed.apply(u12)).as("a redelivery after the retention is stale, not applied").isEqualTo(Outcome.STALE);
        assertThat(ReplicaDb.column(tenant, "select name from athlete.team_ref")).containsExactly("U12 Lions");
    }

    @Test
    void aRetentionBelowTheTombstoneRetentionIsRefused() {
        assertThatThrownBy(() -> retention(WEEK.minusSeconds(1), MONTH, 100))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("hoops.roster.replica.retention.applied-events").hasMessageContaining("7 days");
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
        assertThat(ReplicaDb.parkedOffsets()).doesNotContain(base).contains(base + 1, base + 2);
    }

    private ReplicaRetention retention(Duration appliedEvents, Duration parkedEvents, int batchSize) {
        return new ReplicaRetention(history, tenantScope, CLOCK, appliedEvents, parkedEvents, batchSize);
    }

    private Record team(String name) {
        return CoreEvents.team(tenant, UUID.randomUUID(), name, SEASON_END);
    }

    /** Sets the applied event's {@code applied_at} to {@code age} before the fixed clock's now. */
    private static void age(TenantId tenant, Record record, Duration age) {
        ReplicaDb.execute(tenant, "update athlete.applied_event set applied_at = '" + NOW.minus(age)
                + "' where event_id = '" + record.eventId() + "'");
    }

    private static List<Object> appliedIds(TenantId tenant) {
        return ReplicaDb.column(tenant, "select event_id from athlete.applied_event order by applied_at desc");
    }

    private static void park(long offset, String inspectedAt) {
        ReplicaDb.executeAsOwner("insert into athlete.parked_event (topic, partition, kafka_offset, reason, inspected_at)"
                + " values ('core.team', 7, " + offset + ", 'schema violation', " + inspectedAt + ")");
    }
}
