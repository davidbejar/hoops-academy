package com.hoopsacademy.athlete.support;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hoopsacademy.common.tenancy.TenantId;
import com.networknt.schema.Schema;
import com.networknt.schema.SchemaRegistry;
import com.networknt.schema.SpecificationVersion;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Core's roster events as core's outbox publisher sends them (WP67 contracts, libs/contracts/events): envelope, key
 * {@code <tenant>:<aggregate>}, one topic per aggregate. A stand-in for core: the tests feed athlete's replica with these
 * records instead of running core. Every record is validated against its topic's schema when it is built, so a fixture
 * that drifts from the contract fails here and not in the code under test. A record's {@code occurredAt} is taken when
 * it is BUILT (a JVM-wide increasing clock), so build records in the order core would have written them.
 */
public final class CoreEvents {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final SchemaRegistry REGISTRY = SchemaRegistry.withDefaultDialect(SpecificationVersion.DRAFT_2020_12);
    private static final Map<String, Schema> SCHEMAS = new ConcurrentHashMap<>();
    /** Strictly increasing occurredAt across all fixtures of a JVM (core's clock_timestamp()). */
    private static final AtomicLong CLOCK = new AtomicLong(Instant.parse("2026-11-06T10:00:00Z").toEpochMilli() * 1000);

    /** One Kafka record: topic, key and the JSON value. */
    public record Record(String topic, String key, String value) {

        public UUID eventId() {
            return UUID.fromString(json().get("eventId").asText());
        }

        public Instant occurredAt() {
            return Instant.parse(json().get("occurredAt").asText());
        }

        public JsonNode json() {
            try {
                return JSON.readTree(value);
            } catch (IOException e) {
                throw new UncheckedIOException(e);
            }
        }

        /** The same aggregate's event with another id and an explicit time (to build out-of-order streams). */
        public Record at(Instant occurredAt) {
            ObjectNode copy = (ObjectNode) json();
            copy.put("eventId", UUID.randomUUID().toString());
            copy.put("occurredAt", occurredAt.toString());
            return new Record(topic, key, write(copy));
        }

        /** The same record with a value edited by hand (contract violations); not validated. */
        public Record withValue(String rawValue) {
            return new Record(topic, key, rawValue);
        }

        public Record withKey(String otherKey) {
            return new Record(topic, otherKey, value);
        }
    }

    private CoreEvents() {}

    public static Instant nextInstant() {
        return Instant.ofEpochSecond(0, CLOCK.addAndGet(1000) * 1000);
    }

    public static Record tenant(TenantId tenant, String status, String timezone) {
        ObjectNode payload = JSON.createObjectNode()
                .put("slug", "academy-" + tenant.toString().substring(0, 8))
                .put("name", "Academy " + tenant.toString().substring(0, 8))
                .put("status", status)
                .put("timezone", timezone)
                .put("defaultLocale", "es");
        return record("core.tenant", "tenant.changed", tenant, tenant.value(), payload);
    }

    public static Record person(TenantId tenant, UUID person, String displayName, String subject, List<String> roles,
            boolean active) {
        ObjectNode payload = JSON.createObjectNode().put("displayName", displayName);
        if (subject == null) {
            payload.putNull("subject");
        } else {
            payload.put("subject", subject);
        }
        ArrayNode sorted = payload.putArray("roles");
        roles.stream().sorted().forEach(sorted::add);
        payload.put("active", active);
        return record("core.person", "person.changed", tenant, person, payload);
    }

    public static Record player(TenantId tenant, UUID player, UUID person, String displayName, String status,
            LocalDate birthDate, String gender) {
        ObjectNode payload = JSON.createObjectNode()
                .put("personId", person.toString())
                .put("displayName", displayName)
                .put("status", status);
        nullable(payload, "birthDate", birthDate == null ? null : birthDate.toString());
        nullable(payload, "gender", gender);
        return record("core.player", "player.changed", tenant, player, payload);
    }

    public static Record team(TenantId tenant, UUID team, String name, LocalDate seasonEnd) {
        ObjectNode payload = JSON.createObjectNode()
                .put("seasonId", UUID.nameUUIDFromBytes(("season:" + seasonEnd).getBytes(StandardCharsets.UTF_8)).toString())
                .put("seasonStartDate", seasonEnd.minusMonths(10).toString())
                .put("seasonEndDate", seasonEnd.toString())
                .put("name", name)
                .putNull("alias")
                .put("ageCategoryId", UUID.randomUUID().toString())
                .put("genderPolicy", "MIXED");
        return record("core.team", "team.changed", tenant, team, payload);
    }

