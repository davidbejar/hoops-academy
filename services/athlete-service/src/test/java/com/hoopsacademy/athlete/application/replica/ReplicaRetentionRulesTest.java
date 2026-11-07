package com.hoopsacademy.athlete.application.replica;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.athlete.application.replica.ReplicaRetention.Report;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * The retention rules without a database (PIT scope, WP82): cut-offs from the clock, batches until a short one, every
 * tenant entered in its own scope, a failing tenant counted and skipped, and the configuration limits.
 */
class ReplicaRetentionRulesTest {

    private static final Instant NOW = Instant.parse("2026-11-07T03:40:00Z");
    private static final Clock CLOCK = Clock.fixed(NOW, ZoneOffset.UTC);
    private static final Duration WEEK = Duration.ofDays(7);
    private static final Duration MONTH = Duration.ofDays(30);

    private final FakeHistory history = new FakeHistory();
    private final TenantScope tenantScope = mock(TenantScope.class);
    private final List<TenantId> entered = new ArrayList<>();

    @BeforeEach
    @SuppressWarnings("unchecked")
    void tenantScopeRunsTheWorkInTheTenant() {
        when(tenantScope.runAs(any(TenantId.class), any(Supplier.class))).thenAnswer(call -> {
            TenantId tenant = call.getArgument(0);
            entered.add(tenant);
            history.bound = tenant;
            try {
                return ((Supplier<?>) call.getArgument(1)).get();
            } finally {
                history.bound = null;
            }
        });
    }

    @Test
    void eachTenantIsPrunedInBatchesUntilABatchIsShort() {
        TenantId a = TenantId.random();
        TenantId b = TenantId.random();
        history.batches(a, 3, 3, 1);
        history.batches(b, 2);

        Report report = new ReplicaRetention(history, tenantScope, CLOCK, WEEK, MONTH, 3).prune();

        assertThat(report.appliedEvents()).isEqualTo(9);
        assertThat(report.tenants()).isEqualTo(2);
        assertThat(report.failedTenants()).isZero();
        assertThat(entered).containsExactly(a, a, a, b);
        assertThat(history.cutoffs).containsOnly(NOW.minus(WEEK));
        assertThat(history.limits).containsOnly(3);
    }

    @Test
    void aBatchExactlyAsLargeAsTheLimitAsksOnceMore() {
        TenantId a = TenantId.random();
        history.batches(a, 2, 0);

        Report report = new ReplicaRetention(history, tenantScope, CLOCK, WEEK, MONTH, 2).prune();

        assertThat(report.appliedEvents()).isEqualTo(2);
        assertThat(entered).containsExactly(a, a);
    }

    @Test
    void aFailingTenantIsCountedAndTheOthersArePruned() {
        TenantId broken = TenantId.random();
        TenantId fine = TenantId.random();
        history.batches(broken);
        history.failing.put(broken, new IllegalStateException("database blip"));
        history.batches(fine, 4);

        Report report = new ReplicaRetention(history, tenantScope, CLOCK, WEEK, MONTH, 10).prune();

        assertThat(report.failedTenants()).isOne();
        assertThat(report.appliedEvents()).isEqualTo(4);
        assertThat(report.tenants()).isEqualTo(2);
    }

    @Test
    void parkedRecordsAreAskedForWithTheInspectionCutOff() {
        ParkedPosition gone = new ParkedPosition("core.team", 0, 42);
        history.parked = List.of(gone);

        Report report = new ReplicaRetention(history, tenantScope, CLOCK, Duration.ofDays(10), MONTH, 10).prune();

        assertThat(report.parkedEvents()).containsExactly(gone);
        assertThat(report.inspectedBefore()).isEqualTo(NOW.minus(MONTH));
        assertThat(history.inspectedBefore).isEqualTo(NOW.minus(MONTH));
        assertThat(report.appliedBefore()).isEqualTo(NOW.minus(Duration.ofDays(10)));
        assertThat(gone).hasToString("core.team-0@42");
    }

    @Test
    void theLimitsOfTheConfigurationAreInclusive() {
        assertThatCode(() -> new ReplicaRetention(history, tenantScope, CLOCK, WEEK, Duration.ZERO, 1))
                .doesNotThrowAnyException();
        assertThatThrownBy(() -> new ReplicaRetention(history, tenantScope, CLOCK, WEEK.minusNanos(1), MONTH, 1))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("applied-events");
        assertThatThrownBy(() -> new ReplicaRetention(history, tenantScope, CLOCK, WEEK, Duration.ofNanos(-1), 1))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("parked-events");
        assertThatThrownBy(() -> new ReplicaRetention(history, tenantScope, CLOCK, WEEK, MONTH, 0))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("batch-size");
    }

    @Test
    void theReportKeepsItsOwnCopyOfTheParkedPositions() {
        List<ParkedPosition> positions = new ArrayList<>(List.of(new ParkedPosition("core.team", 0, 1)));
        Report report = new Report(NOW, 0, 0, 0, NOW, positions);

        positions.clear();

        assertThat(report.parkedEvents()).hasSize(1);
        assertThatThrownBy(() -> report.parkedEvents().clear()).isInstanceOf(UnsupportedOperationException.class);
    }

    /** Answers each tenant's batches in order (0 once they run out); deletes only inside a tenant scope. */
    private static final class FakeHistory implements ReplicaHistory {

        private final Map<TenantId, Deque<Integer>> batches = new HashMap<>();
        private final Map<TenantId, RuntimeException> failing = new HashMap<>();
        private final List<TenantId> tenants = new ArrayList<>();
        private final List<Instant> cutoffs = new ArrayList<>();
        private final List<Integer> limits = new ArrayList<>();
        private TenantId bound;
        private List<ParkedPosition> parked = List.of();
        private Instant inspectedBefore;

        void batches(TenantId tenant, Integer... sizes) {
            tenants.add(tenant);
            batches.put(tenant, new ArrayDeque<>(List.of(sizes)));
        }

        @Override
        public List<TenantId> tenants() {
            return List.copyOf(tenants);
        }

        @Override
        public int deleteAppliedBefore(Instant before, int limit) {
            assertThat(bound).as("applied events are deleted inside a tenant scope").isNotNull();
            if (failing.containsKey(bound)) {
                throw failing.get(bound);
            }
            cutoffs.add(before);
            limits.add(limit);
            Integer next = batches.get(bound).poll();
            return next == null ? 0 : next;
        }

        @Override
        public List<ParkedPosition> deleteParkedInspectedBefore(Instant inspectedBefore) {
            assertThat(bound).as("parked records have no tenant").isNull();
            this.inspectedBefore = inspectedBefore;
            return parked;
        }
    }
}
