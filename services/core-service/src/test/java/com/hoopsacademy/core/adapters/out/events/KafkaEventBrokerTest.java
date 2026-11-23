package com.hoopsacademy.core.adapters.out.events;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.core.application.port.EventBroker;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import org.apache.kafka.clients.producer.MockProducer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.errors.SaslAuthenticationException;
import org.apache.kafka.common.serialization.StringSerializer;
import org.junit.jupiter.api.Test;

/**
 * WP81: the broker adapter replaces a producer that keeps failing (an idempotent producer whose first login failed
 * never gets a producer id and lets every record expire, WP71), and only such a producer.
 */
class KafkaEventBrokerTest {

    private static final Duration TIMEOUT = Duration.ofMillis(200);
    private static final org.apache.kafka.common.MetricName SEND_TOTAL = new org.apache.kafka.common.MetricName(
            "record-send-total", "producer-metrics", "", Map.of("client-id", KafkaEventBroker.CLIENT_ID));

    private final List<MockProducer<String, String>> created = new ArrayList<>();
    private final SimpleMeterRegistry registry = new SimpleMeterRegistry();
    private final AtomicBoolean brokerAnswers = new AtomicBoolean(false);

    private KafkaEventBroker broker(int resetAfter) {
        return new KafkaEventBroker(this::producer, TIMEOUT, resetAfter, registry);
    }

    /** A producer that acknowledges every record while the broker answers, and fails it otherwise. */
    private MockProducer<String, String> producer() {
        MockProducer<String, String> producer = new MockProducer<>(false, null, new StringSerializer(),
                new StringSerializer()) {
            @Override
            public synchronized java.util.concurrent.Future<org.apache.kafka.clients.producer.RecordMetadata> send(
                    ProducerRecord<String, String> record, org.apache.kafka.clients.producer.Callback callback) {
                var future = super.send(record, callback);
                if (brokerAnswers.get()) {
                    completeNext();
                } else {
                    errorNext(new SaslAuthenticationException("SASL authentication failed"));
                }
                return future;
            }
        };
        producer.setMockMetrics(SEND_TOTAL, new org.apache.kafka.common.metrics.KafkaMetric(new Object(), SEND_TOTAL,
                (org.apache.kafka.common.metrics.Measurable) (config, now) -> 1.0,
                new org.apache.kafka.common.metrics.MetricConfig(), org.apache.kafka.common.utils.Time.SYSTEM));
        created.add(producer);
        return producer;
    }

    @Test
    void sendsTheRecordWithItsTopicKeyAndValueAndATombstoneAsNull() {
        brokerAnswers.set(true);
        KafkaEventBroker broker = broker(3);

        broker.send("core.team", "t:a", "{}");
        broker.send("core.team", "t:a", null);

        assertThat(created).hasSize(1);
        assertThat(created.getFirst().history()).extracting(ProducerRecord::topic, ProducerRecord::key,
                ProducerRecord::value).containsExactly(org.assertj.core.groups.Tuple.tuple("core.team", "t:a", "{}"),
                org.assertj.core.groups.Tuple.tuple("core.team", "t:a", null));
    }

    @Test
    void aFailedSendIsReportedAsUnavailable() {
        KafkaEventBroker broker = broker(3);

        assertThatThrownBy(() -> broker.send("core.team", "t:a", "{}"))
                .isInstanceOf(EventBroker.UnavailableException.class).hasMessageContaining("core.team")
                .hasCauseInstanceOf(SaslAuthenticationException.class);
    }

    @Test
    void anUnansweredSendTimesOut() {
        KafkaEventBroker broker = new KafkaEventBroker(
                () -> new MockProducer<>(false, null, new StringSerializer(), new StringSerializer()), TIMEOUT, 3,
                registry);

        assertThatThrownBy(() -> broker.send("core.team", "t:a", "{}"))
                .isInstanceOf(EventBroker.UnavailableException.class)
                .hasCauseInstanceOf(java.util.concurrent.TimeoutException.class);
    }

    @Test
    void replacesTheProducerAfterTheConfiguredNumberOfConsecutiveFailuresAndClosesTheOldOne() {
        KafkaEventBroker broker = broker(3);

        failTimes(broker, 2);
        assertThat(created).as("two failures: the same producer").hasSize(1);
        failTimes(broker, 1);
        assertThat(created.getFirst().closed()).as("the third failure closes it").isTrue();
        assertThat(resets()).isEqualTo(1);

        brokerAnswers.set(true);
        broker.send("core.team", "t:a", "{}");

        assertThat(created).as("the next send creates a new one").hasSize(2);
        assertThat(created.get(1).history()).hasSize(1);
    }

