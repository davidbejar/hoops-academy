package com.hoopsacademy.core.testsupport;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.UUID;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.eclipse.microprofile.config.ConfigProvider;

/** Reads a topic of the Dev Services broker from the start, as a consumer that replays it would. */
public final class TopicReader {

    private static final ObjectMapper JSON = new ObjectMapper();

    /** One record: the key, the value (null = tombstone) and the value parsed. */
    public record Event(String key, String value) {
        public JsonNode json() {
            try {
                return value == null ? null : JSON.readTree(value);
            } catch (IOException e) {
                throw new UncheckedIOException(e);
            }
        }

        public boolean tombstone() {
            return value == null;
        }
    }

    private TopicReader() {}

    /** Every record of {@code topic} whose key starts with {@code <tenant>:}, in partition order. */
    public static List<Event> of(String topic, String tenant) {
        return all(topic).stream().filter(event -> event.key() != null && event.key().startsWith(tenant + ":")).toList();
    }

    public static List<Event> all(String topic) {
        Properties config = new Properties();
        config.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG,
                ConfigProvider.getConfig().getValue("kafka.bootstrap.servers", String.class));
        config.put(ConsumerConfig.GROUP_ID_CONFIG, "test-reader-" + UUID.randomUUID());
        config.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");
        try (KafkaConsumer<String, String> consumer = new KafkaConsumer<>(config, new StringDeserializer(),
                new StringDeserializer())) {
            List<TopicPartition> partitions = consumer.partitionsFor(topic, Duration.ofSeconds(10)).stream()
                    .map(info -> new TopicPartition(topic, info.partition())).toList();
            consumer.assign(partitions);
            consumer.seekToBeginning(partitions);
            var end = consumer.endOffsets(partitions, Duration.ofSeconds(10));
            List<Event> events = new ArrayList<>();
            long deadline = System.nanoTime() + Duration.ofSeconds(20).toNanos();
            while (partitions.stream().anyMatch(p -> consumer.position(p) < end.get(p)) && System.nanoTime() < deadline) {
                for (ConsumerRecord<String, String> record : consumer.poll(Duration.ofMillis(200))) {
                    events.add(new Event(record.key(), record.value()));
                }
            }
            return events;
        }
    }
}
