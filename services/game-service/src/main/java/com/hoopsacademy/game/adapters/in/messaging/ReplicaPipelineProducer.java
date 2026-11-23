package com.hoopsacademy.game.adapters.in.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.replica.CoreEventDecoder;
import com.hoopsacademy.common.replica.ParkedEvents;
import com.hoopsacademy.common.replica.ReplicaConsumer;
import com.hoopsacademy.common.replica.ReplicaMetrics;
import com.hoopsacademy.common.replica.RetryPolicy;
import com.hoopsacademy.game.application.replica.ReplicateRoster;
import com.hoopsacademy.game.application.replica.RosterEvent;
import io.micrometer.core.instrument.MeterRegistry;
import io.quarkus.runtime.Startup;
import jakarta.enterprise.context.Dependent;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Singleton;
import java.time.Clock;
import java.time.Duration;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Wires common's replica pipeline (WP130, ADR-0062) to game: the envelope decoder with game's {@link RosterEventMapper}
 * (the schemas are read once, at creation) and the consumer loop that applies through {@link ReplicateRoster}, parks in
 * {@code game.parked_event} and retries per {@code hoops.roster.replica.max-attempts} / {@code first-backoff}.
 */
@Dependent
class ReplicaPipelineProducer {

    @Produces
    @Singleton
    CoreEventDecoder<RosterEvent> rosterEventDecoder(ObjectMapper json) {
        return new CoreEventDecoder<>(json, new RosterEventMapper());
    }

    /** Created at startup, so the meters of every topic exist before the first record (ADR-0062). */
    @Produces
    @Singleton
    @Startup
    ReplicaConsumer<RosterEvent> replicaConsumer(CoreEventDecoder<RosterEvent> decoder, ReplicateRoster replicate,
            ParkedEvents parked, MeterRegistry metrics, Clock clock,
            @ConfigProperty(name = "hoops.roster.replica.max-attempts", defaultValue = "5") int maxAttempts,
            @ConfigProperty(name = "hoops.roster.replica.first-backoff", defaultValue = "PT0.5S") Duration firstBackoff) {
        return new ReplicaConsumer<>(decoder, replicate::apply, parked, new ReplicaMetrics(metrics), clock,
                new RetryPolicy(maxAttempts, firstBackoff));
    }
}
