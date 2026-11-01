package com.hoopsacademy.game.adapters.json;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.events.EventId;
import com.hoopsacademy.game.domain.events.EventMeta;
import com.hoopsacademy.game.domain.events.MatchEvent;
import com.hoopsacademy.game.domain.events.MatchEventType;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Maps the contract's MatchEvent JSON (events/match-event.schema.json) to the domain model and back. Decoding
 * expects JSON that already passed the schema; anything unexpected surfaces as a runtime exception.
 */
public final class MatchEventJson {

    private MatchEventJson() {}

    public static MatchEvent decode(JsonNode json) {
        EventMeta meta = new EventMeta(EventId.of(uuid(json, "id")), json.get("deviceId").asText(),
                json.get("clientSeq").asLong(), json.get("period").asInt(), json.get("clockSecondsRemaining").asInt(),
                OffsetDateTime.parse(json.get("recordedAtClient").asText()).toInstant());
        JsonNode payload = json.path("payload");
        return switch (MatchEventType.valueOf(json.get("type").asText())) {
            case PERIOD_START -> new MatchEvent.PeriodStart(meta);
            case PERIOD_END -> new MatchEvent.PeriodEnd(meta);
            case SUB_IN -> new MatchEvent.SubIn(meta, player(json));
            case SUB_OUT -> new MatchEvent.SubOut(meta, player(json));
            case SHOT -> new MatchEvent.Shot(meta, player(json), payload.get("points").asInt(), payload.get("made").asBoolean());
            case ASSIST -> new MatchEvent.Assist(meta, player(json));
            case REBOUND -> new MatchEvent.Rebound(meta, player(json), MatchEvent.ReboundKind.valueOf(payload.get("kind").asText()));
            case TURNOVER -> new MatchEvent.Turnover(meta, player(json));
            case STEAL -> new MatchEvent.Steal(meta, player(json));
            case BLOCK -> new MatchEvent.Block(meta, player(json));
            case FOUL -> new MatchEvent.Foul(meta, player(json), MatchEvent.FoulKind.valueOf(payload.get("kind").asText()));
            case OPPONENT_SCORE -> new MatchEvent.OpponentScore(meta, payload.get("points").asInt());
            case TIMEOUT -> new MatchEvent.Timeout(meta, MatchEvent.TimeoutSide.valueOf(payload.get("side").asText()));
            case VOID -> new MatchEvent.Void(meta, EventId.of(uuid(payload, "targetEventId")));
            case NOTE -> new MatchEvent.Note(meta, json.hasNonNull("playerId") ? player(json) : null,
                    payload.get("text").asText());
        };
    }

    public static ObjectNode encode(ObjectMapper mapper, MatchEvent event) {
        EventMeta meta = event.meta();
        ObjectNode json = mapper.createObjectNode()
                .put("id", meta.id().toString())
                .put("deviceId", meta.deviceId())
                .put("clientSeq", meta.clientSeq())
                .put("type", event.type().name())
                .put("period", meta.period())
                .put("clockSecondsRemaining", meta.clockSecondsRemaining())
                .put("recordedAtClient", meta.recordedAtClient().toString());
        event.playerId().ifPresent(p -> json.put("playerId", p.toString()));
        ObjectNode payload = payload(mapper, event);
        if (payload != null) {
            json.set("payload", payload);
        }
        return json;
    }

    /** The type-specific payload as stored in {@code match_event.payload}, or null when the type has none. */
    public static ObjectNode payload(ObjectMapper mapper, MatchEvent event) {
        ObjectNode payload = mapper.createObjectNode();
        return switch (event) {
            case MatchEvent.Shot s -> payload.put("points", s.points()).put("made", s.made());
            case MatchEvent.Rebound r -> payload.put("kind", r.kind().name());
            case MatchEvent.Foul f -> payload.put("kind", f.kind().name());
            case MatchEvent.OpponentScore o -> payload.put("points", o.points());
            case MatchEvent.Timeout t -> payload.put("side", t.side().name());
            case MatchEvent.Void v -> payload.put("targetEventId", v.target().toString());
            case MatchEvent.Note n -> payload.put("text", n.text());
            default -> null;
        };
    }

    private static PlayerId player(JsonNode json) {
        return PlayerId.of(uuid(json, "playerId"));
    }

    private static UUID uuid(JsonNode json, String field) {
        return UUID.fromString(json.get(field).asText());
    }
}
