package com.hoopsacademy.core.adapters.in.scheduler;

import com.hoopsacademy.core.application.events.OutboxPublisherStatus;
import com.hoopsacademy.core.application.events.PublishOutbox;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Runs the outbox publisher every {@code hoops.outbox.poll-interval} (default 1 s; {@code off} disables it) and exposes
 * its metrics on /q/metrics: {@code hoops_outbox_published_total{topic}}, {@code hoops_outbox_pending} (unpublished
 * roster events of every tenant), {@code hoops_outbox_lag_seconds} (age of the oldest one, 0 when none) and
 * {@code hoops_outbox_broker_available} (1/0), as of the last run. Every replica runs it; no cluster lock is needed
 * (see {@link PublishOutbox}). With events off ({@code hoops.outbox.enabled=false}, env {@code CORE_OUTBOX_ENABLED}, WP91)
 * the trigger does nothing: no run, no producer, no broker warnings; the outbox keeps filling until events are on.
 */
@ApplicationScoped
public class OutboxPublisherJob {

    private final PublishOutbox publisher;
    private final MeterRegistry registry;
    private final boolean enabled;

    public OutboxPublisherJob(PublishOutbox publisher, OutboxPublisherStatus status, MeterRegistry registry,
            @ConfigProperty(name = "hoops.outbox.enabled", defaultValue = "true") boolean enabled) {
        this.publisher = publisher;
        this.registry = registry;
        this.enabled = enabled;
        Gauge.builder("hoops.outbox.pending", status, s -> s.snapshot().pending())
                .description("Unpublished roster events in the outbox (all tenants), as of the last publisher run")
                .register(registry);
        Gauge.builder("hoops.outbox.lag", status, s -> s.snapshot().lag().toMillis() / 1000.0).baseUnit("seconds")
                .description("Age of the oldest unpublished roster event, as of the last publisher run")
                .register(registry);
        Gauge.builder("hoops.outbox.broker.available", status, s -> s.snapshot().brokerAvailable() ? 1 : 0)
                .description("1 when the last publisher run reached the event broker, 0 when it did not")
                .register(registry);
    }

    @Scheduled(identity = "outbox-publisher", every = "{hoops.outbox.poll-interval}",
            concurrentExecution = Scheduled.ConcurrentExecution.SKIP)
    void scheduled() {
        if (enabled) {
            run();
        }
    }

    /** One run (the trigger above; tests call it directly). */
    public PublishOutbox.Result run() {
        PublishOutbox.Result result = publisher.run();
        result.publishedByTopic().forEach((topic, count) -> Counter.builder("hoops.outbox.published")
                .description("Roster events the outbox publisher sent and marked published")
                .tag("topic", topic).register(registry).increment(count));
        return result;
    }
}
