package com.hoopsacademy.core.application.events;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.core.application.port.PlatformAuditLog;
import com.hoopsacademy.core.application.port.RosterInventory;
import com.hoopsacademy.core.application.port.TenantRepository;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.quarkus.narayana.jta.QuarkusTransaction;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.TreeMap;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

/**
 * The events backfill (WP81, decision 59): roster data written before the outbox publisher (WP67) has no event, so a
 * replica built from the topics would not know it. For each academy (or one), in that academy's transactions as
 * core_app, every live aggregate without a roster event (every live aggregate with {@code force}: a new snapshot) is
 * reported to {@link RosterChanges}, which appends its {@code .changed} from the current state under the writers' locks,
 * like any change: the outbox keeps the order per aggregate and the publisher sends it. A person's player follows its
 * person (the appender's rule), so the player is not reported a second time: before each topic the candidates are read
 * again. Idempotent: without {@code force} a second run appends nothing. Each academy that got events gets an audit row;
 * an academy that fails is logged and counted, the others go on.
 */
@ApplicationScoped
public class BackfillRosterEvents {

    private static final Logger LOG = Logger.getLogger(BackfillRosterEvents.class);

    /** What a run appended: per topic, the aggregates that got an event (topics without any are left out). */
    public record Result(boolean force, int tenants, int failed, Map<String, Integer> appendedByTopic) {

        public int appended() {
            return appendedByTopic.values().stream().mapToInt(Integer::intValue).sum();
        }
    }

    private final TenantRepository registry;
    private final RosterInventory inventory;
    private final RosterChanges changes;
    private final TenantScope tenantScope;
    private final PlatformAuditLog audit;
    private final MeterRegistry metrics;
    private final int chunkSize;

    public BackfillRosterEvents(TenantRepository registry, RosterInventory inventory, RosterChanges changes,
            TenantScope tenantScope, PlatformAuditLog audit, MeterRegistry metrics,
            @ConfigProperty(name = "hoops.outbox.backfill.chunk-size", defaultValue = "200") int chunkSize) {
        this.registry = registry;
        this.inventory = inventory;
        this.changes = changes;
        this.tenantScope = tenantScope;
        this.audit = audit;
        this.metrics = metrics;
        this.chunkSize = chunkSize;
    }

    /** @throws NotFoundException when {@code only} names no registered academy */
    public Result run(Optional<TenantId> only, boolean force) {
        List<TenantId> tenants = QuarkusTransaction.requiringNew().call(() -> only
                .map(id -> registry.find(id).map(found -> List.of(id))
                        .orElseThrow(() -> new NotFoundException("Tenant not found")))
                .orElseGet(registry::ids));
        LOG.infof("Events backfill started: %d academies, force %s", tenants.size(), force);
        Map<String, Integer> total = new TreeMap<>();
        int failed = 0;
        for (TenantId tenant : tenants) {
            try {
                Map<String, Integer> appended = backfill(tenant, force);
                appended.forEach((topic, count) -> total.merge(topic, count, Integer::sum));
            } catch (RuntimeException e) {
                failed++;
                LOG.errorf(e, "Events backfill of tenant %s failed; run the backfill again to retry it", tenant);
            }
        }
        Result result = new Result(force, tenants.size(), failed, Map.copyOf(total));
        LOG.infof("Events backfill done: %d academies (%d failed), %d events %s", result.tenants(), failed,
                result.appended(), total);
        return result;
    }

    /**
     * The candidates of every topic are counted first: a player that gets its event with its person is still one of the
     * players this run published. Each topic's candidates are read again just before it is appended, so that player is
     * not reported a second time.
     */
    private Map<String, Integer> backfill(TenantId tenant, boolean force) {
        long after = force ? tenantScope.runAs(tenant, inventory::lastSeq) : 0;
        Map<String, Integer> appended = new TreeMap<>();
        tenantScope.runAs(tenant, () -> BackfillPlan.ORDER.forEach(topic -> {
            int count = candidates(tenant, topic, after).size();
            if (count > 0) {
                appended.put(topic.topic(), count);
            }
        }));
        for (EventTopic topic : BackfillPlan.ORDER) {
            if (!appended.containsKey(topic.topic())) {
                continue;
            }
            List<RosterChange> candidates = tenantScope.runAs(tenant, () -> candidates(tenant, topic, after));
            for (List<RosterChange> chunk : BackfillPlan.chunks(candidates, chunkSize)) {
                tenantScope.runAs(tenant, () -> chunk.forEach(changes::report));
            }
            counter(topic).increment(appended.get(topic.topic()));
        }
        if (!appended.isEmpty()) {
            int events = appended.values().stream().mapToInt(Integer::intValue).sum();
            QuarkusTransaction.requiringNew().run(() -> audit.record(tenant, AuditEvent.of(
                    AuditAction.TENANT_EVENTS_BACKFILLED, tenant,
                    Map.of("force", force, "events", events, "topics", List.copyOf(appended.keySet())))));
            LOG.infof("Events backfill of tenant %s: %d events %s", tenant, events, appended);
        }
        return appended;
    }

    /** The live aggregates of {@code topic} without an event after {@code afterSeq} (0: without any event). */
    private List<RosterChange> candidates(TenantId tenant, EventTopic topic, long afterSeq) {
        return BackfillPlan.missing(tenant, inventory.live(topic), inventory.withEvents(topic, afterSeq));
    }

    private Counter counter(EventTopic topic) {
        return Counter.builder("hoops.outbox.backfill.appended")
                .description("Roster events the events backfill appended to the outbox")
                .tag("topic", topic.topic()).register(metrics);
    }
}
