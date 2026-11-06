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
