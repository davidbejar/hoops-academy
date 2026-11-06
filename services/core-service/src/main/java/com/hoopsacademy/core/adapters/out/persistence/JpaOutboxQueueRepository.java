package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.OutboxQueue;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

/** The bound tenant's unpublished roster events (core_app under the tenant policy). */
@ApplicationScoped
class JpaOutboxQueueRepository implements OutboxQueue {

    /**
     * The batch CTE locks the oldest unpublished rows that no other transaction holds. A row is returned only if no
     * older unpublished row of the same aggregate exists outside the batch, i.e. none is held by another publisher (or
     * cut off by the limit): those rows wait for a later run, behind the earlier one.
     */
    private static final String LOCK_NEXT = """
            with batch as (
              select id from core.outbox
               where published_at is null and topic is not null
               order by seq
               limit :limit
               for update skip locked)
            select o.id, o.topic, o.event_type, o.tenant_id, o.aggregate_id, o.occurred_at, o.payload::text
              from core.outbox o
              join batch b on b.id = o.id
             where not exists (
                     select 1 from core.outbox e
                      where e.published_at is null and e.topic = o.topic and e.aggregate_id = o.aggregate_id
                        and e.seq < o.seq and e.id not in (select id from batch))
             order by o.seq""";

    private final EntityManager em;

    JpaOutboxQueueRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    @SuppressWarnings("unchecked")
    public List<PendingEvent> lockNext(int limit) {
        List<Object[]> rows = em.createNativeQuery(LOCK_NEXT, Object[].class).setParameter("limit", limit)
                .getResultList();
        return rows.stream().map(row -> new PendingEvent((UUID) row[0], (String) row[1], (String) row[2],
                new TenantId((UUID) row[3]), (String) row[4], instant(row[5]), (String) row[6])).toList();
    }

    @Override
    public void markPublished(Collection<UUID> eventIds) {
        if (eventIds.isEmpty()) {
            return;
        }
        em.createNativeQuery("update core.outbox set published_at = clock_timestamp() where id in (:ids)")
                .setParameter("ids", eventIds).executeUpdate();
    }

    static Instant instant(Object value) {
        return switch (value) {
            case Instant instant -> instant;
            case OffsetDateTime offset -> offset.toInstant();
            case java.sql.Timestamp timestamp -> timestamp.toInstant();
            default -> throw new IllegalStateException("Not a timestamp: " + value.getClass());
        };
    }
}
