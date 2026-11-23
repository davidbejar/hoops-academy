package com.hoopsacademy.game.adapters.in.messaging;

import com.hoopsacademy.common.replica.ReplicaConsumer;
import com.hoopsacademy.common.replica.ReplicaRecord;
import com.hoopsacademy.game.application.replica.RosterEvent;
import io.smallrye.reactive.messaging.annotations.Blocking;
import jakarta.enterprise.context.ApplicationScoped;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.eclipse.microprofile.reactive.messaging.Incoming;

/**
 * Feeds the roster replica from core's roster topics (channel {@code core-roster}, ADR-0037), one record at a time in
 * partition order, through common's {@link ReplicaConsumer} (WP130, ADR-0062: tombstones skipped, invalid records
 * parked, the database work of a record tried {@code hoops.roster.replica.max-attempts} times with a backoff doubling
 * from {@code first-backoff}, then the channel fails).
 */
@ApplicationScoped
public class RosterEventConsumer {

    private final ReplicaConsumer<RosterEvent> consumer;

    RosterEventConsumer(ReplicaConsumer<RosterEvent> consumer) {
        this.consumer = consumer;
    }

    @Incoming("core-roster")
    @Blocking
    public void consume(ConsumerRecord<String, String> record) {
        consumer.consume(new ReplicaRecord(record.topic(), record.partition(), record.offset(), record.key(),
                record.value()));
    }
}