    @Test
    void aSuccessfulSendStartsTheCountAgain() {
        KafkaEventBroker broker = broker(3);

        failTimes(broker, 2);
        brokerAnswers.set(true);
        broker.send("core.team", "t:a", "{}");
        brokerAnswers.set(false);
        failTimes(broker, 2);

        assertThat(created.getFirst().closed()).as("never three failures in a row").isFalse();
        assertThat(resets()).isZero();
        failTimes(broker, 1);
        assertThat(created.getFirst().closed()).isTrue();
    }

    @Test
    void theProducerIsCreatedAtTheFirstSendAndClosedWithTheBroker() {
        brokerAnswers.set(true);
        KafkaEventBroker broker = broker(3);
        assertThat(created).as("no producer (and no connection) while nothing is sent").isEmpty();

        broker.send("core.team", "t:a", "{}");
        broker.close();

        assertThat(created).hasSize(1);
        assertThat(created.getFirst().closed()).isTrue();
    }

    @Test
    void theResetCounterIsRegisteredBeforeAnyReset() {
        broker(3);

        assertThat(resets()).isZero();
    }

    @Test
    void theProducerTakesTheKafkaSettingsButAcksIdempotenceAndSerializersAreFixed() {
        Map<String, Object> config = KafkaEventBroker.producerConfig(Map.of("bootstrap.servers", "broker:9092",
                "security.protocol", "SASL_PLAINTEXT", "acks", "1", "enable.idempotence", "false", "group.id", "core",
                "delivery.timeout.ms", "8000"));

        assertThat(config).containsEntry("bootstrap.servers", "broker:9092")
                .containsEntry("security.protocol", "SASL_PLAINTEXT").containsEntry("delivery.timeout.ms", "8000")
                .containsEntry("acks", "all").containsEntry("enable.idempotence", true)
                .containsEntry("key.serializer", StringSerializer.class.getName())
                .containsEntry("value.serializer", StringSerializer.class.getName())
                .containsEntry("client.id", "core-events")
                .doesNotContainKey("group.id");
    }

    @Test
    void atLeastOneFailureBeforeAReset() {
        assertThatThrownBy(() -> broker(0)).isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("producer-reset-after");
        broker(1);
    }

    @Test
    void theInjectedBrokerCreatesARealKafkaProducerFromTheSettings() {
        KafkaEventBroker broker = new KafkaEventBroker(Map.of("bootstrap.servers", "localhost:1", "max.block.ms", "100"),
                registry, TIMEOUT, 3, true);
        try {
            assertThatThrownBy(() -> broker.send("core.team", "t:a", "{}"))
                    .isInstanceOf(EventBroker.UnavailableException.class)
                    .as("no broker answers: the Kafka client's own timeout, not a failure to create it")
                    .hasCauseInstanceOf(org.apache.kafka.common.errors.TimeoutException.class);
        } finally {
            broker.close();
        }
    }

    @Test
    void withEventsOffNoProducerIsEverCreatedAndASendFailsWithoutCountingAsABrokerFailure() {
        KafkaEventBroker broker = new KafkaEventBroker(this::producer, TIMEOUT, 1, registry, false);

        for (int i = 0; i < 3; i++) {
            assertThatThrownBy(() -> broker.send("core.team", "t:a", "{}"))
                    .isInstanceOf(EventBroker.UnavailableException.class)
                    .hasMessageContaining("hoops.outbox.enabled=false").hasNoCause();
        }

        assertThat(created).as("no producer, so no connection attempt and no Kafka WARN line").isEmpty();
        assertThat(resets()).as("an intended stop is not a failing producer").isZero();
    }

    @Test
    void theInjectedBrokerWithEventsOffNeverBuildsAKafkaProducer() {
        KafkaEventBroker broker = new KafkaEventBroker(Map.of("bootstrap.servers", "localhost:1", "max.block.ms", "100"),
                registry, TIMEOUT, 3, false);

        assertThatThrownBy(() -> broker.send("core.team", "t:a", "{}"))
                .isInstanceOf(EventBroker.UnavailableException.class).hasNoCause();
        assertThat(registry.find("kafka.producer.record.send.total").meter()).as("no producer metrics bound")
                .isNull();
        broker.close();
    }

    @Test
    void closingABrokerThatNeverSentIsANoOp() {
        KafkaEventBroker broker = broker(3);

        broker.close();

        assertThat(created).isEmpty();
    }

    @Test
    void theProducersClientMetricsArePublishedWhileItLives() {
        brokerAnswers.set(true);
        KafkaEventBroker broker = broker(3);

        broker.send("core.team", "t:a", "{}");
        assertThat(registry.find("kafka.producer.record.send.total").meter())
                .as("bound at creation").isNotNull();

        broker.close();
        assertThat(registry.find("kafka.producer.record.send.total").meter())
                .as("removed with the producer").isNull();
    }

