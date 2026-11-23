package com.hoopsacademy.common.replica;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.contracts.ContractResources;
import com.hoopsacademy.common.replica.DecodedEvent.Invalid;
import com.hoopsacademy.common.replica.DecodedEvent.Valid;
import com.hoopsacademy.common.tenancy.TenantId;
import com.networknt.schema.Error;
import com.networknt.schema.Schema;
import com.networknt.schema.SchemaRegistry;
import com.networknt.schema.SpecificationVersion;
import java.time.DateTimeException;
import java.time.Instant;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * The envelope half of the roster event decoders of game and athlete (ADR-0037, one copy since WP130, ADR-0062): the
 * value must follow its topic's contract ({@code events/core.<aggregate>.schema.json}, read from the contracts jar at
 * construction), the key must be {@code <tenantId>:<aggregateId>} of the envelope, so a record can never write into a
 * tenant other than the one it names twice, and a tenant event must be about its own tenant. The service's
 * {@link EventMapper} turns the valid payload into its own event. Never throws for bad input: the record becomes
 * {@link Invalid} with a bounded reason that quotes no value of the record, and the consumer parks it.
 *
 * @param <E> the service's own event type
 */
public final class CoreEventDecoder<E> {

    /** Parked reasons are bounded (they are stored and logged). */
    public static final int MAX_REASON_LENGTH = 500;
    /** Schema errors kept in a reason. */
    public static final int MAX_ERRORS = 5;

    private static final String SCHEMA_FOLDER = "/events/";
    private static final Pattern UUID_FORMAT =
            Pattern.compile("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$");

    private final ObjectMapper json;
    private final EventMapper<E> mapper;
    private final Map<RosterTopic, Schema> schemas = new EnumMap<>(RosterTopic.class);

    /**
     * @throws IllegalStateException when a topic's schema is not on the class path (the contracts jar is missing)
     */
    public CoreEventDecoder(ObjectMapper json, EventMapper<E> mapper) {
        this(json, mapper, SCHEMA_FOLDER);
    }

    CoreEventDecoder(ObjectMapper json, EventMapper<E> mapper, String schemaFolder) {
        this.json = json;
        this.mapper = mapper;
        SchemaRegistry registry = SchemaRegistry.withDefaultDialect(SpecificationVersion.DRAFT_2020_12);
        for (RosterTopic topic : RosterTopic.values()) {
            schemas.put(topic, registry.getSchema(ContractResources.json(json, CoreEventDecoder.class,
                    schemaFolder + topic.topicName() + ".schema.json")));
        }
    }

    /** @param value the record's value; null (a tombstone) is invalid here, the consumer skips tombstones first */
    public DecodedEvent<E> decode(String topicName, String key, String value) {
        Optional<RosterTopic> topic = RosterTopic.of(topicName);
        if (topic.isEmpty()) {
            return invalid(Optional.empty(), "not a roster topic");
        }
        if (value == null) {
            return invalid(Optional.empty(), "no value");
        }
        JsonNode event;
        try {
            event = json.readTree(value);
        } catch (JsonProcessingException e) {
            return invalid(Optional.empty(), "value is not JSON");
        }
        return decode(topic.get(), key, event);
    }

    private DecodedEvent<E> decode(RosterTopic topic, String key, JsonNode event) {
        Optional<UUID> eventId = uuid(event.path("eventId"));
        List<Error> errors = schemas.get(topic).validate(event);
        if (!errors.isEmpty()) {
            return invalid(eventId, errors.stream().limit(MAX_ERRORS)
                    .map(error -> error.getInstanceLocation() + ": " + error.getMessage())
                    .collect(Collectors.joining("; ")));
        }
        String tenantId = event.get("tenantId").asText();
        String aggregateId = event.get("aggregateId").asText();
        if (!(tenantId + ":" + aggregateId).equals(key)) {
            return invalid(eventId, "key is not <tenantId>:<aggregateId> of the envelope");
        }
        if (topic == RosterTopic.TENANT && !aggregateId.equals(tenantId)) {
            return invalid(eventId, "a tenant event's aggregateId is not its tenantId");
        }
        try {
            EventEnvelope envelope = new EventEnvelope(eventId.orElseThrow(), TenantId.parse(tenantId),
                    UUID.fromString(aggregateId), Instant.parse(event.get("occurredAt").asText()));
            return new Valid<>(envelope, mapper.map(topic, envelope, event.get("type").asText(), event.get("payload")));
        } catch (DateTimeException | IllegalArgumentException e) {
            return invalid(eventId, "value outside the contract: " + e.getClass().getSimpleName());
        }
    }

    private static Optional<UUID> uuid(JsonNode node) {
        // a number, boolean or structure never matches the format
        return UUID_FORMAT.matcher(node.asText()).matches() ? Optional.of(UUID.fromString(node.asText())) : Optional.empty();
    }

    private static <E> Invalid<E> invalid(Optional<UUID> eventId, String reason) {
        return new Invalid<>(eventId, reason.substring(0, Math.min(reason.length(), MAX_REASON_LENGTH)));
    }
}
