package com.hoopsacademy.core.adapters.out.persistence;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.core.application.port.OutboxEvent;
import jakarta.persistence.EntityManager;
import java.util.UUID;

/**
 * The one insert into {@code core.outbox}, shared by the tenant-bound writer ({@link JpaOutboxRepository}) and the
 * platform writer of core_platform; each passes its own entity manager, so the row lands in the caller's transaction.
 */
public final class OutboxRowRepository {

    private OutboxRowRepository() {
    }

    /** The application mapper omits nulls (REST); an event payload spells an absent value as an explicit null. */
    public static ObjectMapper payloadMapper(ObjectMapper json) {
        return json.copy().setDefaultPropertyInclusion(
                JsonInclude.Value.construct(JsonInclude.Include.ALWAYS, JsonInclude.Include.ALWAYS));
    }

    /** Appends {@code event}; {@code payloadJson} is a {@link #payloadMapper(ObjectMapper)}. */
    public static void insert(EntityManager em, ObjectMapper payloadJson, OutboxEvent event) {
        em.createNativeQuery("""
                insert into core.outbox (id, tenant_id, event_type, aggregate_type, aggregate_id, payload, topic)
                values (:id, :tenant, :type, :aggregateType, :aggregateId, cast(:payload as jsonb), :topic)""")
                .setParameter("id", UUID.randomUUID())
                .setParameter("tenant", event.tenant().value())
                .setParameter("type", event.type())
                .setParameter("aggregateType", event.aggregateType())
                .setParameter("aggregateId", event.aggregateId())
                .setParameter("payload", serialize(payloadJson, event))
                .setParameter("topic", event.topic())
                .executeUpdate();
    }

    private static String serialize(ObjectMapper payloadJson, OutboxEvent event) {
        try {
            return payloadJson.writeValueAsString(event.payload());
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Outbox payload is not serializable: " + event.type(), e);
        }
    }
}
