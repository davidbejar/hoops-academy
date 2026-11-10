package com.hoopsacademy.game.application.replica;

import com.hoopsacademy.common.replica.ReplicaHistory;
import com.hoopsacademy.common.replica.ReplicaRetention;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.quarkus.runtime.Startup;
import jakarta.enterprise.context.Dependent;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Singleton;
import java.time.Clock;
import java.time.Duration;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Wires common's {@link ReplicaRetention} (WP98) to this service's replica tables and its
 * {@code hoops.roster.replica.retention.*} settings. Created at startup, so a retention below the topics' tombstone
 * retention fails the start.
 */
@Dependent
class ReplicaRetentionProducer {

    @Produces
    @Singleton
    @Startup
    ReplicaRetention replicaRetention(ReplicaHistory history, TenantScope tenantScope, Clock clock,
            @ConfigProperty(name = "hoops.roster.replica.retention.applied-events", defaultValue = "P7D")
            Duration appliedEvents,
            @ConfigProperty(name = "hoops.roster.replica.retention.parked-events", defaultValue = "P30D")
            Duration parkedEvents,
            @ConfigProperty(name = "hoops.roster.replica.retention.batch-size", defaultValue = "1000") int batchSize) {
        return new ReplicaRetention(history, tenantScope, clock, appliedEvents, parkedEvents, batchSize);
    }
}
