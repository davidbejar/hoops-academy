package com.hoopsacademy.game.support;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hoopsacademy.game.adapters.json.MatchEventJson;
import com.hoopsacademy.game.domain.events.RecordedEvent;
import com.hoopsacademy.game.domain.events.Script;
import java.util.List;

/** Request bodies for {@code POST /events:batch} built from scripted domain events. */
public final class EventBatches {

    public static final ObjectMapper JSON = new ObjectMapper();

    private EventBatches() {}

    public static String batch(Script script) {
        return batch(script.events());
    }

    public static String batch(List<RecordedEvent> events) {
        ObjectNode body = JSON.createObjectNode();
        ArrayNode array = body.putArray("events");
        events.forEach(e -> array.add(MatchEventJson.encode(JSON, e.event())));
        return body.toString();
    }

    /** A batch with raw JSON events (e.g. invalid ones). */
    public static String raw(List<ObjectNode> events) {
        ObjectNode body = JSON.createObjectNode();
        body.putArray("events").addAll(events);
        return body.toString();
    }

    public static ObjectNode json(RecordedEvent event) {
        return MatchEventJson.encode(JSON, event.event());
    }
}
