package com.hoopsacademy.core.application.platform;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.adapters.in.scheduler.OnboardingRepairJob;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.RosterEvents;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * The onboarding saga's crash window (WP3 open point): a process that dies after the registry insert and before the
 * tenant transaction leaves a tenant row without settings or admin. The repair job removes such rows once they are
 * older than the grace period; provisioned tenants (FK from tenant_settings) and fresh rows are left alone.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class OnboardingRepairTest {

    @Inject
    RepairOnboarding repair;

    @Inject
    OnboardingRepairJob job;

    @Test
    void anOldTenantWithoutSettingsIsRemovedWithItsSubscription() {
        String orphan = registryRowOnly("2 hours");
        String provisioned = UUID.randomUUID().toString();
        CoreDb.tenant(provisioned);
        age(provisioned, "2 hours");
        String fresh = registryRowOnly("1 minute");

        RepairOnboarding.Summary summary = repair.run();

        assertThat(summary.removed()).isGreaterThanOrEqualTo(1);
        assertThat(registryRows(orphan)).isZero();
        assertThat(CoreDb.countAsPlatform("select count(*) from billing.tenant_subscription where tenant_id = ?::uuid",
                orphan)).isZero();
        assertThat(registryRows(provisioned)).isEqualTo(1);
        assertThat(registryRows(fresh)).as("still inside the grace period").isEqualTo(1);
        List<JsonNode> removed = RosterEvents.of(orphan, "core.tenant");
        assertThat(removed).as("WP81: the deletion publishes tenant.removed").extracting(e -> e.get("type").asText())
                .containsExactly("tenant.removed");
        RosterEvents.assertValid("core.tenant", removed.getFirst());
        assertThat(removed.getFirst().get("aggregateId").asText()).isEqualTo(orphan);
        assertThat(RosterEvents.of(fresh, "core.tenant")).isEmpty();
    }

    @Test
    void theJobRunsTheRepairUnderItsClusterLock() {
        String orphan = registryRowOnly("3 hours");

        job.run();

        assertThat(registryRows(orphan)).isZero();
        assertThat(OnboardingRepairJob.LOCK).isEqualTo("core.onboarding-repair");
    }

    private static String registryRowOnly(String age) {
        String id = UUID.randomUUID().toString();
        CoreDb.inTenant(id, c -> {
            CoreDb.insertTenantRow(c, UUID.fromString(id), "ACTIVE");
            CoreDb.update(c, "insert into billing.tenant_subscription (tenant_id, plan_code) values (?, 'FREE')",
                    UUID.fromString(id));
            return null;
        });
        age(id, age);
        return id;
    }

    private static void age(String id, String age) {
        CoreDb.inTenant(id, c -> CoreDb.update(c,
                "update core.tenant set created_at = now() - cast(? as interval) where id = ?", age, UUID.fromString(id)));
    }

    private static long registryRows(String id) {
        return CoreDb.countAsPlatform("select count(*) from core.tenant where id = ?::uuid", id);
    }
}
