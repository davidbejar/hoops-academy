package com.hoopsacademy.core.adapters.in.scheduler;

import static org.assertj.core.api.Assertions.assertThat;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.application.usage.SnapshotTenantUsage;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.UsageStubs;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class UsageSnapshotJobTest {

    @Inject
    UsageSnapshotJob job;

    @Inject
    SnapshotTenantUsage snapshots;

    @InjectWireMock
    WireMockServer peers;

    private String first;
    private String second;
    private String suspended;

    @BeforeEach
    void twoActiveTenantsAndASuspendedOne() {
        KeycloakStubs.installDefaults(peers);
        UsageStubs.bothAnswer(peers);
        first = Members.newTenant();
        second = Members.newTenant();
        suspended = UUID.randomUUID().toString();
        CoreDb.tenant(suspended, "SUSPENDED");
    }

    @Test
    void anotherReplicaHoldingTheJobLockMakesThisRunSkipAndTheNextRunCatchesUp() throws Exception {
        try (java.sql.Connection otherReplica = com.hoopsacademy.common.testing.RlsTestDatabase.fromConfig().openAsApp();
                java.sql.PreparedStatement lock = otherReplica.prepareStatement("select pg_advisory_lock(?)")) {
            lock.setLong(1, com.hoopsacademy.common.tenancy.TenantScope.advisoryKey(UsageSnapshotJob.LOCK));
            lock.execute();

            job.run();
            assertThat(snapshots(first)).isZero();
        }

        job.run();
        assertThat(snapshots(first)).isEqualTo(1);
    }

    @Test
    void writesOneSnapshotPerActiveTenantAndTheSecondRunOfTheDayChangesNothing() {
        job.run();
        assertThat(snapshots(first)).isEqualTo(1);
        assertThat(snapshots(second)).isEqualTo(1);
        assertThat(snapshots(suspended)).isZero();

        job.run();
        job.run();
        assertThat(snapshots(first)).isEqualTo(1);
        assertThat(snapshots(second)).isEqualTo(1);
        assertThat(CoreDb.countAsPlatform("select count(*) from (select tenant_id, snapshot_date from core.usage_snapshot "
                + "group by 1, 2 having count(*) > 1) d")).isZero();
    }

    @Test
    void theSnapshotHoldsTheServicesOfTheTenant() {
        job.run();
        assertThat(CoreDb.countAsPlatform("select count(*) from core.usage_snapshot where tenant_id = ?::uuid "
                + "and report -> 'services' @> '[{\"service\":\"athlete\"}]'::jsonb "
                + "and jsonb_array_length(report -> 'unavailableServices') = 0", first)).isEqualTo(1);
    }

    @Test
    void aPartialRunIsReportedAndLaterCompletedWithoutADuplicate() {
        UsageStubs.down(peers, "athlete");
        SnapshotTenantUsage.Summary partial = snapshots.run();
        assertThat(partial.tenants()).isGreaterThanOrEqualTo(2);
        assertThat(partial.partial()).isEqualTo(partial.tenants());
        assertThat(partial.failedTenants()).isZero();
        assertThat(snapshots(first)).isEqualTo(1);

        UsageStubs.bothAnswer(peers);
        SnapshotTenantUsage.Summary complete = snapshots.run();
        assertThat(complete.partial()).isZero();
        assertThat(snapshots(first)).isEqualTo(1);
        assertThat(CoreDb.countAsPlatform("select count(*) from core.usage_snapshot where tenant_id = ?::uuid "
                + "and jsonb_array_length(report -> 'unavailableServices') = 0", first)).isEqualTo(1);
    }

    private long snapshots(String tenant) {
        return CoreDb.countAsPlatform("select count(*) from core.usage_snapshot where tenant_id = ?::uuid", tenant);
    }
}
