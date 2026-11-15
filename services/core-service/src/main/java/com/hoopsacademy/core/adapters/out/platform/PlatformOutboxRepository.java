package com.hoopsacademy.core.adapters.out.platform;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.adapters.out.persistence.OutboxRowRepository;
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
        this.json = OutboxRowRepository.payloadMapper(json);
    }

    @Override
    public void write(OutboxEvent event) {
        OutboxRowRepository.insert(em, json, event);
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
}
