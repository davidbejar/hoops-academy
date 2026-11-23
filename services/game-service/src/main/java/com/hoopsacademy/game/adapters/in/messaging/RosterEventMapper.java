package com.hoopsacademy.game.adapters.in.messaging;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import com.hoopsacademy.common.replica.EventEnvelope;
import com.hoopsacademy.common.replica.EventMapper;
import com.hoopsacademy.common.replica.RosterTopic;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.game.application.replica.RosterEvent;
import com.hoopsacademy.game.application.replica.RosterEvent.Aggregate;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.EnumSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * game's half of the roster event decoder (ADR-0037; the envelope half is common's {@code CoreEventDecoder}, WP130):
 * the payload of a valid {@code core.*} event as the {@link RosterEvent} the replica stores. A value the schema allows
 * but game cannot read (an unknown time zone) throws, and common parks the record.
 */
final class RosterEventMapper implements EventMapper<RosterEvent> {

    @Override
    public RosterEvent map(RosterTopic topic, EventEnvelope envelope, String type, JsonNode payload) {
        return switch (type) {
            case "tenant.changed" -> new RosterEvent.TenantChanged(envelope, TenantStatus.valueOf(text(payload, "status")),
                    ZoneId.of(text(payload, "timezone")), text(payload, "name"));
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
            case "person.removed" -> new RosterEvent.Removed(envelope, Aggregate.PERSON);
            case "player.removed" -> new RosterEvent.Removed(envelope, Aggregate.PLAYER);
            case "team.removed" -> new RosterEvent.Removed(envelope, Aggregate.TEAM);
            case "team-player.removed" -> new RosterEvent.Removed(envelope, Aggregate.TEAM_PLAYER);
            case "tenant.removed" -> new RosterEvent.Removed(envelope, Aggregate.TENANT);
            default -> throw new IllegalArgumentException("unknown event type");
        };
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
}
