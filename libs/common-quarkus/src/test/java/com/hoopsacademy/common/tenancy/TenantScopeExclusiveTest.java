package com.hoopsacademy.common.tenancy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.agroal.api.AgroalDataSource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;

/** {@link TenantScope#runExclusive}: one replica runs a job, the others skip it (pg_try_advisory_xact_lock). */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class TenantScopeExclusiveTest {

    @Inject
    TenantScope tenantScope;

    @Inject
    AgroalDataSource dataSource;

    @Test
    void runsTheWorkWhenNobodyHoldsTheLock() {
        AtomicInteger runs = new AtomicInteger();

        boolean ran = tenantScope.runExclusive("test.free", runs::incrementAndGet);

        assertThat(ran).isTrue();
        assertThat(runs).hasValue(1);
    }

    @Test
    void aSecondCallerWithTheSameKeySkipsWhileTheFirstRunsAndOtherKeysAreIndependent() throws Exception {
        CountDownLatch holding = new CountDownLatch(1);
        CountDownLatch release = new CountDownLatch(1);
        AtomicInteger runs = new AtomicInteger();

        CompletableFuture<Boolean> first = CompletableFuture.supplyAsync(() -> tenantScope.runExclusive("test.busy", () -> {
            runs.incrementAndGet();
            holding.countDown();
            await(release);
        }));
        assertThat(holding.await(10, TimeUnit.SECONDS)).isTrue();

        boolean secondRan = CompletableFuture.supplyAsync(() -> tenantScope.runExclusive("test.busy", runs::incrementAndGet))
                .get(10, TimeUnit.SECONDS);
        boolean otherKeyRan = CompletableFuture.supplyAsync(() -> tenantScope.runExclusive("test.other", () -> { }))
                .get(10, TimeUnit.SECONDS);
        release.countDown();

        assertThat(first.get(10, TimeUnit.SECONDS)).isTrue();
        assertThat(secondRan).isFalse();
        assertThat(otherKeyRan).isTrue();
        assertThat(runs).hasValue(1);
        assertThat(tenantScope.runExclusive("test.busy", runs::incrementAndGet)).as("released after commit").isTrue();
    }

    @Test
    void theLockIsReleasedWhenTheWorkFails() {
        assertThatThrownBy(() -> tenantScope.runExclusive("test.failing", () -> {
            throw new IllegalStateException("job failed");
        })).hasMessage("job failed");

        assertThat(tenantScope.runExclusive("test.failing", () -> { })).isTrue();
    }

    @Test
    void tenantWorkInsideAnExclusiveJobRunsInItsOwnTenantTransaction() {
        TenantId tenant = TenantId.random();
        AtomicReference<String> seen = new AtomicReference<>();

        CompletableFuture.runAsync(() -> tenantScope.runExclusive("test.nested",
                () -> tenantScope.runAs(tenant, () -> seen.set(SessionProbe.of(dataSource).tenantSetting())))).join();

        assertThat(seen.get()).isEqualTo(tenant.toString());
    }

    @Test
    void theWorkRunsOutsideTheLockTransactionSoItsOwnTransactionsCommitIndependently() {
        AtomicReference<Boolean> activeInside = new AtomicReference<>();

        CompletableFuture.runAsync(() -> tenantScope.runExclusive("test.isolated",
                () -> activeInside.set(io.quarkus.narayana.jta.QuarkusTransaction.isActive()))).join();

        assertThat(activeInside.get()).isFalse();
    }

    @Test
    void callingItInsideATransactionIsAProgrammingError() {
        assertThatThrownBy(() -> io.quarkus.narayana.jta.QuarkusTransaction.requiringNew()
                .run(() -> tenantScope.runExclusive("test.nested-tx", () -> { })))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void lockKeysMapToStableDistinctAdvisoryKeys() {
        assertThat(TenantScope.advisoryKey("athlete.materialisation")).isEqualTo(TenantScope.advisoryKey("athlete.materialisation"));
        assertThat(TenantScope.advisoryKey("athlete.materialisation")).isNotEqualTo(TenantScope.advisoryKey("core.eligibility-sweep"));
    }

    private static void await(CountDownLatch latch) {
        try {
            latch.await(10, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
