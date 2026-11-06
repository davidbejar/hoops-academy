package com.hoopsacademy.core.application.events;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.port.EventBroker;
import com.hoopsacademy.core.application.port.OutboxBacklog;
import com.hoopsacademy.core.application.port.OutboxBacklog.TenantBacklog;
import com.hoopsacademy.core.application.port.OutboxQueue;
import com.hoopsacademy.core.application.port.OutboxQueue.PendingEvent;
import io.quarkus.narayana.jta.QuarkusTransaction;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * One run of the outbox publisher (WP67): for each tenant with a backlog (oldest first), in that tenant's own
 * transaction as core_app, it locks the next batch, sends each event to its topic (a removal is followed by a
 * tombstone for the same key), waits for every acknowledgement and only then marks the batch published. At least
 * once: a crash or a broker failure after a send and before the commit leaves the rows unpublished, and the next run
 * sends them again with the same {@code eventId}. Several replicas can run it at the same time without a cluster lock:
 * the row locks ({@code FOR UPDATE SKIP LOCKED}) give each row to one publisher, and a publisher never sends an
 * aggregate's event while an earlier one of the same aggregate is locked by another, so the order per key holds.
 * A broker failure stops the run (the other tenants wait for the next one) and the status reports it.
 */
@ApplicationScoped
public class PublishOutbox {

    private static final Logger LOG = Logger.getLogger(PublishOutbox.class);

    /** What one run sent, per topic, and the backlog left after it. */
    public record Result(Map<String, Integer> publishedByTopic, boolean brokerAvailable, long pending, Duration lag) {

        public int published() {
            return publishedByTopic.values().stream().mapToInt(Integer::intValue).sum();
        }
    }

    private final OutboxBacklog backlog;
    private final OutboxQueue queue;
    private final EventBroker broker;
    private final EventEnvelopes envelopes;
    private final TenantScope tenantScope;
    private final OutboxPublisherStatus status;
    private final Clock clock;
    private final int batchSize;

    public PublishOutbox(OutboxBacklog backlog, OutboxQueue queue, EventBroker broker, EventEnvelopes envelopes,
            TenantScope tenantScope, OutboxPublisherStatus status, Clock clock,
            @ConfigProperty(name = "hoops.outbox.batch-size", defaultValue = "100") int batchSize) {
        this.backlog = backlog;
        this.queue = queue;
        this.broker = broker;
        this.envelopes = envelopes;
        this.tenantScope = tenantScope;
        this.status = status;
        this.clock = clock;
        this.batchSize = batchSize;
    }

    public Result run() {
        Map<String, Integer> published = new HashMap<>();
        Optional<String> brokerError = Optional.empty();
        for (TenantBacklog tenant : pendingByTenant()) {
            try {
                publishTenant(tenant.tenant(), published);
            } catch (EventBroker.UnavailableException e) {
                LOG.warnf("Event broker unavailable, the backlog waits for the next run: %s", e.getMessage());
                brokerError = Optional.of(e.getCause() == null ? e.getClass().getSimpleName()
                        : e.getCause().getClass().getSimpleName());
                break;
            } catch (RuntimeException e) {
                LOG.errorf(e, "Publishing the outbox of tenant %s failed; its events are sent again next run",
                        tenant.tenant());
            }
        }
        List<TenantBacklog> left = pendingByTenant();
        long pending = left.stream().mapToLong(TenantBacklog::pending).sum();
        Instant now = clock.instant();
        Duration lag = left.stream().map(TenantBacklog::oldest).min(Instant::compareTo)
                .map(oldest -> Duration.between(oldest, now)).filter(age -> !age.isNegative()).orElse(Duration.ZERO);
        status.record(now, brokerError.isEmpty(), pending, lag, brokerError);
        return new Result(Map.copyOf(published), brokerError.isEmpty(), pending, lag);
    }

    private List<TenantBacklog> pendingByTenant() {
        return QuarkusTransaction.requiringNew().call(backlog::pendingByTenant);
    }

    /** Batch after batch until a short one (the rest, if any, is locked elsewhere or arrives for the next run). */
    private void publishTenant(TenantId tenant, Map<String, Integer> published) {
        int sent;
        do {
            Map<String, Integer> committed = tenantScope.runAs(tenant, this::publishBatch);
            committed.forEach((topic, count) -> published.merge(topic, count, Integer::sum));
            sent = committed.values().stream().mapToInt(Integer::intValue).sum();
        } while (sent == batchSize);
    }

    /** Runs in the tenant's transaction: the batch is marked published only after every send was acknowledged. */
    private Map<String, Integer> publishBatch() {
        List<PendingEvent> batch = queue.lockNext(batchSize);
        Map<String, Integer> sent = new HashMap<>();
        for (PendingEvent event : batch) {
            String key = EventEnvelopes.key(event);
            broker.send(event.topic(), key, envelopes.value(event));
            if (EventTopic.ofTopic(event.topic()).isRemovedType(event.type())) {
                broker.send(event.topic(), key, null);
            }
            sent.merge(event.topic(), 1, Integer::sum);
        }
        if (!batch.isEmpty()) {
            queue.markPublished(batch.stream().map(PendingEvent::eventId).toList());
        }
        return sent;
    }
}
