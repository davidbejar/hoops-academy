package com.hoopsacademy.common.replica;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.hoopsacademy.common.replica.ReplicaRetention.Report;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;

/**
 * What each service's scheduled retention job runs (WP130; the {@code @Scheduled} method stays per service, WP98): the
 * retention under the service's advisory lock, its deletions counted in
 * {@code hoops_roster_replica_pruned_total{table}}; a run another pod holds the lock for is skipped.
 */
class ReplicaHousekeepingTest {

    private static final String LOCK = "game.replica-retention";

    private final ReplicaRetention retention = mock(ReplicaRetention.class);
    private final TenantScope tenantScope = mock(TenantScope.class);
    private final SimpleMeterRegistry registry = new SimpleMeterRegistry();

    @Test
    void aRunUnderTheLockCountsWhatTheRetentionDeleted() {
        whenTheLockIs(true);
        when(retention.prune()).thenReturn(new Report(Instant.EPOCH, 12, 3, 1, Instant.EPOCH,
                List.of(new ParkedPosition("core.team", 0, 4), new ParkedPosition("core.team", 0, 5))));

        boolean ran = new ReplicaHousekeeping(retention, tenantScope, registry, LOCK).run();

        assertThat(ran).isTrue();
        assertThat(pruned("applied_event")).isEqualTo(12.0);
        assertThat(pruned("parked_event")).isEqualTo(2.0);
    }

    @Test
    void aRunWhileAnotherPodHoldsTheLockIsSkipped() {
        whenTheLockIs(false);

        boolean ran = new ReplicaHousekeeping(retention, tenantScope, registry, LOCK).run();

        assertThat(ran).isFalse();
        verifyNoInteractions(retention);
        assertThat(pruned("applied_event")).as("both counters exist before the first run").isZero();
        assertThat(pruned("parked_event")).isZero();
    }

    private void whenTheLockIs(boolean free) {
        when(tenantScope.runExclusive(eq(LOCK), any(Runnable.class))).thenAnswer(call -> {
            if (free) {
                ((Runnable) call.getArgument(1)).run();
            }
            return free;
        });
    }

    private double pruned(String table) {
        return registry.get("hoops.roster.replica.pruned").tag("table", table).counter().count();
    }
}