    @Test
    void anInterruptedSendKeepsTheThreadInterrupted() {
        KafkaEventBroker broker = new KafkaEventBroker(
                () -> new MockProducer<>(false, null, new StringSerializer(), new StringSerializer()), TIMEOUT, 3,
                registry);
        Thread.currentThread().interrupt();
        try {
            assertThatThrownBy(() -> broker.send("core.team", "t:a", "{}"))
                    .isInstanceOf(EventBroker.UnavailableException.class)
                    .hasCauseInstanceOf(InterruptedException.class);
            assertThat(Thread.currentThread().isInterrupted()).isTrue();
        } finally {
            Thread.interrupted();
        }
    }

    @Test
    void aBatchIsSentWholeBeforeItsAcknowledgementsAreAwaited() {
        // CORE-04: the broker answers only once the whole batch is in flight; a send that waited for each record's
        // acknowledgement before the next would time out on the first one
        KafkaEventBroker broker = new KafkaEventBroker(() -> acknowledgingFrom(3), TIMEOUT, 3, registry);

        broker.sendAll(List.of(new EventBroker.Message("core.team", "t:a", "{\"n\":1}"),
                new EventBroker.Message("core.team", "t:a", null),
                new EventBroker.Message("core.player", "p:b", "{\"n\":2}")));

        assertThat(created.getFirst().history())
                .extracting(ProducerRecord::topic, ProducerRecord::key, ProducerRecord::value)
                .containsExactly(org.assertj.core.groups.Tuple.tuple("core.team", "t:a", "{\"n\":1}"),
                        org.assertj.core.groups.Tuple.tuple("core.team", "t:a", null),
                        org.assertj.core.groups.Tuple.tuple("core.player", "p:b", "{\"n\":2}"));
    }

    @Test
    void aBatchWithAnUnacknowledgedRecordFailsAsOneFailure() {
        KafkaEventBroker broker = broker(2);
        List<EventBroker.Message> batch = List.of(new EventBroker.Message("core.team", "t:a", "{}"),
                new EventBroker.Message("core.player", "p:b", "{}"), new EventBroker.Message("core.person", "x", "{}"));

        assertThatThrownBy(() -> broker.sendAll(batch)).isInstanceOf(EventBroker.UnavailableException.class)
                .hasMessageContaining("core.team").hasCauseInstanceOf(SaslAuthenticationException.class);
        assertThat(created.getFirst().closed()).as("three failed records are one failed batch").isFalse();

        assertThatThrownBy(() -> broker.sendAll(batch)).isInstanceOf(EventBroker.UnavailableException.class);
        assertThat(created.getFirst().closed()).as("the second failed batch in a row").isTrue();
        assertThat(resets()).isEqualTo(1);
    }

    @Test
    void aBatchWaitsAtMostTheSendTimeoutAltogether() {
        KafkaEventBroker broker = new KafkaEventBroker(
                () -> new MockProducer<>(false, null, new StringSerializer(), new StringSerializer()), TIMEOUT, 3,
                registry);
        List<EventBroker.Message> batch = java.util.stream.IntStream.range(0, 10)
                .mapToObj(i -> new EventBroker.Message("core.team", "t:" + i, "{}")).toList();
        long started = System.nanoTime();

        assertThatThrownBy(() -> broker.sendAll(batch)).isInstanceOf(EventBroker.UnavailableException.class)
                .hasCauseInstanceOf(java.util.concurrent.TimeoutException.class);

        assertThat(Duration.ofNanos(System.nanoTime() - started)).as("one timeout, not one per record")
                .isLessThan(TIMEOUT.multipliedBy(5));
    }

    @Test
    void anEmptyBatchSendsNothingAndCreatesNoProducer() {
        KafkaEventBroker broker = broker(3);

        broker.sendAll(List.of());

        assertThat(created).isEmpty();
    }

    /** A producer that answers nothing until {@code batch} records are in flight, then acknowledges all of them. */
    private MockProducer<String, String> acknowledgingFrom(int batch) {
        MockProducer<String, String> producer = new MockProducer<>(false, null, new StringSerializer(),
                new StringSerializer()) {
            @Override
            public synchronized java.util.concurrent.Future<org.apache.kafka.clients.producer.RecordMetadata> send(
                    ProducerRecord<String, String> record, org.apache.kafka.clients.producer.Callback callback) {
                var future = super.send(record, callback);
                if (history().size() == batch) {
                    while (completeNext()) {
                        // acknowledge every record in flight
                    }
                }
                return future;
            }
        };
        created.add(producer);
        return producer;
    }

    private void failTimes(KafkaEventBroker broker, int times) {
        for (int i = 0; i < times; i++) {
            assertThatThrownBy(() -> broker.send("core.team", "t:a", "{}"))
                    .isInstanceOf(EventBroker.UnavailableException.class);
        }
    }

    private double resets() {
        return registry.get("hoops.outbox.producer.resets").counter().count();
    }
}
