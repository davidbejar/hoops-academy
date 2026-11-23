package com.hoopsacademy.athlete.adapters.in.messaging;

import com.hoopsacademy.athlete.application.replica.RosterEvent;
import com.hoopsacademy.common.replica.ReplicaConsumer;
import com.hoopsacademy.common.replica.ReplicaRecord;
import io.smallrye.common.annotation.Blocking;
import jakarta.enterprise.context.ApplicationScoped;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.eclipse.microprofile.reactive.messaging.Incoming;

/**
 * Consumes core's seven roster topics (channel {@code core-roster}, group {@code athlete-service.roster}, only with
 * hoops.roster.consumer.enabled, on by default) one record at a time, in topic order, through common's
 * {@link ReplicaConsumer} (WP130, ADR-0062: the same loop, retry policy and meters as game's): a valid event is applied
 * in its own tenant, a record that breaks the contract is parked and skipped, a tombstone is skipped; the database work
 * of a record is tried {@code hoops.roster.replica.max-attempts} times with a backoff doubling from
 * {@code first-backoff}, then the channel fails (liveness DOWN, the pod restarts from the last committed offset).
 */
@ApplicationScoped
public class CoreRosterConsumer {

    private final ReplicaConsumer<RosterEvent> consumer;

    public CoreRosterConsumer(ReplicaConsumer<RosterEvent> consumer) {
        this.consumer = consumer;
    }

    @Incoming("core-roster")
    @Blocking
    public void consume(ConsumerRecord<String, String> record) {
        consumer.consume(new ReplicaRecord(record.topic(), record.partition(), record.offset(), record.key(),
                record.value()));
    }
}
