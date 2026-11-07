package com.hoopsacademy.athlete.adapters.in.job;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.adapters.in.messaging.CoreEventDecoder;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent;
import com.hoopsacademy.athlete.support.CoreEvents;
import com.hoopsacademy.athlete.support.ReplicaDb;
import com.hoopsacademy.athlete.support.ReplicaFeed;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.testing.PostgresRlsResource;
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
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class ReplicaRetentionJobTest {

    @Inject ReplicaRetentionJob job;
    @Inject MeterRegistry metrics;
    @Inject CoreEventDecoder decoder;
    @Inject ApplyRosterEvent apply;

    @Test
    void theJobPrunesAndCountsWhatItDeleted() {
        TenantId tenant = TenantId.random();
        new ReplicaFeed(decoder, apply).apply(CoreEvents.team(tenant, UUID.randomUUID(), "U12",
                LocalDate.now().plusMonths(6)));
        ReplicaDb.execute(tenant, "update athlete.applied_event set applied_at = '"
                + Instant.now().minus(8, ChronoUnit.DAYS) + "'");
        long offset = Math.abs(UUID.randomUUID().getMostSignificantBits() % 1_000_000_000L);
        ReplicaDb.executeAsOwner("insert into athlete.parked_event (topic, partition, kafka_offset, reason, inspected_at)"
                + " values ('core.person', 0, " + offset + ", 'schema violation', '"
                + Instant.now().minus(31, ChronoUnit.DAYS) + "')");
        double applied = pruned("applied_event");
        double parked = pruned("parked_event");

        assertThat(job.run()).isTrue();

        assertThat(ReplicaDb.column(tenant, "select event_id from athlete.applied_event")).isEmpty();
        assertThat(pruned("applied_event") - applied).isGreaterThanOrEqualTo(1.0);
        assertThat(pruned("parked_event") - parked).isGreaterThanOrEqualTo(1.0);
        assertThat(ReplicaDb.parkedOffsets()).doesNotContain(offset);
    }

    private double pruned(String table) {
        Counter counter = metrics.find("hoops.roster.replica.pruned").tag("table", table).counter();
        return counter == null ? 0 : counter.count();
    }
}
