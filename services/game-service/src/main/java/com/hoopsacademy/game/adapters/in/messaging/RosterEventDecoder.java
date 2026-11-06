package com.hoopsacademy.game.adapters.in.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.application.replica.EventEnvelope;
import com.hoopsacademy.game.application.replica.RosterEvent;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
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
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Turns a record of a {@code core.*} topic into a {@link RosterEvent} when it matches the topic's contract
 * ({@code events/core.<aggregate>.schema.json} from the contracts jar, ADR-0037): the JSON Schema, a key
 * {@code <tenantId>:<aggregateId>}, a tenant event about its own tenant and a known time zone. Anything else is an
 * {@link Decoded.Invalid} with the reason, which the consumer parks.
 */
@ApplicationScoped
public class RosterEventDecoder {

    /** The outcome of decoding one record. */
    public sealed interface Decoded {

        record Valid(RosterEvent event) implements Decoded {}

        /** @param eventId the record's event id when it could be read */
        record Invalid(Optional<UUID> eventId, String reason) implements Decoded {}
    }

    private static final int MAX_REASON_LENGTH = 1000;
    private static final List<String> TOPICS = List.of("core.person", "core.player", "core.team", "core.team-player",
            "core.team-staff", "core.guardian-link", "core.tenant");

    private final ObjectMapper json = new ObjectMapper();
    private final Map<String, Schema> schemas;

    public RosterEventDecoder() {
        SchemaRegistry registry = SchemaRegistry.withDefaultDialect(SpecificationVersion.DRAFT_2020_12);
        this.schemas = TOPICS.stream().collect(Collectors.toUnmodifiableMap(Function.identity(),
                topic -> registry.getSchema(load("/events/" + topic + ".schema.json"))));
    }

    /** @param value the record's value, never null (tombstones are skipped before decoding) */
    public Decoded decode(String topic, String key, String value) {
        Schema schema = schemas.get(topic);
        if (schema == null) {
            return invalid(Optional.empty(), "unknown topic " + topic);
        }
        JsonNode event;
        try {
            event = json.readTree(value);
        } catch (JsonProcessingException e) {
            return invalid(Optional.empty(), "not JSON: " + e.getOriginalMessage());
        }
        Optional<UUID> eventId = eventId(event);
        List<Error> errors = schema.validate(event);
        if (!errors.isEmpty()) {
            return invalid(eventId, "schema violation: " + errors.stream()
                    .map(e -> e.getInstanceLocation() + ": " + e.getMessage()).collect(Collectors.joining("; ")));
        }
        EventEnvelope envelope = envelope(event);
        String expectedKey = envelope.tenantId() + ":" + envelope.aggregateId();
        if (!expectedKey.equals(key)) {
            return invalid(eventId, "key " + key + " is not " + expectedKey);
        }
        try {
            return new Decoded.Valid(event(envelope, event.get("type").asText(), event.get("payload")));
        } catch (InvalidEvent e) {
            return invalid(eventId, e.getMessage());
        }
    }

    private static RosterEvent event(EventEnvelope envelope, String type, JsonNode payload) {
        return switch (type) {
            case "tenant.changed" -> tenant(envelope, payload);
            case "person.changed" -> new RosterEvent.PersonChanged(envelope, text(payload, "displayName"),
                    optionalText(payload, "subject"), roles(payload.get("roles")), payload.get("active").asBoolean());
            case "player.changed" -> new RosterEvent.PlayerChanged(envelope, uuid(payload, "personId"),
                    text(payload, "displayName"), text(payload, "status"),
                    optionalText(payload, "birthDate").map(LocalDate::parse), optionalText(payload, "gender"));
            case "team.changed" -> new RosterEvent.TeamChanged(envelope, SeasonId.of(uuid(payload, "seasonId")),
                    LocalDate.parse(text(payload, "seasonEndDate")), text(payload, "name"));
            case "team-player.changed" -> new RosterEvent.TeamPlayerChanged(envelope, TeamId.of(uuid(payload, "teamId")),
                    PlayerId.of(uuid(payload, "playerId")), optionalText(payload, "jerseyNumber"),
                    LocalDate.parse(text(payload, "joinedOn")), optionalText(payload, "leftOn").map(LocalDate::parse),
                    optionalText(payload, "invalidReason"));
            case "team-staff.changed" -> new RosterEvent.TeamStaffChanged(envelope, TeamId.of(uuid(payload, "teamId")),
                    uuid(payload, "personId"), text(payload, "role"));
            case "team-staff.removed" -> new RosterEvent.TeamStaffRemoved(envelope, TeamId.of(uuid(payload, "teamId")),
                    uuid(payload, "personId"));
            case "guardian-link.changed" -> new RosterEvent.GuardianLinkChanged(envelope,
                    uuid(payload, "guardianPersonId"), PlayerId.of(uuid(payload, "playerId")));
            case "guardian-link.removed" -> new RosterEvent.GuardianLinkRemoved(envelope,
                    uuid(payload, "guardianPersonId"), PlayerId.of(uuid(payload, "playerId")));
            default -> throw new InvalidEvent("unknown event type " + type);
        };
    }

    private static RosterEvent tenant(EventEnvelope envelope, JsonNode payload) {
        if (!envelope.aggregateId().equals(envelope.tenantId().value())) {
            throw new InvalidEvent("a tenant event must be about its own tenant, not " + envelope.aggregateId());
        }
        String zone = text(payload, "timezone");
        try {
            return new RosterEvent.TenantChanged(envelope, TenantStatus.valueOf(text(payload, "status")), ZoneId.of(zone));
        } catch (DateTimeException e) {
            throw new InvalidEvent("unknown time zone " + zone);
        }
    }

    private static EventEnvelope envelope(JsonNode event) {
        return new EventEnvelope(uuid(event, "eventId"), TenantId.parse(text(event, "tenantId")),
                uuid(event, "aggregateId"), Instant.parse(text(event, "occurredAt")));
    }

    private static Optional<UUID> eventId(JsonNode event) {
        try {
            return Optional.ofNullable(event.get("eventId")).filter(JsonNode::isTextual).map(JsonNode::asText)
                    .map(UUID::fromString);
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
    }

    private static Set<TenantRole> roles(JsonNode roles) {
        Set<TenantRole> result = EnumSet.noneOf(TenantRole.class);
        roles.forEach(role -> result.add(TenantRole.valueOf(role.asText())));
        return result;
    }

    private static String text(JsonNode node, String field) {
        return node.get(field).asText();
    }

    private static Optional<String> optionalText(JsonNode node, String field) {
        return Optional.ofNullable(node.get(field)).filter(value -> !value.isNull()).map(JsonNode::asText);
    }

    private static UUID uuid(JsonNode node, String field) {
        return UUID.fromString(text(node, field));
    }

    private static Decoded invalid(Optional<UUID> eventId, String reason) {
        return new Decoded.Invalid(eventId, reason.length() <= MAX_REASON_LENGTH ? reason
                : reason.substring(0, MAX_REASON_LENGTH));
    }

    private JsonNode load(String resource) {
        try (InputStream in = RosterEventDecoder.class.getResourceAsStream(resource)) {
            if (in == null) {
                throw new IllegalStateException(resource + " is missing from the contracts jar");
            }
            return json.readTree(in);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    /** A record that matches its schema but breaks a rule the schema cannot express. */
    private static final class InvalidEvent extends RuntimeException {
        InvalidEvent(String message) {
            super(message);
        }
    }
}
