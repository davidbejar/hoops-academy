package com.hoopsacademy.core.adapters.out.persistence;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.application.port.OutboxWriter;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.util.UUID;

/** Appends to {@code core.outbox} in the caller's tenant-bound transaction. */
@ApplicationScoped
class JpaOutboxRepository implements OutboxWriter {

    private final EntityManager em;
    private final ObjectMapper json;

    JpaOutboxRepository(EntityManager em, ObjectMapper json) {
        this.em = em;
        this.json = payloadMapper(json);
    }

    /** The application mapper omits nulls (REST); an event payload spells an absent value as an explicit null. */
    static ObjectMapper payloadMapper(ObjectMapper json) {
        return json.copy().setDefaultPropertyInclusion(
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
                .setParameter("payload", serialize(event))
                .setParameter("topic", event.topic())
                .executeUpdate();
    }

    private String serialize(OutboxEvent event) {
        try {
            return json.writeValueAsString(event.payload());
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Outbox payload is not serializable: " + event.type(), e);
        }
    }
}
