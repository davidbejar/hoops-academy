package com.hoopsacademy.core.adapters.out.platform;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.OutboxBacklog;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.application.port.PlatformOutboxWriter;
import io.quarkus.hibernate.orm.PersistenceUnit;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Lifecycle events appended by core_platform (insert grant and policy on core.outbox), and the publisher's backlog
 * per tenant (V14: the queue columns of every tenant, never a payload).
 */
@ApplicationScoped
class PlatformOutboxRepository implements PlatformOutboxWriter, OutboxBacklog {

    private final EntityManager em;
    private final ObjectMapper json;

    PlatformOutboxRepository(@PersistenceUnit("platform") EntityManager em, ObjectMapper json) {
        this.em = em;
        // event payloads spell an absent value as an explicit null (the application mapper omits nulls)
        this.json = json.copy().setDefaultPropertyInclusion(
                JsonInclude.Value.construct(JsonInclude.Include.ALWAYS, JsonInclude.Include.ALWAYS));
    }

    @Override
    public void write(OutboxEvent event) {
        em.createNativeQuery("""
                insert into core.outbox (id, tenant_id, event_type, aggregate_type, aggregate_id, payload, topic)
                values (:id, :tenant, :type, :aggregateType, :aggregateId, cast(:payload as jsonb), :topic)""")
                .setParameter("id", UUID.randomUUID())
                .setParameter("tenant", event.tenant().value())
                .setParameter("type", event.type())
                .setParameter("aggregateType", event.aggregateType())
                .setParameter("aggregateId", event.aggregateId())
                .setParameter("payload", toJson(event.payload()))
                .setParameter("topic", event.topic())
                .executeUpdate();
    }

    @Override
    @SuppressWarnings("unchecked")
    public List<TenantBacklog> pendingByTenant() {
        List<Object[]> rows = em.createNativeQuery("""
                select tenant_id, count(*), min(occurred_at) from core.outbox
                 where published_at is null and topic is not null
                 group by tenant_id
                 order by min(occurred_at)""", Object[].class).getResultList();
        return rows.stream().map(row -> new TenantBacklog(new TenantId((UUID) row[0]), ((Number) row[1]).longValue(),
                instant(row[2]))).toList();
    }

    private static Instant instant(Object value) {
        return switch (value) {
            case Instant instant -> instant;
            case OffsetDateTime offset -> offset.toInstant();
            case java.sql.Timestamp timestamp -> timestamp.toInstant();
            default -> throw new IllegalStateException("Not a timestamp: " + value.getClass());
        };
    }

    private String toJson(Object payload) {
        try {
            return json.writeValueAsString(payload);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Outbox payload is not serializable", e);
        }
    }
}
