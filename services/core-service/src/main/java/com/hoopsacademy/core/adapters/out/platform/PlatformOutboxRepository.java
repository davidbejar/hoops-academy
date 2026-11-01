package com.hoopsacademy.core.adapters.out.platform;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.application.port.PlatformOutboxWriter;
import io.quarkus.hibernate.orm.PersistenceUnit;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.UUID;

/** Lifecycle events appended by core_platform (insert-only grant and policy on core.outbox). */
@ApplicationScoped
class PlatformOutboxRepository implements PlatformOutboxWriter {

    private final EntityManager em;
    private final ObjectMapper json;

    PlatformOutboxRepository(@PersistenceUnit("platform") EntityManager em, ObjectMapper json) {
        this.em = em;
        this.json = json;
    }

    @Override
    public void write(OutboxEvent event) {
        em.createNativeQuery("""
                insert into core.outbox (id, tenant_id, event_type, aggregate_type, aggregate_id, payload)
                values (:id, :tenant, :type, :aggregateType, :aggregateId, cast(:payload as jsonb))""")
                .setParameter("id", UUID.randomUUID())
                .setParameter("tenant", event.tenant().value())
                .setParameter("type", event.type())
                .setParameter("aggregateType", event.aggregateType())
                .setParameter("aggregateId", event.aggregateId())
                .setParameter("payload", toJson(event.payload()))
                .executeUpdate();
    }

    private String toJson(Object payload) {
        try {
            return json.writeValueAsString(payload);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Outbox payload is not serializable", e);
        }
    }
}
