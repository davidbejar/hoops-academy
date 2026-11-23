package com.hoopsacademy.athlete.adapters.out.persistence;

import com.hoopsacademy.common.replica.JdbcParkedEvents;
import com.hoopsacademy.common.replica.JdbcReplicaHistory;
import com.hoopsacademy.common.replica.ParkedEvents;
import com.hoopsacademy.common.replica.ReplicaHistory;
import com.hoopsacademy.common.replica.ReplicaSchema;
import jakarta.enterprise.context.Dependent;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Singleton;
import javax.sql.DataSource;

/**
 * The replica's bookkeeping in schema {@code athlete} (V6, V9) through common's stores (WP130):
 * {@code applied_event} on the transaction's connection, the global {@code replica_tenant} and {@code parked_event}
 * without a tenant.
 */
@Dependent
class ReplicaBookkeepingProducer {

    private static final ReplicaSchema SCHEMA = new ReplicaSchema("athlete");

    @Produces
    @Singleton
    ReplicaHistory replicaHistory(DataSource dataSource) {
        return new JdbcReplicaHistory(dataSource, SCHEMA);
    }

    @Produces
    @Singleton
    ParkedEvents parkedEvents(DataSource dataSource) {
        return new JdbcParkedEvents(dataSource, SCHEMA);
    }
}
