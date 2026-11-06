package com.hoopsacademy.game.support;

import com.hoopsacademy.game.support.CoreEvents.Record;
import java.util.Properties;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;
import org.eclipse.microprofile.config.ConfigProvider;

/** Publishes fixture records to the Dev Services broker's core.* topics, in order, as core's publisher does. */
public final class CoreTopics {

    private CoreTopics() {}

    public static void publish(Record... records) {
        Properties config = new Properties();
        config.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG,
                ConfigProvider.getConfig().getValue("kafka.bootstrap.servers", String.class));
        config.put(ProducerConfig.ACKS_CONFIG, "all");
        try (KafkaProducer<String, String> producer = new KafkaProducer<>(config, new StringSerializer(),
                new StringSerializer())) {
            for (Record record : records) {
                producer.send(new ProducerRecord<>(record.topic(), record.key(), record.value())).get(10, TimeUnit.SECONDS);
            }
        } catch (ExecutionException | TimeoutException e) {
            throw new IllegalStateException("could not publish the fixture records", e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
    }
}
