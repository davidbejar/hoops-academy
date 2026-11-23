package com.hoopsacademy.athlete.adapters.in.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent;
import com.hoopsacademy.athlete.application.replica.RosterEvent;
import com.hoopsacademy.common.replica.CoreEventDecoder;
import com.hoopsacademy.common.replica.ParkedEvents;
import com.hoopsacademy.common.replica.ReplicaConsumer;
import com.hoopsacademy.common.replica.ReplicaMetrics;
import com.hoopsacademy.common.replica.RetryPolicy;
import io.micrometer.core.instrument.MeterRegistry;
import io.quarkus.runtime.StartupEvent;
import jakarta.enterprise.context.Dependent;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.inject.Instance;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Singleton;
import java.time.Clock;
import java.time.Duration;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Wires common's replica pipeline (WP130, ADR-0062) to athlete: the envelope decoder with athlete's
 * {@link CoreEventMapper} (the schemas are read once, at creation) and the consumer loop that applies through
 * {@link ApplyRosterEvent}, parks in {@code athlete.parked_event} and retries per
 * {@code hoops.roster.replica.max-attempts} / {@code first-backoff}.
 */
@Dependent
class ReplicaPipelineProducer {

    @Produces
    @Singleton
    CoreEventDecoder<RosterEvent> coreEventDecoder(ObjectMapper json) {
        return new CoreEventDecoder<>(json, new CoreEventMapper());
    }

    @Produces
    @Singleton
    ReplicaConsumer<RosterEvent> replicaConsumer(CoreEventDecoder<RosterEvent> decoder, ApplyRosterEvent apply,
            ParkedEvents parked, MeterRegistry metrics, Clock clock,
            @ConfigProperty(name = "hoops.roster.replica.max-attempts", defaultValue = "5") int maxAttempts,
            @ConfigProperty(name = "hoops.roster.replica.first-backoff", defaultValue = "PT0.5S") Duration firstBackoff) {
        return new ReplicaConsumer<>(decoder, apply::apply, parked, new ReplicaMetrics(metrics), clock,
                new RetryPolicy(maxAttempts, firstBackoff));
    }

    /**
     * With the consumer on, the pipeline is created at startup rather than on the first record, so the parked counter
     * and lag gauge of every topic exist from the start (ADR-0062). With it off nothing registers them: a service that
     * does not consume shows no replica meters.
     */
    void createAtStartup(@Observes StartupEvent event,
            @ConfigProperty(name = "hoops.roster.consumer.enabled", defaultValue = "true") boolean consumerEnabled,
            Instance<ReplicaConsumer<RosterEvent>> consumer) {
        if (consumerEnabled) {
            consumer.get();
        }
    }
}
