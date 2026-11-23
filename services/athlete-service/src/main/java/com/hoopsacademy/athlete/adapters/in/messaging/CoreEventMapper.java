package com.hoopsacademy.athlete.adapters.in.messaging;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.athlete.application.replica.RosterChange;
import com.hoopsacademy.athlete.application.replica.RosterEvent;
import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.replica.EventEnvelope;
import com.hoopsacademy.common.replica.EventMapper;
import com.hoopsacademy.common.replica.RosterTopic;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.EnumSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * athlete's half of the roster event decoder (ADR-0037; the envelope half is common's {@code CoreEventDecoder}, WP130):
 * the payload of a valid {@code core.*} event as the {@link RosterChange} athlete's replica stores. A value the schema
 * allows but athlete cannot read (an unknown time zone) throws, and common parks the record.
 */
final class CoreEventMapper implements EventMapper<RosterEvent> {

    @Override
    public RosterEvent map(RosterTopic topic, EventEnvelope envelope, String type, JsonNode payload) {
        return new RosterEvent(envelope.eventId(), envelope.tenantId(), envelope.aggregateId(), envelope.occurredAt(),
                change(topic, type, payload));
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
        return Optional.ofNullable(payload.get(field)).filter(node -> !node.isNull()).map(JsonNode::asText);
    }
}
