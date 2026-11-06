package com.hoopsacademy.core.testsupport;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.networknt.schema.Error;
import com.networknt.schema.Schema;
import com.networknt.schema.SchemaRegistry;
import com.networknt.schema.SpecificationVersion;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * The roster events core appended to {@code core.outbox} (WP67), read as the schema owner in the tenant and turned into
 * the envelope the publisher sends. Every envelope is validated against its topic's schema in libs/contracts/events, so
 * an assertion on an event is also a contract check.
 */
public final class RosterEvents {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final SchemaRegistry REGISTRY = SchemaRegistry.withDefaultDialect(SpecificationVersion.DRAFT_2020_12);
    private static final Map<String, Schema> SCHEMAS = new ConcurrentHashMap<>();

    private RosterEvents() {}

    /** The tenant's events on {@code topic}, in outbox order. */
    public static List<JsonNode> of(String tenant, String topic) {
        return read(tenant, "topic = ?", topic);
    }

    /** The events of one aggregate on {@code topic}, in outbox order. */
    public static List<JsonNode> of(String tenant, String topic, UUID aggregate) {
        return read(tenant, "topic = ? and aggregate_id = ?", topic, aggregate.toString());
    }

    /** The latest event of one aggregate (fails when there is none). */
    public static JsonNode last(String tenant, String topic, UUID aggregate) {
        List<JsonNode> events = of(tenant, topic, aggregate);
        assertThat(events).as("events of %s on %s", aggregate, topic).isNotEmpty();
        return events.getLast();
    }

    /** The payload of the latest event of one aggregate. */
    public static JsonNode state(String tenant, String topic, UUID aggregate) {
        return last(tenant, topic, aggregate).get("payload");
    }

    /** Every roster event of the tenant (all topics). */
    public static long count(String tenant) {
        return CoreDb.count(tenant, "select count(*) from core.outbox where topic is not null");
    }

    /** The derived aggregate id of a team staff entry (the contract's rule). */
    public static UUID teamStaffId(UUID team, UUID person) {
        return UUID.nameUUIDFromBytes(("team-staff:" + team + ":" + person).getBytes(java.nio.charset.StandardCharsets.UTF_8));
    }

    /** Validates one envelope against its topic's schema. */
    public static void assertValid(String topic, JsonNode envelope) {
        List<Error> errors = SCHEMAS.computeIfAbsent(topic, RosterEvents::load).validate(envelope);
        assertThat(errors).as("%s event %s", topic, envelope).isEmpty();
    }

    private static List<JsonNode> read(String tenant, String where, Object... params) {
        List<JsonNode> events = CoreDb.inTenant(tenant, c -> {
            List<JsonNode> rows = new ArrayList<>();
            try (PreparedStatement statement = c.prepareStatement("""
                    select id, event_type, tenant_id, aggregate_id, occurred_at, payload::text, topic
                      from core.outbox where %s order by seq""".formatted(where))) {
                CoreDb.bind(statement, params);
                try (ResultSet rs = statement.executeQuery()) {
                    while (rs.next()) {
                        rows.add(envelope(rs));
                    }
                }
            }
            return rows;
        });
        events.forEach(event -> assertValid(event.get("topic").asText(), strip(event)));
        return events.stream().map(RosterEvents::strip).toList();
    }

    private static ObjectNode envelope(ResultSet rs) throws java.sql.SQLException {
        ObjectNode event = JSON.createObjectNode();
        event.put("eventId", rs.getString(1));
        event.put("type", rs.getString(2));
        event.put("version", 1);
        event.put("tenantId", rs.getString(3));
        event.put("aggregateId", rs.getString(4));
        event.put("occurredAt", rs.getTimestamp(5).toInstant().toString());
        try {
            event.set("payload", JSON.readTree(rs.getString(6)));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        event.put("topic", rs.getString(7));
        return event;
    }

    private static JsonNode strip(JsonNode event) {
        ObjectNode copy = event.deepCopy();
        copy.remove("topic");
        return copy;
    }

    private static Schema load(String topic) {
        try (InputStream in = RosterEvents.class.getResourceAsStream("/events/" + topic + ".schema.json")) {
            assertThat(in).as("schema of %s on the test classpath (libs/contracts)", topic).isNotNull();
            return REGISTRY.getSchema(JSON.readTree(in));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
