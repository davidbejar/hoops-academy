package com.hoopsacademy.core.application.events;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.application.port.OutboxQueue.PendingEvent;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class EventEnvelopesTest {

    private static final ObjectMapper JSON = new ObjectMapper();
    private final EventEnvelopes envelopes = new EventEnvelopes(JSON);
    private final TenantId tenant = new TenantId(UUID.randomUUID());
    private final UUID aggregate = UUID.randomUUID();
    private final UUID eventId = UUID.randomUUID();

    @Test
    void theKeyIsTenantColonAggregateAndTheValueTheEnvelopeWithThePayloadVerbatim() throws Exception {
        PendingEvent event = new PendingEvent(eventId, "core.team", "team.changed", tenant, aggregate.toString(),
                Instant.parse("2026-11-06T10:15:30.123456Z"), "{\"name\":\"Lions\",\"alias\":null}");

        JsonNode value = JSON.readTree(envelopes.value(event));

        assertThat(EventEnvelopes.key(event)).isEqualTo(tenant + ":" + aggregate);
        assertThat(iterable(value.fieldNames())).containsExactly("eventId", "type", "version", "tenantId",
                "aggregateId", "occurredAt", "payload");
        assertThat(value.get("eventId").asText()).isEqualTo(eventId.toString());
        assertThat(value.get("type").asText()).isEqualTo("team.changed");
        assertThat(value.get("version").asInt()).isEqualTo(1);
        assertThat(value.get("tenantId").asText()).isEqualTo(tenant.toString());
        assertThat(value.get("aggregateId").asText()).isEqualTo(aggregate.toString());
        assertThat(value.get("occurredAt").asText()).isEqualTo("2026-11-06T10:15:30.123456Z");
        assertThat(value.get("payload").get("name").asText()).isEqualTo("Lions");
        assertThat(value.get("payload").has("alias")).as("an explicit null stays").isTrue();
    }

    @Test
    void aPayloadThatIsNoJsonIsRefused() {
        PendingEvent event = new PendingEvent(eventId, "core.team", "team.changed", tenant, aggregate.toString(),
                Instant.EPOCH, "{not json");

        assertThatThrownBy(() -> envelopes.value(event)).isInstanceOf(IllegalStateException.class)
                .hasMessageContaining(eventId.toString());
    }

    private static List<String> iterable(java.util.Iterator<String> names) {
        List<String> list = new java.util.ArrayList<>();
        names.forEachRemaining(list::add);
        return list;
    }
}
