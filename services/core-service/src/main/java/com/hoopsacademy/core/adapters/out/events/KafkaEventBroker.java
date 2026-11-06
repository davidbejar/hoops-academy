package com.hoopsacademy.core.adapters.out.events;

import com.hoopsacademy.core.application.port.EventBroker;
import io.smallrye.reactive.messaging.MutinyEmitter;
import io.smallrye.reactive.messaging.kafka.Record;
import io.smallrye.reactive.messaging.kafka.api.OutgoingKafkaRecordMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Duration;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Message;

/**
 * The Kafka producer of channel {@value #CHANNEL} (quarkus-messaging-kafka): the topic is set per record, the key is
 * the record's key, a null value is a tombstone. Each send waits for the broker's acknowledgement (acks=all,
 * idempotent producer) at most {@code hoops.outbox.send-timeout}.
 */
@ApplicationScoped
class KafkaEventBroker implements EventBroker {

    static final String CHANNEL = "core-events";

    private final MutinyEmitter<Record<String, String>> emitter;
    private final Duration timeout;

    KafkaEventBroker(@Channel(CHANNEL) MutinyEmitter<Record<String, String>> emitter,
            @ConfigProperty(name = "hoops.outbox.send-timeout", defaultValue = "PT10S") Duration timeout) {
        this.emitter = emitter;
        this.timeout = timeout;
    }

    @Override
    public void send(String topic, String key, String value) {
        Message<Record<String, String>> message = Message.of(Record.of(key, value))
                .addMetadata(OutgoingKafkaRecordMetadata.<String>builder().withTopic(topic).build());
        try {
            emitter.sendMessage(message).await().atMost(timeout);
        } catch (RuntimeException e) {
            throw new UnavailableException("No acknowledgement from the broker for a record on " + topic, e);
        }
    }
}
