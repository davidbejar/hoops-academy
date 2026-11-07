package com.hoopsacademy.athlete.adapters.in.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.athlete.adapters.in.messaging.DecodedEvent.Invalid;
import com.hoopsacademy.athlete.adapters.in.messaging.DecodedEvent.Valid;
import com.hoopsacademy.athlete.application.replica.RosterChange;
import com.hoopsacademy.athlete.application.replica.RosterEvent;
import com.hoopsacademy.athlete.application.replica.RosterTopic;
import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.networknt.schema.Error;
import com.networknt.schema.Schema;
import com.networknt.schema.SchemaRegistry;
import com.networknt.schema.SpecificationVersion;
import jakarta.enterprise.context.ApplicationScoped;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.time.DateTimeException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Turns a record of a roster topic into a {@link RosterEvent}: the value must follow its topic's contract
 * (libs/contracts events/core.&lt;aggregate&gt;.schema.json, read from the contracts jar), and the key must be
 * {@code <tenantId>:<aggregateId>} of the envelope, so a record can never write into a tenant other than the one it
 * names twice. Never throws for bad input: the record becomes {@link Invalid} and is parked by the consumer.
 */
@ApplicationScoped
public class CoreEventDecoder {

    /** Parked reasons are bounded (they are stored and logged). */
    static final int MAX_REASON_LENGTH = 500;
    private static final int MAX_ERRORS = 5;
    private static final Pattern UUID_FORMAT =
            Pattern.compile("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$");

    private final ObjectMapper mapper;
    private final Map<RosterTopic, Schema> schemas = new EnumMap<>(RosterTopic.class);

    public CoreEventDecoder(ObjectMapper mapper) {
        this.mapper = mapper;
        SchemaRegistry registry = SchemaRegistry.withDefaultDialect(SpecificationVersion.DRAFT_2020_12);
        for (RosterTopic topic : RosterTopic.values()) {
            schemas.put(topic, registry.getSchema(read("/events/" + topic.topicName() + ".schema.json")));
        }
    }

    public DecodedEvent decode(String topicName, String key, String value) {
        Optional<RosterTopic> topic = RosterTopic.of(topicName);
        if (topic.isEmpty()) {
            return invalid(Optional.empty(), "not a roster topic");
        }
        if (value == null) {
            return invalid(Optional.empty(), "no value");
        }
        JsonNode json;
        try {
            json = mapper.readTree(value);
        } catch (JsonProcessingException e) {
            return invalid(Optional.empty(), "value is not JSON");
        }
        Optional<UUID> eventId = uuid(json.path("eventId"));
        List<Error> errors = schemas.get(topic.get()).validate(json);
        if (!errors.isEmpty()) {
            return invalid(eventId, errors.stream().limit(MAX_ERRORS)
                    .map(error -> error.getInstanceLocation() + ": " + error.getMessage())
                    .collect(Collectors.joining("; ")));
        }
        String expectedKey = json.get("tenantId").asText() + ":" + json.get("aggregateId").asText();
        if (!expectedKey.equals(key)) {
            return invalid(eventId, "key is not <tenantId>:<aggregateId> of the envelope");
        }
        if (topic.get() == RosterTopic.TENANT && !json.get("aggregateId").equals(json.get("tenantId"))) {
            return invalid(eventId, "a tenant event's aggregateId is not its tenantId");
        }
        try {
            return new Valid(new RosterEvent(eventId.orElseThrow(), TenantId.parse(json.get("tenantId").asText()),
                    UUID.fromString(json.get("aggregateId").asText()), Instant.parse(json.get("occurredAt").asText()),
                    change(topic.get(), json.get("type").asText(), json.get("payload"))));
        } catch (DateTimeException | IllegalArgumentException e) {
            return invalid(eventId, "value outside the contract: " + e.getClass().getSimpleName());
        }
    }

    private static RosterChange change(RosterTopic topic, String type, JsonNode p) {
        return switch (type) {
            case "person.removed", "player.removed", "team.removed", "team-player.removed", "tenant.removed" ->
                    new RosterChange.Removed(topic);
            case "person.changed" -> new RosterChange.PersonChanged(p.get("displayName").asText(), text(p, "subject"),
                    roles(p.get("roles")), p.get("active").asBoolean());
            case "player.changed" -> new RosterChange.PlayerChanged(new PersonId(id(p, "personId")),
                    p.get("displayName").asText(), p.get("status").asText(), text(p, "birthDate").map(LocalDate::parse),
                    text(p, "gender").map(Gender::valueOf));
            case "team.changed" -> new RosterChange.TeamChanged(id(p, "seasonId"),
                    LocalDate.parse(p.get("seasonEndDate").asText()), p.get("name").asText());
            case "team-player.changed" -> new RosterChange.TeamPlayerChanged(new TeamId(id(p, "teamId")),
                    new PlayerId(id(p, "playerId")), text(p, "jerseyNumber"), LocalDate.parse(p.get("joinedOn").asText()),
                    text(p, "leftOn").map(LocalDate::parse), text(p, "invalidReason"));
            case "team-staff.changed" -> new RosterChange.TeamStaffChanged(new TeamId(id(p, "teamId")),
                    new PersonId(id(p, "personId")), p.get("role").asText(), LocalDate.parse(p.get("since").asText()));
            case "team-staff.removed" -> new RosterChange.TeamStaffRemoved(new TeamId(id(p, "teamId")),
                    new PersonId(id(p, "personId")));
            case "guardian-link.changed" -> new RosterChange.GuardianLinkChanged(new PersonId(id(p, "guardianPersonId")),
                    new PlayerId(id(p, "playerId")));
            case "guardian-link.removed" -> new RosterChange.GuardianLinkRemoved(new PersonId(id(p, "guardianPersonId")),
                    new PlayerId(id(p, "playerId")));
            case "tenant.changed" -> new RosterChange.TenantChanged(p.get("status").asText(),
                    ZoneId.of(p.get("timezone").asText()));
            default -> throw new IllegalArgumentException("unknown type");
        };
    }

    private static Set<TenantRole> roles(JsonNode roles) {
        Set<TenantRole> result = EnumSet.noneOf(TenantRole.class);
        roles.forEach(role -> result.add(TenantRole.valueOf(role.asText())));
        return result;
    }

    private static UUID id(JsonNode payload, String field) {
        return UUID.fromString(payload.get(field).asText());
    }

    /** A required-but-nullable field: JSON null is absent. */
    private static Optional<String> text(JsonNode payload, String field) {
        JsonNode node = payload.get(field);
        return node == null || node.isNull() ? Optional.empty() : Optional.of(node.asText());
    }

    private static Optional<UUID> uuid(JsonNode node) {
        return node.isTextual() && UUID_FORMAT.matcher(node.asText()).matches()
                ? Optional.of(UUID.fromString(node.asText()))
                : Optional.empty();
    }

    private static Invalid invalid(Optional<UUID> eventId, String reason) {
        return new Invalid(eventId, reason.length() <= MAX_REASON_LENGTH ? reason : reason.substring(0, MAX_REASON_LENGTH));
    }

    private JsonNode read(String resource) {
        try (InputStream in = CoreEventDecoder.class.getResourceAsStream(resource)) {
            if (in == null) {
                throw new IllegalStateException(resource + " is not on the classpath (contracts jar)");
            }
            return mapper.readTree(in);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