    public static Record teamPlayer(TenantId tenant, UUID assignment, UUID team, UUID player, String jersey,
            LocalDate joinedOn, LocalDate leftOn, String invalidReason) {
        ObjectNode payload = JSON.createObjectNode()
                .put("teamId", team.toString())
                .put("playerId", player.toString());
        nullable(payload, "jerseyNumber", jersey);
        payload.put("joinedOn", joinedOn.toString());
        nullable(payload, "leftOn", leftOn == null ? null : leftOn.toString());
        payload.put("playUpLevels", 0);
        nullable(payload, "invalidReason", invalidReason);
        return record("core.team-player", "team-player.changed", tenant, assignment, payload);
    }

    public static Record teamStaff(TenantId tenant, UUID team, UUID person, String role) {
        ObjectNode payload = JSON.createObjectNode()
                .put("teamId", team.toString())
                .put("personId", person.toString())
                .put("role", role)
                .put("since", "2026-09-01");
        return record("core.team-staff", "team-staff.changed", tenant, staffId(team, person), payload);
    }

    public static Record teamStaffRemoved(TenantId tenant, UUID team, UUID person) {
        ObjectNode payload = JSON.createObjectNode()
                .put("teamId", team.toString())
                .put("personId", person.toString());
        return record("core.team-staff", "team-staff.removed", tenant, staffId(team, person), payload);
    }

    public static Record guardianLink(TenantId tenant, UUID link, UUID guardian, UUID player) {
        return record("core.guardian-link", "guardian-link.changed", tenant, link, linkPayload(guardian, player));
    }

    public static Record guardianLinkRemoved(TenantId tenant, UUID link, UUID guardian, UUID player) {
        return record("core.guardian-link", "guardian-link.removed", tenant, link, linkPayload(guardian, player));
    }

    /**
     * The removal core publishes when it deletes a person, player, team, team assignment or tenant (WP81):
     * {@code <aggregate>.removed} with an empty payload ({@code aggregate} is {@code person}, {@code player}, {@code team},
     * {@code team-player} or {@code tenant}, whose id is the tenant's).
     */
    public static Record removed(TenantId tenant, String aggregate, UUID id) {
        return record("core." + aggregate, aggregate + ".removed", tenant, id, JSON.createObjectNode());
    }

    public static Record tenantRemoved(TenantId tenant) {
        return removed(tenant, "tenant", tenant.value());
    }

    /** Core's team-staff aggregate id: UUID v3 of {@code team-staff:<teamId>:<personId>}. */
    public static UUID staffId(UUID team, UUID person) {
        return UUID.nameUUIDFromBytes(("team-staff:" + team + ":" + person).getBytes(StandardCharsets.UTF_8));
    }

    private static ObjectNode linkPayload(UUID guardian, UUID player) {
        return JSON.createObjectNode().put("guardianPersonId", guardian.toString()).put("playerId", player.toString());
    }

    private static void nullable(ObjectNode node, String field, String value) {
        if (value == null) {
            node.putNull(field);
        } else {
            node.put(field, value);
        }
    }

    private static Record record(String topic, String type, TenantId tenant, UUID aggregate, ObjectNode payload) {
        ObjectNode envelope = JSON.createObjectNode()
                .put("eventId", UUID.randomUUID().toString())
                .put("type", type)
                .put("version", 1)
                .put("tenantId", tenant.toString())
                .put("aggregateId", aggregate.toString())
                .put("occurredAt", nextInstant().toString());
        envelope.set("payload", payload);
        assertThat(schema(topic).validate(envelope)).as("fixture %s must follow its contract", type).isEmpty();
        return new Record(topic, tenant + ":" + aggregate, write(envelope));
    }

    private static Schema schema(String topic) {
        return SCHEMAS.computeIfAbsent(topic, t -> {
            try (InputStream in = CoreEvents.class.getResourceAsStream("/events/" + t + ".schema.json")) {
                return REGISTRY.getSchema(JSON.readTree(in));
            } catch (IOException e) {
                throw new UncheckedIOException(e);
            }
        });
    }

    private static String write(JsonNode node) {
        try {
            return JSON.writeValueAsString(node);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
