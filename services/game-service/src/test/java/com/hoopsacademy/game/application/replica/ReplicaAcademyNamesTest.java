package com.hoopsacademy.game.application.replica;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import com.hoopsacademy.common.tenancy.TenantId;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;

/**
 * The academy's name as core last published it ({@code tenant.changed}), read from the replica whatever the roster
 * source: the consumer feeds the replica in both modes (ADR-0037). Unknown when core never said it to this replica.
 */
class ReplicaAcademyNamesTest {

    private static final TenantId TENANT = TenantId.random();
    private static final ZoneId MADRID = ZoneId.of("Europe/Madrid");

    private final FakeRosterQueries replica = new FakeRosterQueries();
    private final ReplicaAcademyNames names = new ReplicaAcademyNames(replica);

    @Test
    void theNameCoreLastPublished() {
        replica.tenants.put(TENANT, new ReplicaTenant(TenantStatus.ACTIVE, MADRID, "Lions Academy"));

        assertThat(names.find(TENANT)).contains("Lions Academy");
    }

    @Test
    void aTenantTheReplicaDoesNotKnowHasNoName() {
        assertThat(names.find(TENANT)).isEmpty();
    }

    @Test
    void aRowWrittenBeforeTheNameWasKeptHasNoName() {
        replica.tenants.put(TENANT, new ReplicaTenant(TenantStatus.ACTIVE, MADRID));

        assertThat(names.find(TENANT)).isEmpty();
    }

    @Test
    void aBlankNameIsNoName() {
        replica.tenants.put(TENANT, new ReplicaTenant(TenantStatus.ACTIVE, MADRID, " "));

        assertThat(names.find(TENANT)).isEmpty();
    }
}
