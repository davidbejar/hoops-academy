package com.hoopsacademy.core.application.events;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hoopsacademy.core.application.port.OutboxQueue.PendingEvent;
import jakarta.enterprise.context.ApplicationScoped;

/**
 * The record of an outbox row on its topic (libs/contracts/events, README "Events"): key
 * {@code <tenantId>:<aggregateId>}, value the envelope {@code eventId, type, version, tenantId, aggregateId, occurredAt,
 * payload} with the stored payload verbatim.
 */
@ApplicationScoped
public class EventEnvelopes {

    private final ObjectMapper json;

    public EventEnvelopes(ObjectMapper json) {
        this.json = json;
    }

    public static String key(PendingEvent event) {
        return event.tenant() + ":" + event.aggregateId();
    }

    public String value(PendingEvent event) {
        ObjectNode envelope = json.createObjectNode();
        envelope.put("eventId", event.eventId().toString());
        envelope.put("type", event.type());
        envelope.put("version", EventTopic.VERSION);
        envelope.put("tenantId", event.tenant().toString());
        envelope.put("aggregateId", event.aggregateId());
        envelope.put("occurredAt", event.occurredAt().toString());
        try {
            envelope.set("payload", json.readTree(event.payloadJson()));
            return json.writeValueAsString(envelope);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Outbox row " + event.eventId() + " has no JSON payload", e);
        }
    }
}
