package com.hoopsacademy.core.adapters.out.events;

import com.hoopsacademy.core.application.port.EventBroker;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.binder.kafka.KafkaClientMetrics;
import io.smallrye.common.annotation.Identifier;
import jakarta.annotation.PreDestroy;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.function.Supplier;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * The Kafka producer of the outbox publisher: the topic is set per record, the key is the record's key, a null value
 * is a tombstone. Each send waits for the broker's acknowledgement (acks=all, idempotent producer) at most
 * {@code hoops.outbox.send-timeout}. The client settings are the {@code kafka.*} configuration (bootstrap, SASL,
 * timeouts; Dev Services in tests); acks, idempotence and the serializers are fixed here.
 *
 * <p>Recovery (WP81, ADR-0008 amendment): an idempotent producer whose first producer-id request failed (core started
 * before its broker user existed, WP71) never asks again and lets every record expire, even once the login works.
 * After {@code hoops.outbox.producer-reset-after} consecutive failed sends the producer is closed and a new one is
 * created at the next send ({@code hoops_outbox_producer_resets_total}). A broker that is merely down costs one new
 * producer per that many failed runs; the outbox keeps the events either way.
 */
@ApplicationScoped
class KafkaEventBroker implements EventBroker {

    private static final Logger LOG = Logger.getLogger(KafkaEventBroker.class);
    static final String CLIENT_ID = "core-events";

    private final Supplier<Producer<String, String>> producers;
    private final Duration timeout;
    private final int resetAfter;
    private final Counter resets;
    private final MeterRegistry registry;

    private Producer<String, String> producer;
    private KafkaClientMetrics producerMetrics;
    private int consecutiveFailures;

    @Inject
    KafkaEventBroker(@Identifier("default-kafka-broker") Map<String, Object> kafka, MeterRegistry registry,
            @ConfigProperty(name = "hoops.outbox.send-timeout", defaultValue = "PT10S") Duration timeout,
            @ConfigProperty(name = "hoops.outbox.producer-reset-after", defaultValue = "3") int resetAfter) {
        this(() -> new KafkaProducer<>(producerConfig(kafka)), timeout, resetAfter, registry);
    }

    KafkaEventBroker(Supplier<Producer<String, String>> producers, Duration timeout, int resetAfter,
            MeterRegistry registry) {
        if (resetAfter < 1) {
            throw new IllegalArgumentException("hoops.outbox.producer-reset-after must be at least 1: " + resetAfter);
        }
        this.producers = producers;
        this.registry = registry;
        this.timeout = timeout;
        this.resetAfter = resetAfter;
        this.resets = Counter.builder("hoops.outbox.producer.resets")
                .description("Kafka producers the outbox publisher replaced after consecutive failed sends")
                .register(registry);
    }

    @Override
    public synchronized void send(String topic, String key, String value) {
        try {
            current().send(new ProducerRecord<>(topic, key, value)).get(timeout.toMillis(), TimeUnit.MILLISECONDS);
            consecutiveFailures = 0;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw failed(topic, e);
        } catch (ExecutionException e) {
            throw failed(topic, e.getCause());
        } catch (TimeoutException | RuntimeException e) {
            throw failed(topic, e);
        }
    }

    @PreDestroy
    synchronized void close() {
        if (producer != null) {
            producerMetrics.close();
            producer.close(Duration.ZERO);
            producer = null;
        }
    }

    private Producer<String, String> current() {
        if (producer == null) {
            producer = producers.get();
            // the Kafka client's own metrics on /q/metrics (kafka_producer_*), for this producer's lifetime
            producerMetrics = new KafkaClientMetrics(producer);
            producerMetrics.bindTo(registry);
        }
        return producer;
    }

    private UnavailableException failed(String topic, Throwable cause) {
        consecutiveFailures++;
        if (consecutiveFailures >= resetAfter) {
            LOG.warnf("%d sends in a row failed (last: %s); replacing the Kafka producer", consecutiveFailures,
                    cause.getClass().getSimpleName());
            close();
            consecutiveFailures = 0;
            resets.increment();
        }
        return new UnavailableException("No acknowledgement from the broker for a record on " + topic, cause);
    }

    static Map<String, Object> producerConfig(Map<String, Object> kafka) {
        Map<String, Object> config = new HashMap<>(kafka);
        config.remove("group.id");
        config.put(ProducerConfig.CLIENT_ID_CONFIG, CLIENT_ID);
        config.put(ProducerConfig.ACKS_CONFIG, "all");
        config.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        config.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        config.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        return config;
    }
}
