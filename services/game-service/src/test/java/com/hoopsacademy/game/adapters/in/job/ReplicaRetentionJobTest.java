package com.hoopsacademy.game.adapters.in.job;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.adapters.in.messaging.RosterEventDecoder;
import com.hoopsacademy.game.application.replica.ReplicateRoster;
import com.hoopsacademy.game.support.CoreEvents;
import com.hoopsacademy.game.support.CoreEvents.Record;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.ReplicaDb;
import com.hoopsacademy.game.support.ReplicaFeed;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * The scheduled retention job (WP82): one replica runs it at a time (advisory lock), and what it deleted is counted on
 * /q/metrics ({@code hoops_roster_replica_pruned_total{table}}) and logged.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class ReplicaRetentionJobTest {

    @Inject
    ReplicaRetentionJob job;

    @Inject
    MeterRegistry metrics;

    @Inject
    RosterEventDecoder decoder;

    @Inject
    ReplicateRoster replicate;

    @Test
    void theJobPrunesAndCountsWhatItDeleted() {
        TenantId tenant = TenantId.random();
        Record lions = CoreEvents.of(tenant).team(UUID.randomUUID(), UUID.randomUUID(), LocalDate.parse("2027-06-30"),
                "Lions");
        ReplicaFeed.apply(decoder, replicate, lions);
        ReplicaDb.execute(tenant, "update game.applied_event set applied_at = '"
                + Instant.now().minus(8, ChronoUnit.DAYS) + "'");
        long offset = Math.abs(UUID.randomUUID().getMostSignificantBits() % 1_000_000_000L);
        ReplicaDb.executeAsOwner("insert into game.parked_event (topic, kafka_partition, kafka_offset, reason, "
                + "inspected_at) values ('core.person', 0, " + offset + ", 'schema violation', '"
                + Instant.now().minus(31, ChronoUnit.DAYS) + "')");
        double applied = pruned("applied_event");
        double parked = pruned("parked_event");

        assertThat(job.run()).isTrue();

        assertThat(ReplicaDb.value(tenant, "select count(*) from game.applied_event")).isEqualTo(0L);
        assertThat(pruned("applied_event") - applied).isGreaterThanOrEqualTo(1.0);
        assertThat(pruned("parked_event") - parked).isGreaterThanOrEqualTo(1.0);
        assertThat(ReplicaDb.parked()).extracting(row -> row.get("kafka_offset")).doesNotContain(offset);
    }

    private double pruned(String table) {
        Counter counter = metrics.find("hoops.roster.replica.pruned").tag("table", table).counter();
        return counter == null ? 0 : counter.count();
    }
}
