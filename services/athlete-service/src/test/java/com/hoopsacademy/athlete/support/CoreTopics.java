package com.hoopsacademy.athlete.support;

import java.time.Duration;
import java.util.Properties;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.function.BooleanSupplier;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;
import org.eclipse.microprofile.config.ConfigProvider;

/**
 * Publishes {@link CoreEvents} records to the Dev Services Redpanda the way core's publisher does (topic per aggregate,
 * key {@code <tenant>:<aggregate>}, a tombstone after a removal), so the consumer under test reads real records.
 */
public final class CoreTopics implements AutoCloseable {

    private final KafkaProducer<String, String> producer;

    public CoreTopics() {
        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG,
                ConfigProvider.getConfig().getValue("kafka.bootstrap.servers", String.class));
        props.put(ProducerConfig.ACKS_CONFIG, "all");
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        producer = new KafkaProducer<>(props);
    }

    public CoreTopics publish(CoreEvents.Record... records) {
        for (CoreEvents.Record record : records) {
            send(new ProducerRecord<>(record.topic(), record.key(), record.value()));
        }
        return this;
    }

    /** A null value for the key: what core sends after a removal so compaction can drop the key. */
    public CoreTopics tombstone(String topic, String key) {
        send(new ProducerRecord<>(topic, key, null));
        return this;
    }

    private void send(ProducerRecord<String, String> record) {
        try {
            producer.send(record).get(10, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        } catch (ExecutionException | TimeoutException e) {
            throw new IllegalStateException("could not publish to " + record.topic(), e);
        }
    }

    /** Polls {@code condition} until it holds or {@code timeout} passes (the consumer is asynchronous). */
    public static void await(String what, Duration timeout, BooleanSupplier condition) {
        long deadline = System.nanoTime() + timeout.toNanos();
        while (!safely(condition)) {
            if (System.nanoTime() > deadline) {
                throw new AssertionError("timed out after " + timeout + " waiting for " + what);
            }
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new IllegalStateException(e);
            }
        }
    }

    private static boolean safely(BooleanSupplier condition) {
        try {
            return condition.getAsBoolean();
        } catch (RuntimeException notYet) {
            return false;
        }
    }

    @Override
    public void close() {
        producer.close(Duration.ofSeconds(5));
    }
}
