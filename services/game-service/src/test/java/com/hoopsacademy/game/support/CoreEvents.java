package com.hoopsacademy.game.support;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.UUID;

/**
 * Stands in for core's outbox publisher in tests (ADR-0037): builds the records core publishes for one tenant, in the
 * WP67 contracts (libs/contracts/events: envelope, payload, key {@code <tenantId>:<aggregateId>}, tombstones), without
 * running core. Each event gets a new event id and an {@code occurredAt} one second after the previous one, unless
 * {@link #at(Instant)} sets the next one.
 */
public final class CoreEvents {

    /** One Kafka record; {@code value} null is a tombstone. */
    public record Record(String topic, String key, String value) {

        public String eventId() {
            return value == null ? null : value.replaceAll("(?s).*\"eventId\":\"([^\"]+)\".*", "$1");
        }
    }

    private static final ObjectMapper JSON = new ObjectMapper();

    private final TenantId tenant;
    private Instant next = Instant.parse("2026-11-06T10:00:00Z");

    private CoreEvents(TenantId tenant) {
        this.tenant = tenant;
    }

    public static CoreEvents of(TenantId tenant) {
        return new CoreEvents(tenant);
    }

    public TenantId tenant() {
        return tenant;
    }

    /** The next event occurs at {@code instant} (then one second later each). */
    public CoreEvents at(Instant instant) {
        next = instant;
        return this;
    }

    public Record tenant(String status, String timezone) {
        ObjectNode payload = JSON.createObjectNode().put("slug", "academy-" + tenant.toString().substring(0, 8))
                .put("name", "Academy").put("status", status).put("timezone", timezone).put("defaultLocale", "en");
        return record("core.tenant", "tenant.changed", tenant.value(), payload);
    }

    /** @param subject the login's sub, null for none */
    public Record person(UUID id, String displayName, String subject, boolean active, TenantRole... roles) {
        ArrayNode roleNames = JSON.createArrayNode();
        Arrays.stream(roles).map(Enum::name).sorted().forEach(roleNames::add);
        ObjectNode payload = JSON.createObjectNode().put("displayName", displayName).put("subject", subject);
        payload.set("roles", roleNames);
        payload.put("active", active);
        return record("core.person", "person.changed", id, payload);
    }

    /** @param birthDate null for none; @param gender MALE, FEMALE or null */
    public Record player(UUID id, UUID personId, String displayName, String status, LocalDate birthDate, String gender) {
        ObjectNode payload = JSON.createObjectNode().put("personId", personId.toString()).put("displayName", displayName)
                .put("status", status).put("birthDate", birthDate == null ? null : birthDate.toString())
                .put("gender", gender);
        return record("core.player", "player.changed", id, payload);
    }

    public Record team(UUID id, UUID seasonId, LocalDate seasonEndDate, String name) {
        ObjectNode payload = JSON.createObjectNode().put("seasonId", seasonId.toString())
                .put("seasonStartDate", seasonEndDate.minusMonths(10).toString())
                .put("seasonEndDate", seasonEndDate.toString()).put("name", name).putNull("alias")
                .put("ageCategoryId", UUID.nameUUIDFromBytes(seasonId.toString().getBytes(StandardCharsets.UTF_8)).toString())
                .put("genderPolicy", "MIXED");
        return record("core.team", "team.changed", id, payload);
    }

    /** @param jersey, leftOn, invalidReason null for none */
    public Record assignment(UUID id, UUID teamId, UUID playerId, String jersey, LocalDate joinedOn, LocalDate leftOn,
            String invalidReason) {
        ObjectNode payload = JSON.createObjectNode().put("teamId", teamId.toString()).put("playerId", playerId.toString())
                .put("jerseyNumber", jersey).put("joinedOn", joinedOn.toString())
                .put("leftOn", leftOn == null ? null : leftOn.toString()).put("playUpLevels", 0)
                .put("invalidReason", invalidReason);
        return record("core.team-player", "team-player.changed", id, payload);
    }

    public Record staff(UUID teamId, UUID personId, String role) {
        ObjectNode payload = JSON.createObjectNode().put("teamId", teamId.toString()).put("personId", personId.toString())
                .put("role", role).put("since", "2026-09-01");
        return record("core.team-staff", "team-staff.changed", staffId(teamId, personId), payload);
    }

    public Record staffRemoved(UUID teamId, UUID personId) {
        ObjectNode payload = JSON.createObjectNode().put("teamId", teamId.toString()).put("personId", personId.toString());
        return record("core.team-staff", "team-staff.removed", staffId(teamId, personId), payload);
    }

    public Record link(UUID id, UUID guardianPersonId, UUID playerId) {
        return record("core.guardian-link", "guardian-link.changed", id, linkPayload(guardianPersonId, playerId));
    }

    public Record linkRemoved(UUID id, UUID guardianPersonId, UUID playerId) {
        return record("core.guardian-link", "guardian-link.removed", id, linkPayload(guardianPersonId, playerId));
    }

    /**
     * The removal core publishes when an aggregate is deleted (WP81): {@code <aggregate>.removed} with an empty payload,
     * for {@code person}, {@code player}, {@code team}, {@code team-player} and {@code tenant} (whose id is the tenant's).
     */
    public Record removed(String aggregate, UUID id) {
        return record("core." + aggregate, aggregate + ".removed", id, JSON.createObjectNode());
    }

    /** The tenant's own removal (a failed onboarding, WP81). */
    public Record tenantRemoved() {
        return removed("tenant", tenant.value());
    }

    /** The tombstone core sends after a removal. */
    public static Record tombstone(Record removal) {
        return new Record(removal.topic(), removal.key(), null);
    }

    /** The contract's team-staff aggregate id: UUID v3 of {@code team-staff:<teamId>:<personId>}. */
    public static UUID staffId(UUID teamId, UUID personId) {
        return UUID.nameUUIDFromBytes(("team-staff:" + teamId + ":" + personId).getBytes(StandardCharsets.UTF_8));
    }

    private static ObjectNode linkPayload(UUID guardianPersonId, UUID playerId) {
        return JSON.createObjectNode().put("guardianPersonId", guardianPersonId.toString())
                .put("playerId", playerId.toString());
    }

    private Record record(String topic, String type, UUID aggregateId, ObjectNode payload) {
        Instant occurredAt = next;
        next = next.plus(Duration.ofSeconds(1));
        ObjectNode envelope = JSON.createObjectNode().put("eventId", UUID.randomUUID().toString()).put("type", type)
                .put("version", 1).put("tenantId", tenant.toString()).put("aggregateId", aggregateId.toString())
                .put("occurredAt", occurredAt.toString());
        envelope.set("payload", payload);
        return new Record(topic, tenant + ":" + aggregateId, envelope.toString());
    }
}
